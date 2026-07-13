extends "res://scenes/tools/Tool.gd"
class_name SelectTool

## Rectangle select. Click+drag outside an existing selection defines a new one.
## Click+drag INSIDE an existing selection moves the pixels under it (cut & paste).

var _moving: bool = false
var _move_snapshot: Image = null
var _move_content: Image = null  # the cut-out pixels being dragged
var _move_origin: Vector2i

func start(pos: Vector2i) -> void:
	start_pos = pos
	last_pos = pos
	var sel: Rect2i = Global.selection_rect
	if sel.size.x > 0 and sel.size.y > 0 and sel.has_point(pos):
		_begin_move(sel)
	else:
		_moving = false
		Global.selection_rect = Rect2i(pos, Vector2i.ZERO)

func drag(pos: Vector2i) -> void:
	last_pos = pos
	if _moving:
		_update_move(pos)
	else:
		var r := Rect2i(start_pos, pos - start_pos).abs()
		Global.selection_rect = r
		Global.canvas_dirty.emit()

func end(pos: Vector2i) -> void:
	last_pos = pos
	if _moving:
		_update_move(pos)
		UndoRedoManager.commit_stroke("Move Selection")
		_moving = false
		_move_snapshot = null
		_move_content = null
	else:
		Global.selection_rect = Rect2i(start_pos, pos - start_pos).abs()
		Global.canvas_dirty.emit()

func _begin_move(sel: Rect2i) -> void:
	_moving = true
	_move_origin = sel.position
	UndoRedoManager.begin_stroke()
	var layer := Global.get_current_layer()
	_move_snapshot = layer.image.duplicate()
	_move_content = Image.create(sel.size.x, sel.size.y, false, Image.FORMAT_RGBA8)
	_move_content.blit_rect(layer.image, sel, Vector2i.ZERO)
	# clear original area
	for y in sel.size.y:
		for x in sel.size.x:
			layer.image.set_pixel(sel.position.x + x, sel.position.y + y, Color(0, 0, 0, 0))
	_refresh()

func _update_move(pos: Vector2i) -> void:
	var layer := Global.get_current_layer()
	layer.image = _move_snapshot.duplicate()
	var sel: Rect2i = Global.selection_rect
	for y in sel.size.y:
		for x in sel.size.x:
			layer.image.set_pixel(sel.position.x + x, sel.position.y + y, Color(0, 0, 0, 0))
	var delta := pos - start_pos
	var new_pos := _move_origin + delta
	var dest := Rect2i(new_pos, sel.size)
	layer.image.blit_rect(_move_content, Rect2i(Vector2i.ZERO, sel.size), new_pos)
	Global.selection_rect = dest
	_refresh()

func get_action_name() -> String:
	return "Select"
