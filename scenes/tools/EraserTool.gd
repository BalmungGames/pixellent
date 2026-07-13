extends "res://scenes/tools/Tool.gd"
class_name EraserTool

func _apply_point(from: Vector2i, to: Vector2i) -> void:
	var img := _current_image()
	PixelOps.draw_line(img, from.x, from.y, to.x, to.y, Color(0, 0, 0, 0), Global.brush_size, Global.brush_round)
	_refresh()

func get_action_name() -> String:
	return "Eraser"
