extends "res://scenes/tools/Tool.gd"
class_name EllipseTool

var filled: bool = false

func start(pos: Vector2i) -> void:
	start_pos = pos
	last_pos = pos
	UndoRedoManager.begin_stroke()
	_drag_snapshot = Global.get_current_layer().image.duplicate()
	_redraw_preview(pos)

func drag(pos: Vector2i) -> void:
	last_pos = pos
	_redraw_preview(pos)

func end(pos: Vector2i) -> void:
	last_pos = pos
	_redraw_preview(pos)
	UndoRedoManager.commit_stroke(get_action_name())
	_drag_snapshot = null

func _redraw_preview(pos: Vector2i) -> void:
	var layer := Global.get_current_layer()
	layer.image = _drag_snapshot.duplicate()
	_apply_symmetric(start_pos, pos, Callable(self, "_do_ellipse"))
	_refresh()

func _do_ellipse(p0: Vector2i, p1: Vector2i) -> void:
	var img := Global.get_current_layer().image
	PixelOps.draw_ellipse(img, p0.x, p0.y, p1.x, p1.y, Global.primary_color, filled)

func get_action_name() -> String:
	return "Ellipse"
