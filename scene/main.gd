extends Node2D
# H5 Test — 验证 HTML5 导出的每个关键点

@onready var font_status: Label = $UI/FontStatus

var touch_positions: Array = []   # 最近 20 个触屏位置

func _ready():
	print("[main] H5 Test started. Engine: ", Engine.get_version_info())
	# 验证字体是否已加载
	var theme = get_tree().root.theme
	if theme and theme.default_font:
		font_status.text = "✓ 字体已加载: h5font (21KB)"
		print("[main] Font loaded OK")
	else:
		font_status.text = "✗ 字体未加载！"
		printerr("[main] Font NOT loaded!")

func _process(_delta):
	queue_redraw()

func _draw():
	# 背景网格（验证渲染管线）
	var grid_size = 80
	var grid_color = Color(0.2, 0.2, 0.25, 0.3)
	for x in range(0, 720, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, 1280), grid_color, 1)
	for y in range(0, 1280, grid_size):
		draw_line(Vector2(0, y), Vector2(720, y), grid_color, 1)

	# 触屏轨迹点
	for tp in touch_positions:
		draw_circle(tp, 6, Color(0.3, 1.0, 0.5, 0.6))

	# WASD 移动的小方块
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0:
		var rect_pos = Vector2(360, 640) + input_dir * 200
		draw_rect(Rect2(rect_pos - Vector2(25, 25), Vector2(50, 50)), Color(1.0, 0.8, 0.2, 0.8))

	# 中心十字
	var cx = 360; var cy = 640
	draw_line(Vector2(cx - 30, cy), Vector2(cx + 30, cy), Color(1, 1, 1, 0.5), 2)
	draw_line(Vector2(cx, cy - 30), Vector2(cx, cy + 30), Color(1, 1, 1, 0.5), 2)

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if event is InputEventScreenTouch and event.pressed:
			touch_positions.append(event.position)
			if touch_positions.size() > 20:
				touch_positions.pop_front()
			queue_redraw()
		elif event is InputEventScreenDrag:
			touch_positions.append(event.position)
			if touch_positions.size() > 20:
				touch_positions.pop_front()
			queue_redraw()
