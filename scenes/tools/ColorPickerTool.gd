extends "res://scenes/tools/Tool.gd"
class_name ColorPickerTool

func start(pos: Vector2i) -> void:
	_pick(pos)

func drag(pos: Vector2i) -> void:
	_pick(pos)

func end(pos: Vector2i) -> void:
	_pick(pos)

func _pick(pos: Vector2i) -> void:
	var img := _current_image()
	if PixelOps.in_bounds(img, pos.x, pos.y):
		Global.set_primary_color(img.get_pixel(pos.x, pos.y))

func get_action_name() -> String:
	return "Pick Color"
