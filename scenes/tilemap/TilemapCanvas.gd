extends Control
class_name TilemapCanvas

## Grid-based paint surface for the Tilemap Editor. Each "pixel" here is a whole tile
## cell. Left-click/drag stamps the selected tile (brush_size tiles wide, round or
## square footprint — same brush shapes as the pixel editor, just at tile scale).
## Right-click/drag erases. Whole strokes are undoable via UndoRedoManager (reused
## from the pixel editor — it just wraps Godot's generic UndoRedo).

var _is_drawing: bool = false
var _erasing: bool = false
var _stroke_before: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	TilemapState.map_dirty.connect(func(): _update_size(); queue_redraw())
	TilemapState.layers_updated.connect(func(): _update_size(); queue_redraw())
	TilemapState.tileset_changed.connect(func(): _update_size(); queue_redraw())
	_update_size()

func _update_size() -> void:
	var ts := TilemapState.tileset.tile_size * TilemapState.zoom
	custom_minimum_size = Vector2(TilemapState.map_width, TilemapState.map_height) * Vector2(ts)
	size = custom_minimum_size

func _cell_pixel_size() -> Vector2:
	return Vector2(TilemapState.tileset.tile_size) * TilemapState.zoom

func _screen_to_cell(local_pos: Vector2) -> Vector2i:
	var cs := _cell_pixel_size()
	return Vector2i(floori(local_pos.x / cs.x), floori(local_pos.y / cs.y))

func _draw() -> void:
	var cs := _cell_pixel_size()
	# base checker so empty cells are still visible
	for gy in TilemapState.map_height:
		for gx in TilemapState.map_width:
			var c := Color(0.85, 0.85, 0.87) if (gx + gy) % 2 == 0 else Color(0.76, 0.76, 0.79)
			draw_rect(Rect2(Vector2(gx, gy) * cs, cs), c, true)
	for layer in TilemapState.layers:
		if not layer.visible_flag or layer.opacity <= 0.0:
			continue
		for pos in layer.cells.keys():
			var idx: int = layer.cells[pos]
			var tex := TilemapState.tileset.get_texture(idx)
			if tex:
				draw_texture_rect(tex, Rect2(Vector2(pos) * cs, cs), false, Color(1, 1, 1, layer.opacity))
	# grid lines
	for gx in range(TilemapState.map_width + 1):
		draw_line(Vector2(gx * cs.x, 0), Vector2(gx * cs.x, TilemapState.map_height * cs.y), Color(0, 0, 0, 0.15))
	for gy in range(TilemapState.map_height + 1):
		draw_line(Vector2(0, gy * cs.y), Vector2(TilemapState.map_width * cs.x, gy * cs.y), Color(0, 0, 0, 0.15))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_stroke(mb.position, false)
			else:
				_end_stroke()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_start_stroke(mb.position, true)
			else:
				_end_stroke()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			TilemapState.zoom = clampf(TilemapState.zoom * 1.25, 0.5, 16.0)
			_update_size()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			TilemapState.zoom = clampf(TilemapState.zoom / 1.25, 0.5, 16.0)
			_update_size()
			queue_redraw()
	elif event is InputEventMouseMotion and _is_drawing:
		_paint_at((event as InputEventMouseMotion).position)

func _start_stroke(local_pos: Vector2, erase: bool) -> void:
	_is_drawing = true
	_erasing = erase
	_stroke_before = TilemapState.get_current_layer().cells.duplicate()
	_paint_at(local_pos)

func _paint_at(local_pos: Vector2) -> void:
	var center := _screen_to_cell(local_pos)
	var layer := TilemapState.get_current_layer()
	var tile_to_place := -1 if _erasing else TilemapState.selected_tile_index
	for off in PixelOps.brush_offsets(TilemapState.brush_size, TilemapState.brush_round):
		layer.set_cell(center + off, tile_to_place)
	TilemapState.mark_dirty()

func _end_stroke() -> void:
	if not _is_drawing:
		return
	_is_drawing = false
	var layer := TilemapState.get_current_layer()
	var after := layer.cells.duplicate()
	if after.hash() == _stroke_before.hash():
		return
	var before := _stroke_before
	UndoRedoManager.do_structural(
		"Paint Tiles",
		func():
			layer.cells = after.duplicate()
			TilemapState.mark_dirty(),
		func():
			layer.cells = before.duplicate()
			TilemapState.mark_dirty()
	)
