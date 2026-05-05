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
		return  # 每10帧查一次
	
	# 用 get_interface 直接操作 DOM，完全绕过 eval
	var doc = JavaScriptBridge.get_interface("document")
	var raw = ""
	if doc != null:
		var dbg_el = doc.call("getElementById", "_gd_touch_dbg")
		if dbg_el != null:
			var q_attr = dbg_el.call("getAttribute", "data-queue")
			if q_attr != null and q_attr.length() > 0:
				raw = str(q_attr)
				dbg_el.call("removeAttribute", "data-queue")
	
	if raw.length() == 0:
		if dbg and frame_count % 120 == 1:
			var dom_text = ""
			if doc != null and dbg_el != null:
				dom_text = str(dbg_el.get("textContent"))
			dbg.text = "[Bridge] idle dom=%s doc=%s" % [dom_text.left(40), str(doc != null)]
		return
	
	var items = raw.split(";")
	for item in items:
		var parts = item.split("|")
		if parts.size() == 4:
			total_events += 1
			_dispatch(parts[0], int(parts[1]), float(parts[2]), float(parts[3]))
	
	if dbg:
		dbg.text = "[Bridge] DISPATCHED! total=%d batch=%d" % [total_events, items.size()]

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
