extends Node

## State for the Tilemap Editor screen (parallel to Global, which is the pixel-canvas
## editor's state). Kept separate because the two editors have very different data
## models (per-pixel Image vs sparse tile-index grid).

signal tileset_changed
signal layers_updated
signal layer_changed(index: int)
signal map_dirty
signal selected_tile_changed(index: int)

var tileset: TileSetData = TileSetData.new()
var layers: Array[TileMapLayerData] = []
var current_layer_index: int = 0

var map_width: int = 30   # in tiles
var map_height: int = 20  # in tiles
var zoom: float = 2.0     # extra scale multiplier on top of tile_size (tiles are often small, e.g. 16px)

var selected_tile_index: int = -1
var brush_size: int = 1   # in tiles
var brush_round: bool = false
var project_path: String = ""

func _ready() -> void:
	new_map(30, 20)

func new_map(width: int, height: int) -> void:
	map_width = width
	map_height = height
	layers = [TileMapLayerData.new()]
	layers[0].layer_name = "Ground"
	current_layer_index = 0
	project_path = ""
	layers_updated.emit()
	map_dirty.emit()

func get_current_layer() -> TileMapLayerData:
	if layers.is_empty():
		layers.append(TileMapLayerData.new())
	current_layer_index = clampi(current_layer_index, 0, layers.size() - 1)
	return layers[current_layer_index]

func set_current_layer(index: int) -> void:
	current_layer_index = clampi(index, 0, layers.size() - 1)
	layer_changed.emit(current_layer_index)

func set_selected_tile(index: int) -> void:
	selected_tile_index = index
	selected_tile_changed.emit(index)

func set_tileset(ts: TileSetData) -> void:
	tileset = ts
	tileset_changed.emit()

func mark_dirty() -> void:
	map_dirty.emit()
