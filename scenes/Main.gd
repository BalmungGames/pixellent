extends Control
class_name Main

@onready var canvas: Canvas = %Canvas
@onready var brush_spin: SpinBox = %BrushSizeSpin
@onready var zoom_label: Label = %ZoomLabel
@onready var save_dialog: FileDialog = %SaveDialog
@onready var load_dialog: FileDialog = %LoadDialog
@onready var export_png_dialog: FileDialog = %ExportPngDialog
@onready var export_sheet_dialog: FileDialog = %ExportSheetDialog
@onready var export_gif_dialog: FileDialog = %ExportGifDialog
@onready var new_dialog: ConfirmationDialog = %NewProjectDialog
@onready var new_width: SpinBox = %NewWidth
@onready var new_height: SpinBox = %NewHeight
@onready var status_label: Label = %StatusLabel
@onready var filled_shape_check: CheckBox = %FilledShapeCheck
@onready var brush_round_check: CheckBox = %BrushRoundCheck
@onready var symmetry_x_check: CheckBox = %SymmetryXCheck
@onready var symmetry_y_check: CheckBox = %SymmetryYCheck
@onready var dither_slider: HSlider = %DitherSlider
@onready var import_photo_dialog: FileDialog = %ImportPhotoDialog
@onready var import_photo_settings: ConfirmationDialog = %ImportPhotoSettingsDialog
@onready var import_width: SpinBox = %ImportWidth
@onready var import_posterize: SpinBox = %ImportPosterize
@onready var import_match_palette: CheckBox = %ImportMatchPalette
@onready var palette_panel: PalettePanel = %PalettePanel
@onready var plugins_row: HBoxContainer = %PluginsRow

const TOOL_BUTTON_GROUP_NAMES := ["Pencil", "Eraser", "Bucket", "Line", "Rect", "Ellipse", "Picker", "Select", "Shade", "Dither"]
const TOOL_NAME_MAP := {
	"Pencil": "pencil", "Eraser": "eraser", "Bucket": "bucket", "Line": "line",
	"Rect": "rect", "Ellipse": "ellipse", "Picker": "picker", "Select": "select",
	"Shade": "shade", "Dither": "dither",
}

var _pending_photo_path: String = ""

func _ready() -> void:
	for tname in TOOL_BUTTON_GROUP_NAMES:
		var btn: Button = get_node("%%%s" % (tname + "Btn"))
		btn.pressed.connect(_on_tool_button.bind(TOOL_NAME_MAP[tname]))
	%UndoBtn.pressed.connect(func(): UndoRedoManager.undo())
	%RedoBtn.pressed.connect(func(): UndoRedoManager.redo())
	%NewBtn.pressed.connect(func(): new_dialog.popup_centered())
	%SaveBtn.pressed.connect(func(): save_dialog.popup_centered_ratio())
	%LoadBtn.pressed.connect(func(): load_dialog.popup_centered_ratio())
	%ExportPngBtn.pressed.connect(func(): export_png_dialog.popup_centered_ratio())
	%ExportSheetBtn.pressed.connect(func(): export_sheet_dialog.popup_centered_ratio())
	%ExportGifBtn.pressed.connect(func(): export_gif_dialog.popup_centered_ratio())
	%ImportPhotoBtn.pressed.connect(func(): import_photo_dialog.popup_centered_ratio())
	%TilemapEditorBtn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/tilemap/TilemapEditor.tscn"))

	brush_spin.value_changed.connect(func(v): Global.brush_size = int(v))
	filled_shape_check.toggled.connect(_on_filled_toggled)
	brush_round_check.toggled.connect(func(v): Global.brush_round = v)
	symmetry_x_check.toggled.connect(func(v): Global.symmetry_x = v; Global.mark_dirty())
	symmetry_y_check.toggled.connect(func(v): Global.symmetry_y = v; Global.mark_dirty())
	dither_slider.value_changed.connect(func(v): Global.dither_intensity = v / 100.0)

	new_dialog.confirmed.connect(_on_new_confirmed)
	save_dialog.file_selected.connect(func(p): ProjectFile.save_project(p))
	load_dialog.file_selected.connect(func(p): ProjectFile.load_project(p))
	export_png_dialog.file_selected.connect(func(p): ProjectFile.export_current_frame_png(p))
	export_sheet_dialog.file_selected.connect(func(p): ProjectFile.export_spritesheet(p))
	export_gif_dialog.file_selected.connect(func(p): ProjectFile.export_gif(p))
	import_photo_dialog.file_selected.connect(_on_photo_selected)
	import_photo_settings.confirmed.connect(_on_import_photo_confirmed)

	ProjectFile.saved.connect(func(p): _set_status("Saved: " + p))
	ProjectFile.loaded.connect(func(p): _set_status("Loaded: " + p))
	ProjectFile.exported.connect(func(p): _set_status("Exported: " + p))
	ProjectFile.photo_imported.connect(func(p): _set_status("Imported photo as new project: " + p))
	ProjectFile.error.connect(func(msg): _set_status("Error: " + msg))

	Global.zoom_changed.connect(func(z): zoom_label.text = "%d%%" % int(z / 8.0 * 100.0))
	Global.tool_changed.connect(_on_global_tool_changed)
	zoom_label.text = "100%"

	Global.set_tool("pencil")
	_build_plugin_ui()

