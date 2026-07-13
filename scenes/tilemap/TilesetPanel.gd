extends VBoxContainer
class_name TilesetPanel

@onready var grid: GridContainer = $ScrollContainer/Grid
@onready var import_button: Button = $Toolbar/ImportButton
@onready var tile_size_spin: SpinBox = $Toolbar/TileSizeSpin
@onready var import_dialog: FileDialog = $ImportDialog

func _ready() -> void:
	import_button.pressed.connect(func(): import_dialog.popup_centered_ratio())
	import_dialog.file_selected.connect(_on_image_selected)
	TilemapState.tileset_changed.connect(_rebuild)
	TilemapState.selected_tile_changed.connect(func(_i): _rebuild())
	_rebuild()

func _on_image_selected(path: String) -> void:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		return
	img.convert(Image.FORMAT_RGBA8)
	var size := Vector2i(int(tile_size_spin.value), int(tile_size_spin.value))
	var ts := TileSetData.new()
	var added := ts.import_from_sheet(img, size)
	TilemapState.set_tileset(ts)
	if added > 0:
		TilemapState.set_selected_tile(0)

func _rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in TilemapState.tileset.tiles.size():
		var btn := TextureButton.new()
		btn.texture_normal = TilemapState.tileset.get_texture(i)
		btn.custom_minimum_size = Vector2(32, 32)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		btn.toggle_mode = true
		btn.button_pressed = (i == TilemapState.selected_tile_index)
		btn.pressed.connect(TilemapState.set_selected_tile.bind(i))
		grid.add_child(btn)
