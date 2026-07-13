extends "res://scenes/tools/Tool.gd"
class_name BucketTool

func start(pos: Vector2i) -> void:
	UndoRedoManager.begin_stroke()
	var img := _current_image()
	if PixelOps.in_bounds(img, pos.x, pos.y):
		PixelOps.flood_fill(img, pos.x, pos.y, Global.primary_color)
	_refresh()
	UndoRedoManager.commit_stroke(get_action_name())

func drag(_pos: Vector2i) -> void:
	pass  # bucket fills once on click, dragging does nothing

func end(_pos: Vector2i) -> void:
	pass

func get_action_name() -> String:
	return "Bucket Fill"
