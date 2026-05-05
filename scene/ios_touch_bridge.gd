extends Node
# iOS Touch Bridge — 绕过 Godot Emscripten 层，
# 通过 JavaScriptBridge 读取 HTML canvas 原始 touch 事件，
# 注入 InputEventScreenTouch / InputEventScreenDrag

const VIEWPORT_W = 720
const VIEWPORT_H = 1280

var active := false

func _ready():
	if OS.has_feature("web"):
		active = true
		print("[iOSTouchBridge] initialized")

func _process(_delta):
	if not active:
		return

	var json = JavaScriptBridge.eval("""
		(function() {
			var q = window.__godotTouchQueue;
			if (!q || q.length === 0) return 'null';
			var result = [];
			var sx = %d / window.innerWidth;
			var sy = %d / window.innerHeight;
			for (var i = 0; i < q.length; i++) {
				result.push({t: q[i].t, i: q[i].i, x: Math.round(q[i].x * sx), y: Math.round(q[i].y * sy)});
			}
			q.length = 0;
			return JSON.stringify(result);
		})()
	""" % [VIEWPORT_W, VIEWPORT_H])

	if json and json != "null":
		var events = JSON.parse_string(json)
		if events is Array:
			for entry in events:
				_dispatch(entry)

func _dispatch(e: Dictionary):
	match e.t:
		"touchstart":
			var ev = InputEventScreenTouch.new()
			ev.position = Vector2(e.x, e.y)
			ev.index = e.i
			ev.pressed = true
			Input.parse_input_event(ev)

		"touchmove":
			var ev = InputEventScreenDrag.new()
			ev.position = Vector2(e.x, e.y)
			ev.index = e.i
			Input.parse_input_event(ev)

		"touchend":
			var ev = InputEventScreenTouch.new()
			ev.position = Vector2(e.x, e.y)
			ev.index = e.i
			ev.pressed = false
			Input.parse_input_event(ev)
