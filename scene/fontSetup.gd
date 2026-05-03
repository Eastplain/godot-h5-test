extends Node
# FontSetup — autoload that forces font on HTML5 export.
# project.godot's [gui] theme/custom_font is unreliable on HTML5;
# this runtime approach is the only stable method.

func _ready():
	var font = load("res://resource/font/simhei.ttf")
	if font:
		var theme = Theme.new()
		theme.default_font = font
		theme.default_font_size = 16
		get_tree().root.theme = theme
		print("[FontSetup] simhei.ttf loaded, theme applied")
	else:
		printerr("[FontSetup] FAILED to load simhei.ttf")
