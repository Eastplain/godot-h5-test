extends Node
# iOS Touch Bridge — 读取 JS touch 队列，注入 Godot 输入系统
# 带可视化调试（屏幕左上角显示运行状态）

const VIEWPORT_W = 720
const VIEWPORT_H = 1280

var active := false
var frame_count := 0
var dbg: Label = null
var total_events := 0

func _ready():
	if OS.has_feature("web"):
		active = true
		print("[iOSTouchBridge] initialized")
	
	# 延时创建调试标签（等场景树就绪）
	_ensure_debug.call_deferred()

func _ensure_debug():
	if dbg and is_instance_valid(dbg):
		return
	if not get_tree() or not get_tree().root:
		_ensure_debug.call_deferred()
		return
	
	var root = get_tree().root
	dbg = Label.new()
	dbg.name = "_BridgeDebug"
	dbg.position = Vector2(10, 120)
	dbg.size = Vector2(700, 50)
	dbg.add_theme_font_size_override("font_size", 11)
	dbg.add_theme_color_override("font_color", Color(0, 1, 0))
	dbg.text = "[Bridge] waiting..."
	
	var layer = CanvasLayer.new()
	layer.name = "_BridgeLayer"
	layer.add_child(dbg)
	root.add_child(layer)

func _process(_delta):
	frame_count += 1
	if not active:
		if dbg: dbg.text = "[Bridge] inactive (non-web)"
		return
	
	if frame_count % 10 != 1:
		return  # 每10帧查一次，节省开销
	
	# 测试 JavaScriptBridge 是否可用
	var bridge_ok = JavaScriptBridge != null
	var has_eval = JavaScriptBridge.has_method("eval")
	var has_get = JavaScriptBridge.has_method("get_interface")
	
	# 测试 eval 基本功能
	var test_num = JavaScriptBridge.eval("42")
	var test_str = JavaScriptBridge.eval("'hello'")
	var test_bool = JavaScriptBridge.eval("true")
	var tn = typeof(test_num)
	var ts = typeof(test_str)
	var tb = typeof(test_bool)
	
	# 尝试 get_interface 方式直接读取队列
	var q_obj = JavaScriptBridge.get_interface("__godotTouchQueue")
	var q_len = -2
	var q_item0 = ""
	if q_obj != null:
		q_len = q_obj.get("length")
		if q_len > 0:
			var first = q_obj.call("shift")
			if first != null:
				q_item0 = str(first)
	
	if dbg and frame_count % 30 == 1:
		var drain_result = JavaScriptBridge.eval("window.__godotTouchDrain()")
		var dr_type = typeof(drain_result)
		var dr_str: String = drain_result if typeof(drain_result) == TYPE_STRING else ""
		dbg.text = "[Bridge] bridge=%s eval=%s get=%s n=%s/%s s=%s/%s b=%s/%s qobj=%s qlen=%s drain=%s/%s" % [
			str(bridge_ok), str(has_eval), str(has_get),
			str(test_num), str(tn),
			str(test_str), str(ts),
			str(test_bool), str(tb),
			str(q_obj != null), str(q_len),
			str(dr_type), dr_str.left(30)
		]
		
		# 如果有 drain 数据，处理
		if dr_type == TYPE_STRING and dr_str.length() > 0:
			var items = dr_str.split(";")
			for item in items:
				var parts = item.split("|")
				if parts.size() == 4:
					total_events += 1
					_dispatch(parts[0], int(parts[1]), float(parts[2]), float(parts[3]))
			dbg.text = "[Bridge] DISPATCHED! total=%d" % total_events

func _dispatch(type: String, idx: int, x: float, y: float):
	match type:
		"touchstart":
			var ev = InputEventScreenTouch.new()
			ev.position = Vector2(x, y)
			ev.index = idx
			ev.pressed = true
			Input.parse_input_event(ev)
			print("[Bridge] touchstart idx=%d (%.1f,%.1f)" % [idx, x, y])
			
			# 同时也送一个鼠标事件，确保 Button 能响应
			var me = InputEventMouseButton.new()
			me.position = Vector2(x, y)
			me.button_index = MOUSE_BUTTON_LEFT
			me.pressed = true
			Input.parse_input_event(me)

		"touchmove":
			var ev = InputEventScreenDrag.new()
			ev.position = Vector2(x, y)
			ev.index = idx
			Input.parse_input_event(ev)

		"touchend":
			var ev = InputEventScreenTouch.new()
			ev.position = Vector2(x, y)
			ev.index = idx
			ev.pressed = false
			Input.parse_input_event(ev)
			print("[Bridge] touchend idx=%d (%.1f,%.1f)" % [idx, x, y])
			
			# 对应的鼠标释放
			var me = InputEventMouseButton.new()
			me.position = Vector2(x, y)
			me.button_index = MOUSE_BUTTON_LEFT
			me.pressed = false
			Input.parse_input_event(me)
