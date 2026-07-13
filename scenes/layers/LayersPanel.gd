extends VBoxContainer
class_name LayersPanel

@onready var list_container: VBoxContainer = $ScrollContainer/List
@onready var add_button: Button = $Toolbar/AddButton
@onready var remove_button: Button = $Toolbar/RemoveButton
@onready var up_button: Button = $Toolbar/UpButton
@onready var down_button: Button = $Toolbar/DownButton
@onready var dup_button: Button = $Toolbar/DupButton

const ROW_SCENE := preload("res://scenes/layers/LayerRow.tscn")

func _ready() -> void:
	add_button.pressed.connect(_on_add)
	remove_button.pressed.connect(_on_remove)
	up_button.pressed.connect(_on_move.bind(-1))
	down_button.pressed.connect(_on_move.bind(1))
	dup_button.pressed.connect(_on_duplicate)
	Global.layers_updated.connect(_rebuild)
	Global.layer_changed.connect(func(_i): _rebuild())
	Global.frame_changed.connect(_rebuild)
	Global.project_loaded.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in list_container.get_children():
		c.queue_free()
	var frame := Global.get_current_frame()
	# Show top layer first (index size-1) like most editors.
	for i in range(frame.layers.size() - 1, -1, -1):
		var row := ROW_SCENE.instantiate()
		list_container.add_child(row)
		row.setup(frame.layers[i], i, i == Global.current_layer_index)

func _on_add() -> void:
	var frame := Global.get_current_frame()
	var index := Global.current_layer_index + 1
	UndoRedoManager.do_structural(
		"Add Layer",
		func():
			frame.add_layer(Global.canvas_width, Global.canvas_height, index)
			Global.current_layer_index = index
			Global.layers_updated.emit()
			Global.canvas_dirty.emit(),
		func():
			frame.remove_layer(index)
			Global.current_layer_index = clampi(index - 1, 0, frame.layers.size() - 1)
			Global.layers_updated.emit()
			Global.canvas_dirty.emit()
	)

func _on_remove() -> void:
	var frame := Global.get_current_frame()
	if frame.layers.size() <= 1:
		return
	var index := Global.current_layer_index
	var removed := frame.layers[index]
	UndoRedoManager.do_structural(
		"Remove Layer",
		func():
			frame.layers.remove_at(index)
			Global.current_layer_index = clampi(index - 1, 0, frame.layers.size() - 1)
			Global.layers_updated.emit()
			Global.canvas_dirty.emit(),
		func():
			frame.layers.insert(index, removed)
			Global.current_layer_index = index
			Global.layers_updated.emit()
			Global.canvas_dirty.emit()
	)

func _on_duplicate() -> void:
	var frame := Global.get_current_frame()
	var index := Global.current_layer_index
	var copy := frame.layers[index].duplicate_layer()
	UndoRedoManager.do_structural(
		"Duplicate Layer",
		func():
			frame.layers.insert(index + 1, copy)
			Global.current_layer_index = index + 1
			Global.layers_updated.emit()
			Global.canvas_dirty.emit(),
		func():
			frame.layers.remove_at(index + 1)
			Global.current_layer_index = index
			Global.layers_updated.emit()
			Global.canvas_dirty.emit()
	)

func _on_move(direction: int) -> void:
	var frame := Global.get_current_frame()
	var index := Global.current_layer_index
	var target := index + direction
	if target < 0 or target >= frame.layers.size():
		return
	UndoRedoManager.do_structural(
		"Reorder Layer",
		func():
			var tmp := frame.layers[index]
			frame.layers[index] = frame.layers[target]
			frame.layers[target] = tmp
			Global.current_layer_index = target
			Global.layers_updated.emit()
			Global.canvas_dirty.emit(),
		func():
			var tmp := frame.layers[index]
			frame.layers[index] = frame.layers[target]
			frame.layers[target] = tmp
			Global.current_layer_index = index
			Global.layers_updated.emit()
			Global.canvas_dirty.emit()
	)
