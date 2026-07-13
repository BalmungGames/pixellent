extends Node

## Central project state. Everything else (Canvas, LayersPanel, Timeline, PalettePanel)
## reads/writes here and listens to the signals below.

signal tool_changed(tool_name: String)
signal color_changed(color: Color)
signal frame_changed(frame_index: int)
signal layer_changed(layer_index: int)
signal layers_updated
signal frames_updated
signal canvas_dirty  # emitted whenever pixel data changes -> canvas should redraw
signal zoom_changed(zoom: float)
signal project_loaded

const DEFAULT_WIDTH := 64
const DEFAULT_HEIGHT := 64

var canvas_width: int = DEFAULT_WIDTH
var canvas_height: int = DEFAULT_HEIGHT

var frames: Array[Frame] = []
var current_frame_index: int = 0
var current_layer_index: int = 0

var current_tool: String = "pencil"
var primary_color: Color = Color.BLACK
var secondary_color: Color = Color.WHITE
var brush_size: int = 1

var selection_rect: Rect2i = Rect2i()

var symmetry_x: bool = false  # mirror drawing left<->right
var symmetry_y: bool = false  # mirror drawing top<->bottom
var brush_round: bool = false  # false = square brush, true = round brush
var dither_intensity: float = 0.5

var zoom: float = 8.0
var project_path: String = ""
var fps: int = 6
var onion_skin_enabled: bool = false

func _ready() -> void:
	new_project(DEFAULT_WIDTH, DEFAULT_HEIGHT)

func new_project(width: int, height: int) -> void:
	canvas_width = width
	canvas_height = height
	frames = [Frame.new(width, height)]
	current_frame_index = 0
	current_layer_index = 0
	project_path = ""
	project_loaded.emit()
	frames_updated.emit()
	layers_updated.emit()
	canvas_dirty.emit()

func get_current_frame() -> Frame:
	if frames.is_empty():
		frames.append(Frame.new(canvas_width, canvas_height))
	current_frame_index = clampi(current_frame_index, 0, frames.size() - 1)
	return frames[current_frame_index]

func get_current_layer() -> Layer:
	var f := get_current_frame()
	if f.layers.is_empty():
		f.layers.append(Layer.new(canvas_width, canvas_height))
	current_layer_index = clampi(current_layer_index, 0, f.layers.size() - 1)
	return f.layers[current_layer_index]

func set_tool(tool_name: String) -> void:
	current_tool = tool_name
	tool_changed.emit(tool_name)

func set_primary_color(c: Color) -> void:
	primary_color = c
	color_changed.emit(c)

func set_current_frame(index: int) -> void:
	current_frame_index = clampi(index, 0, frames.size() - 1)
	current_layer_index = 0
	frame_changed.emit(current_frame_index)
	layers_updated.emit()
	canvas_dirty.emit()

func set_current_layer(index: int) -> void:
	current_layer_index = clampi(index, 0, get_current_frame().layers.size() - 1)
	layer_changed.emit(current_layer_index)

func mark_dirty() -> void:
	canvas_dirty.emit()

func set_zoom(z: float) -> void:
	zoom = clampf(z, 1.0, 64.0)
	zoom_changed.emit(zoom)
