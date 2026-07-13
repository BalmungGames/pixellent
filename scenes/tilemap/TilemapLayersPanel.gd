extends VBoxContainer
class_name TilemapLayersPanel

@onready var list_container: VBoxContainer = $ScrollContainer/List
@onready var add_button: Button = $Toolbar/AddButton
@onready var remove_button: Button = $Toolbar/RemoveButton
@onready var up_button: Button = $Toolbar/UpButton
@onready var down_button: Button = $Toolbar/DownButton

func _ready() -> void:
	add_button.pressed.connect(_on_add)
	remove_button.pressed.connect(_on_remove)
	up_button.pressed.connect(_on_move.bind(-1))
	down_button.pressed.connect(_on_move.bind(1))
	TilemapState.layers_updated.connect(_rebuild)
	TilemapState.layer_changed.connect(func(_i): _rebuild())
	_rebuild()

func _rebuild() -> void:
	for c in list_container.get_children():
		c.queue_free()
	for i in range(TilemapState.layers.size() - 1, -1, -1):
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var vis := CheckBox.new()
		vis.button_pressed = TilemapState.layers[i].visible_flag
		vis.toggled.connect(_on_visible_toggled.bind(i))
		hbox.add_child(vis)

		var label := Label.new()
		label.text = TilemapState.layers[i].layer_name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		var select_btn := Button.new()
		select_btn.text = "•"
		select_btn.flat = true
		select_btn.pressed.connect(TilemapState.set_current_layer.bind(i))
		hbox.add_child(select_btn)

		row.self_modulate = Color(0.25, 0.35, 0.55) if i == TilemapState.current_layer_index else Color(1, 1, 1)
		list_container.add_child(row)

func _on_visible_toggled(pressed: bool, index: int) -> void:
	TilemapState.layers[index].visible_flag = pressed
	TilemapState.mark_dirty()

func _on_add() -> void:
	var index := TilemapState.current_layer_index + 1
	var new_layer := TileMapLayerData.new()
	new_layer.layer_name = "Layer %d" % (TilemapState.layers.size() + 1)
	UndoRedoManager.do_structural(
		"Add Tile Layer",
		func():
			TilemapState.layers.insert(index, new_layer)
			TilemapState.current_layer_index = index
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty(),
		func():
			TilemapState.layers.remove_at(index)
			TilemapState.current_layer_index = clampi(index - 1, 0, TilemapState.layers.size() - 1)
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty()
	)

func _on_remove() -> void:
	if TilemapState.layers.size() <= 1:
		return
	var index := TilemapState.current_layer_index
	var removed := TilemapState.layers[index]
	UndoRedoManager.do_structural(
		"Remove Tile Layer",
		func():
			TilemapState.layers.remove_at(index)
			TilemapState.current_layer_index = clampi(index - 1, 0, TilemapState.layers.size() - 1)
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty(),
		func():
			TilemapState.layers.insert(index, removed)
			TilemapState.current_layer_index = index
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty()
	)

func _on_move(direction: int) -> void:
	var index := TilemapState.current_layer_index
	var target := index + direction
	if target < 0 or target >= TilemapState.layers.size():
		return
	UndoRedoManager.do_structural(
		"Reorder Tile Layer",
		func():
			var tmp := TilemapState.layers[index]
			TilemapState.layers[index] = TilemapState.layers[target]
			TilemapState.layers[target] = tmp
			TilemapState.current_layer_index = target
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty(),
		func():
			var tmp := TilemapState.layers[index]
			TilemapState.layers[index] = TilemapState.layers[target]
			TilemapState.layers[target] = tmp
			TilemapState.current_layer_index = index
			TilemapState.layers_updated.emit()
			TilemapState.mark_dirty()
	)
