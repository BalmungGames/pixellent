extends Node

## Wraps Godot's built-in UndoRedo. Pixel edits are undone/redone by swapping whole
## Image snapshots for the affected layer (simple, robust, fast enough for sprite-sized
## canvases). Structural edits (add/remove layer, add/remove frame) use do/undo callables.

var _undo_redo := UndoRedo.new()
var _pending_before: Image = null
var _pending_layer: Layer = null

func begin_stroke() -> void:
	## Call at the start of a drag/click draw action to snapshot the "before" state.
	var layer := Global.get_current_layer()
	_pending_layer = layer
	_pending_before = layer.image.duplicate()

func commit_stroke(action_name: String = "Draw") -> void:
	## Call when the draw action finishes (mouse released). No-ops if nothing changed.
	if _pending_layer == null or _pending_before == null:
		return
	var after := _pending_layer.image.duplicate()
	if after.get_data() == _pending_before.get_data():
		_pending_before = null
		_pending_layer = null
		return
	var layer := _pending_layer
	var before := _pending_before
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(func(): _apply_image(layer, after))
	_undo_redo.add_undo_method(func(): _apply_image(layer, before))
	_undo_redo.commit_action(false)  # false = don't re-run do (already applied live)
	_pending_before = null
	_pending_layer = null

func _apply_image(layer: Layer, img: Image) -> void:
	layer.image = img.duplicate()
	layer.update_texture()
	Global.layers_updated.emit()
	Global.canvas_dirty.emit()

func do_structural(action_name: String, do_cb: Callable, undo_cb: Callable) -> void:
	## For add/remove layer, add/remove frame, reorder, etc.
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(do_cb)
	_undo_redo.add_undo_method(undo_cb)
	_undo_redo.commit_action()

func undo() -> void:
	if _undo_redo.has_undo():
		_undo_redo.undo()

func redo() -> void:
	if _undo_redo.has_redo():
		_undo_redo.redo()
