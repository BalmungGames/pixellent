extends VBoxContainer
class_name PalettePanel

@onready var grid: GridContainer = $ScrollContainer/Grid
@onready var add_button: Button = $Toolbar/AddButton
@onready var remove_button: Button = $Toolbar/RemoveButton
@onready var save_button: Button = $Toolbar/SaveButton
@onready var load_button: Button = $Toolbar/LoadButton
@onready var color_picker: ColorPickerButton = $ColorPickerButton

var colors: Array[Color] = [
	Color.BLACK, Color.WHITE, Color.RED, Color.GREEN, Color.BLUE,
	Color.YELLOW, Color.CYAN, Color.MAGENTA,
]
var _selected_swatch_index: int = -1

const DEFAULT_PALETTE_PATH := "user://palettes/default.json"

func _ready() -> void:
	add_button.pressed.connect(_on_add_current_color)
	remove_button.pressed.connect(_on_remove_selected)
	save_button.pressed.connect(_on_save_palette)
	load_button.pressed.connect(_on_load_palette)
	color_picker.color = Global.primary_color
	color_picker.color_changed.connect(func(c): Global.set_primary_color(c))
	Global.color_changed.connect(func(c): color_picker.color = c)
	_rebuild()

func _rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in colors.size():
		var btn := ColorRect.new()
		btn.color = colors[i]
		btn.custom_minimum_size = Vector2(20, 20)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.gui_input.connect(_on_swatch_input.bind(i))
		grid.add_child(btn)

func _on_swatch_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_swatch_index = index
		Global.set_primary_color(colors[index])

func _on_add_current_color() -> void:
	colors.append(Global.primary_color)
	_rebuild()

func _on_remove_selected() -> void:
	if _selected_swatch_index >= 0 and _selected_swatch_index < colors.size() and colors.size() > 1:
		colors.remove_at(_selected_swatch_index)
		_selected_swatch_index = -1
		_rebuild()

func _on_save_palette() -> void:
	_save_to(DEFAULT_PALETTE_PATH)

func _on_load_palette() -> void:
	_load_from(DEFAULT_PALETTE_PATH)

func _save_to(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var arr := []
	for c in colors:
		arr.append(c.to_html(true))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(arr))
		f.close()

func _load_from(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		colors.clear()
		for hex in parsed:
			colors.append(Color(hex))
		_rebuild()
