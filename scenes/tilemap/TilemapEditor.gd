extends Control
class_name TilemapEditor

@onready var canvas: TilemapCanvas = %TilemapCanvas
@onready var brush_spin: SpinBox = %TileBrushSizeSpin
@onready var brush_round_check: CheckBox = %TileBrushRoundCheck
@onready var status_label: Label = %TilemapStatusLabel

@onready var new_dialog: ConfirmationDialog = %NewMapDialog
@onready var new_map_width: SpinBox = %NewMapWidth
@onready var new_map_height: SpinBox = %NewMapHeight

@onready var save_dialog: FileDialog = %TilemapSaveDialog
@onready var load_dialog: FileDialog = %TilemapLoadDialog
@onready var export_png_dialog: FileDialog = %TilemapExportPngDialog
@onready var export_tres_dialog: FileDialog = %TilemapExportTresDialog

func _ready() -> void:
	%BackBtn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	%NewMapBtn.pressed.connect(func(): new_dialog.popup_centered())
	%TilemapSaveBtn.pressed.connect(func(): save_dialog.popup_centered_ratio())
	%TilemapLoadBtn.pressed.connect(func(): load_dialog.popup_centered_ratio())
	%TilemapExportPngBtn.pressed.connect(func(): export_png_dialog.popup_centered_ratio())
	%TilemapExportTresBtn.pressed.connect(func(): export_tres_dialog.popup_centered_ratio())
	%TilemapUndoBtn.pressed.connect(func(): UndoRedoManager.undo())
	%TilemapRedoBtn.pressed.connect(func(): UndoRedoManager.redo())

	brush_spin.value_changed.connect(func(v): TilemapState.brush_size = int(v))
	brush_round_check.toggled.connect(func(v): TilemapState.brush_round = v)

	new_dialog.confirmed.connect(func():
		TilemapState.new_map(int(new_map_width.value), int(new_map_height.value))
		_set_status("New map: %dx%d tiles" % [int(new_map_width.value), int(new_map_height.value)])
	)
	save_dialog.file_selected.connect(func(p): ProjectFile.save_tilemap(p))
	load_dialog.file_selected.connect(func(p): ProjectFile.load_tilemap(p))
	export_png_dialog.file_selected.connect(func(p): ProjectFile.export_tilemap_png(p))
	export_tres_dialog.file_selected.connect(func(p): ProjectFile.export_tileset_godot(p))

	ProjectFile.saved.connect(func(p): _set_status("Saved: " + p))
	ProjectFile.loaded.connect(func(p): _set_status("Loaded: " + p))
	ProjectFile.exported.connect(func(p): _set_status("Exported: " + p))
	ProjectFile.error.connect(func(msg): _set_status("Error: " + msg))

	_set_status("Tilemap Editor ready. Import a tileset image, pick a tile, then paint.")

func _set_status(msg: String) -> void:
	status_label.text = msg
