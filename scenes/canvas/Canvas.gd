extends Control
class_name Canvas

## The drawing surface. Composites all visible layers of the current frame (bottom
## to top, respecting opacity) and renders them nearest-neighbor scaled by Global.zoom.
## Handles mouse input -> pixel coordinates -> active Tool.

## Panning is handled by wrapping this Control in a ScrollContainer (see Main.tscn);
## zoom changes custom_minimum_size so the scrollbars adjust automatically.

var _current_tool: Tool = null
var _is_drawing: bool = false
var _background: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = ColorRect.new()
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/checkerboard.gdshader")
	_background.material = mat
	add_child(_background)
	move_child(_background, 0)

	Global.canvas_dirty.connect(func(): queue_redraw())
	Global.layers_updated.connect(func(): queue_redraw())
	Global.frame_changed.connect(func(): queue_redraw())
	Global.zoom_changed.connect(func(_z): _update_size(); queue_redraw())
	Global.project_loaded.connect(func(): _update_size(); queue_redraw())
	Global.tool_changed.connect(func(_t): _current_tool = null)
	_update_size()

func _update_size() -> void:
	custom_minimum_size = Vector2(Global.canvas_width, Global.canvas_height) * Global.zoom
	size = custom_minimum_size
	if _background:
		_background.size = size
		_background.position = Vector2.ZERO

func _pixel_size() -> Vector2:
	return Vector2(Global.canvas_width, Global.canvas_height) * Global.zoom

func _screen_to_pixel(local_pos: Vector2) -> Vector2i:
	var p := local_pos / Global.zoom
	return Vector2i(floori(p.x), floori(p.y))

func _draw() -> void:
	var frame := Global.get_current_frame()
	var zoom := Global.zoom
	var rect_size := _pixel_size()
	# composite layers bottom -> top (checkerboard background is drawn by the
	# ColorRect + checkerboard.gdshader material created in _ready())
	for layer in frame.layers:
		if not layer.visible_flag or layer.opacity <= 0.0:
			continue
		layer.update_texture()
		draw_texture_rect(layer.texture, Rect2(Vector2.ZERO, rect_size), false, Color(1, 1, 1, layer.opacity))
	# onion skin: draw previous frame at low alpha
	if Global.onion_skin_enabled and Global.current_frame_index > 0:
		var prev := Global.frames[Global.current_frame_index - 1]
		var ghost := prev.flatten()
		var ghost_tex := ImageTexture.create_from_image(ghost)
		draw_texture_rect(ghost_tex, Rect2(Vector2.ZERO, rect_size), false, Color(1, 0.3, 0.3, 0.35))
	# selection overlay (marching-ants style: dark outline with light inner line)
	var sel := Global.selection_rect
	if sel.size.x > 0 and sel.size.y > 0:
		var r := Rect2(Vector2(sel.position) * zoom, Vector2(sel.size) * zoom)
		draw_rect(r.grow(1.0), Color(0, 0, 0, 0.9), false, 1.0)
		draw_rect(r, Color(1, 1, 1, 0.9), false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_draw(mb.position, false)
			else:
				_end_draw(mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_start_draw(mb.position, true)
			else:
				_end_draw(mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			Global.set_zoom(Global.zoom * 1.25)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			Global.set_zoom(Global.zoom / 1.25)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_drawing:
			_drag_draw(mm.position)

func _start_draw(local_pos: Vector2, alt: bool = false) -> void:
	if _current_tool == null:
		_current_tool = ToolManager.create(Global.current_tool)
	_current_tool.alt_mode = alt
	_is_drawing = true
	_current_tool.start(_screen_to_pixel(local_pos))

func _drag_draw(local_pos: Vector2) -> void:
	if _current_tool:
		_current_tool.drag(_screen_to_pixel(local_pos))

func _end_draw(local_pos: Vector2) -> void:
	if _current_tool:
		_current_tool.end(_screen_to_pixel(local_pos))
	_is_drawing = false
