extends Node2D
# H5 触控输入诊断 — 6 种不同机制的输入检测

@onready var font_status: Label = $UI/FontStatus
@onready var log_label: Label = $UI/LogLabel

# 六个测试区，每个用一种不同的输入捕获方式
var zones = {
	"btn":   {"label": "1 Button.pressed",  "x": 60,  "color": Color(1,0.3,0.3), "count": 0, "method": "button"},
	"gui":   {"label": "2 Control._gui_input", "x": 180, "color": Color(0.3,1,0.3), "count": 0, "method": "gui"},
	"mouse": {"label": "3 _input(MouseBtn)", "x": 300, "color": Color(0.3,0.3,1), "count": 0, "method": "input_mouse"},
	"touch": {"label": "4 _input(ScreenTouch)", "x": 420, "color": Color(1,1,0.3), "count": 0, "method": "input_touch"},
	"unhdl": {"label": "5 _unhandled_input",  "x": 540, "color": Color(1,0.3,1), "count": 0, "method": "unhandled"},
	"area":  {"label": "6 Area2D.input_event","x":660, "color": Color(0.3,1,1), "count": 0, "method": "area"},
}
var last_log = ""
var log_timer = 0.0

func _ready():
	var theme = get_tree().root.theme
	if theme and theme.default_font:
		font_status.text = "✓ 字体 OK"
	font_status.text += "  |  触屏测试"

	# 方式1: Button - 直接连 signal
	$UI/Btn1.pressed.connect(func():
		zones["btn"].count += 1
		_inc("btn")
	)

	# 方式6: Area2D - 物理碰撞检测
	for zid in ["area"]:
		var a = Area2D.new()
		a.name = "Area_" + zid
		a.position = Vector2(zones[zid].x, 540)
		a.collision_layer = 2
		a.collision_mask = 0
		var c = CollisionShape2D.new()
		c.shape = RectangleShape2D.new()
		c.shape.size = Vector2(100, 100)
		a.add_child(c)
		add_child(a)
		a.input_event.connect(_on_area_input.bind(zid))

	# 创建可视化测试区（用 ColorRect 作为触摸目标）
	var colors = [Color(0.8,0.2,0.2), Color(0.2,0.8,0.2), Color(0.2,0.2,0.8),
				  Color(0.8,0.8,0.2), Color(0.8,0.2,0.8), Color(0.2,0.8,0.8)]
	var i = 0
	for zid in zones:
		var z = zones[zid]
		var r = ColorRect.new()
		r.name = "Rect_" + zid
		r.size = Vector2(100, 100)
		r.position = Vector2(z.x - 50, 490)
		r.color = colors[i] * 0.6
		r.mouse_filter = Control.MOUSE_FILTER_STOP  # 接管鼠标事件
		if zid == "btn": continue  # Button 已有
		if zid == "gui":
			r.gui_input.connect(_on_gui_input.bind(zid))
		$UI.add_child(r)
		
		var l = Label.new()
		l.text = z.label + "\n0"
		l.position = Vector2(z.x - 50, 600)
		l.size = Vector2(100, 40)
		l.horizontal_alignment = 1
		l.add_theme_font_size_override("font_size", 14)
		$UI.add_child(l)
		z["label_node"] = l
		i += 1

	# 给 Button 也加一个计数 label
	var bl = Label.new()
	bl.text = "1 Button\n0"
	bl.position = Vector2(10, 600)
	bl.size = Vector2(100, 40)
	bl.add_theme_font_size_override("font_size", 14)
	$UI.add_child(bl)
	zones["btn"]["label_node"] = bl

	log_label.text = "等待触控..."

# 方式2: _gui_input — 由 ColorRect 直接捕获
func _on_gui_input(event: InputEvent, zid: String):
	if event is InputEventMouseButton and event.pressed:
		_inc(zid)
		log_msg("[GUI] %s button=%d pos=%s" % [zid, event.button_index, event.position])
	elif event is InputEventScreenTouch and event.pressed:
		_inc(zid)
		log_msg("[GUI] %s touch pos=%s" % [zid, event.position])

# 方式3: _input — 接收鼠标事件
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		for zid in ["mouse"]:
			var z = zones[zid]
			if abs(event.position.x - z.x) < 50 and abs(event.position.y - 540) < 50:
				_inc(zid)
				log_msg("[_input] MouseBtn button=%d pos=%s" % [event.button_index, event.position])
	if event is InputEventScreenTouch and event.pressed:
		for zid in ["touch"]:
			var z = zones[zid]
			if abs(event.position.x - z.x) < 50 and abs(event.position.y - 540) < 50:
				_inc(zid)
				log_msg("[_input] ScreenTouch idx=%d pos=%s" % [event.index, event.position])

# 方式4: _unhandled_input — 前面没人吃的事件
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		for zid in ["unhdl"]:
			var z = zones[zid]
			if abs(event.position.x - z.x) < 50 and abs(event.position.y - 540) < 50:
				_inc(zid)
				log_msg("[_unhandled] MouseBtn pos=%s" % event.position)
	if event is InputEventScreenTouch and event.pressed:
		for zid in ["unhdl"]:
			var z = zones[zid]
			if abs(event.position.x - z.x) < 50 and abs(event.position.y - 540) < 50:
				_inc(zid)
				log_msg("[_unhandled] ScreenTouch pos=%s" % event.position)

# 方式6: Area2D input_event
func _on_area_input(viewport: Node, event: InputEvent, shape_idx: int, zid: String):
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_inc(zid)
		log_msg("[Area2D] %s %s" % [zid, event])

func _inc(zid: String):
	var z = zones[zid]
	z.count += 1
	if z.has("label_node") and is_instance_valid(z["label_node"]):
		z["label_node"].text = z.label + "\n" + str(z.count)

func _process(delta):
	queue_redraw()  # 重绘背景网格
	if log_timer > 0:
		log_timer -= delta
		if log_timer <= 0:
			log_label.text = "等待触控..."

func log_msg(msg: String):
	last_log = msg
	log_label.text = msg
	log_timer = 3.0
	print(msg)

func _draw():
	# 绘制 6 个测试区背景
	var colors = [Color(0.8,0.2,0.2), Color(0.2,0.8,0.2), Color(0.2,0.2,0.8),
				  Color(0.8,0.8,0.2), Color(0.8,0.2,0.8), Color(0.2,0.8,0.8)]
	var i = 0
	for zid in zones:
		var z = zones[zid]
		var c = colors[i]
		if z.count > 0:
			c = Color.WHITE  # 被点过的变白
		draw_rect(Rect2(z.x - 50, 490, 100, 100), c, false, 3.0)
		draw_rect(Rect2(z.x - 50, 490, 100, 100), Color(c.r*0.3, c.g*0.3, c.b*0.3, 0.3), true)
		i += 1
