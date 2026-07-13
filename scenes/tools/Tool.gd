extends RefCounted
class_name Tool

## Base class for all drawing tools. A tool receives pixel-space integer coordinates.
## Shape tools (line/rect/ellipse) redraw from a snapshot each drag step so the
## preview doesn't smear; freehand tools (pencil/eraser) draw incrementally.
##
## Symmetry (Global.symmetry_x/y) is applied transparently: every call to _apply_point
## also fires for the mirrored coordinate(s) via _paint(). Subclasses should call
## _paint(from, to) instead of _apply_point(from, to) directly, or — for tools that
## draw whole shapes (Line/Rect/Ellipse) — use _apply_symmetric(from, to, callback).

var start_pos: Vector2i
var last_pos: Vector2i
var _drag_snapshot: Image = null
var alt_mode: bool = false  # true when triggered by right-click (e.g. Shade lighten)

func start(pos: Vector2i) -> void:
	start_pos = pos
	UndoRedoManager.begin_stroke()
	var layer := Global.get_current_layer()
	_drag_snapshot = layer.image.duplicate()
	_paint(pos, pos)
	last_pos = pos

func drag(pos: Vector2i) -> void:
	_paint(last_pos, pos)
	last_pos = pos

func end(pos: Vector2i) -> void:
	_paint(last_pos, pos)
	last_pos = pos
	UndoRedoManager.commit_stroke(get_action_name())
	_drag_snapshot = null

func _paint(from: Vector2i, to: Vector2i) -> void:
	_apply_symmetric(from, to, Callable(self, "_apply_point"))

## Calls cb(from, to) for the original coordinates, then again for whichever mirrored
## variants are enabled in Global.symmetry_x / Global.symmetry_y (and both combined).
func _apply_symmetric(from: Vector2i, to: Vector2i, cb: Callable) -> void:
	cb.call(from, to)
	var w := Global.canvas_width
	var h := Global.canvas_height
	if Global.symmetry_x:
		cb.call(PixelOps.mirror_x(from, w), PixelOps.mirror_x(to, w))
	if Global.symmetry_y:
		cb.call(PixelOps.mirror_y(from, h), PixelOps.mirror_y(to, h))
	if Global.symmetry_x and Global.symmetry_y:
		cb.call(PixelOps.mirror_y(PixelOps.mirror_x(from, w), h), PixelOps.mirror_y(PixelOps.mirror_x(to, w), h))

func _apply_point(_from: Vector2i, _to: Vector2i) -> void:
	pass  # overridden by subclasses; _from==_to on first call

func get_action_name() -> String:
	return "Draw"

func _current_image() -> Image:
	return Global.get_current_layer().image

func _refresh() -> void:
	Global.get_current_layer().update_texture()
	Global.mark_dirty()