func _build_plugin_ui() -> void:
	var group: ButtonGroup = %PencilBtn.button_group
	for id in PluginManager.get_tools().keys():
		var info: Dictionary = PluginManager.get_tools()[id]
		var btn := Button.new()
		btn.text = info["name"]
		btn.toggle_mode = true
		btn.button_group = group
		btn.tooltip_text = "Plugin tool"
		btn.pressed.connect(Global.set_tool.bind(id))
		plugins_row.add_child(btn)
	for id in PluginManager.get_filters().keys():
		var finfo: Dictionary = PluginManager.get_filters()[id]
		var btn := Button.new()
		btn.text = finfo["name"]
		btn.tooltip_text = "Plugin filter: applies to the current layer (undoable)"
		btn.pressed.connect(PluginManager.run_filter.bind(id))
		plugins_row.add_child(btn)
	var actions: Array = PluginManager.get_menu_actions()
	for i in actions.size():
		var btn := Button.new()
		btn.text = actions[i]["label"]
		btn.pressed.connect(PluginManager.run_menu_action.bind(i))
		plugins_row.add_child(btn)
	plugins_row.get_parent().visible = plugins_row.get_child_count() > 0

func _on_tool_button(tool_name: String) -> void:
	Global.set_tool(tool_name)

func _on_global_tool_changed(tool_name: String) -> void:
	filled_shape_check.visible = tool_name in ["rect", "ellipse"]
	dither_slider.get_parent().visible = tool_name == "dither"

func _on_filled_toggled(pressed: bool) -> void:
	# Applied lazily: Canvas creates a fresh Tool instance per stroke, so we stash
	# the preference on Global and RectTool/EllipseTool read it via ToolManager.
	Global.set_meta("shape_filled", pressed)

func _on_new_confirmed() -> void:
	Global.new_project(int(new_width.value), int(new_height.value))
	_set_status("New project: %dx%d" % [int(new_width.value), int(new_height.value)])

func _on_photo_selected(path: String) -> void:
	_pending_photo_path = path
	# default target width to the photo's own width, clamped to something sane for pixel art
	var probe := Image.new()
	if probe.load(path) == OK:
		import_width.value = clampi(probe.get_width(), 8, 256)
	import_photo_settings.popup_centered()

func _on_import_photo_confirmed() -> void:
	var palette_colors: Array = palette_panel.colors if import_match_palette.button_pressed else []
	ProjectFile.import_photo(
		_pending_photo_path,
		int(import_width.value),
		int(import_posterize.value),
		import_match_palette.button_pressed,
		palette_colors
	)

func _set_status(msg: String) -> void:
	status_label.text = msg

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	if k.ctrl_pressed and k.keycode == KEY_Z:
		UndoRedoManager.undo()
	elif k.ctrl_pressed and k.keycode == KEY_Y:
		UndoRedoManager.redo()
	elif k.ctrl_pressed and k.keycode == KEY_S:
		save_dialog.popup_centered_ratio()
	elif not k.ctrl_pressed:
		match k.keycode:
			KEY_B: Global.set_tool("pencil")
			KEY_E: Global.set_tool("eraser")
			KEY_G: Global.set_tool("bucket")
			KEY_L: Global.set_tool("line")
			KEY_R: Global.set_tool("rect")
			KEY_O: Global.set_tool("ellipse")
			KEY_I: Global.set_tool("picker")
			KEY_M: Global.set_tool("select")
			KEY_H: Global.set_tool("shade")
			KEY_D: Global.set_tool("dither")
