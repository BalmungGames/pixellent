extends Resource
class_name TileMapLayerData

## One layer of a tilemap: a sparse grid mapping cell coordinate -> tile index into
## the project's TileSetData. Missing keys / index -1 both mean "empty".

@export var layer_name: String = "Layer"
@export var visible_flag: bool = true
@export var opacity: float = 1.0

var cells: Dictionary = {}  # Vector2i -> int (tile index)

func get_cell(pos: Vector2i) -> int:
	return cells.get(pos, -1)

func set_cell(pos: Vector2i, tile_index: int) -> void:
	if tile_index < 0:
		cells.erase(pos)
	else:
		cells[pos] = tile_index

func duplicate_layer() -> TileMapLayerData:
	var l := TileMapLayerData.new()
	l.layer_name = layer_name + " copy"
	l.visible_flag = visible_flag
	l.opacity = opacity
	l.cells = cells.duplicate()
	return l

func to_dict() -> Dictionary:
	var cell_data := {}
	for pos in cells.keys():
		cell_data["%d,%d" % [pos.x, pos.y]] = cells[pos]
	return {
		"name": layer_name,
		"visible": visible_flag,
		"opacity": opacity,
		"cells": cell_data,
	}

static func from_dict(d: Dictionary) -> TileMapLayerData:
	var l := TileMapLayerData.new()
	l.layer_name = d.get("name", "Layer")
	l.visible_flag = d.get("visible", true)
	l.opacity = d.get("opacity", 1.0)
	for key in d.get("cells", {}).keys():
		var key_str: String = key
		var parts: PackedStringArray = key_str.split(",")
		if parts.size() == 2:
			l.cells[Vector2i(int(parts[0]), int(parts[1]))] = int(d["cells"][key_str])
	return l
