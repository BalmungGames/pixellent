extends Resource
class_name TileSetData

## A flat list of tile images (all the same size) sliced from a source spritesheet
## image, or built up manually. `tiles[i]` is the image for tile index i; index -1
## (used in TileMapLayerData.cells) means "empty cell".

@export var tile_size: Vector2i = Vector2i(16, 16)
var tiles: Array[Image] = []
var textures: Array[ImageTexture] = []

func clear() -> void:
	tiles.clear()
	textures.clear()

## Slices a source image into a grid of tile_size cells, left-to-right, top-to-bottom,
## and appends them to this tileset. Returns how many tiles were added.
func import_from_sheet(source: Image, size: Vector2i) -> int:
	tile_size = size
	var cols := source.get_width() / size.x
	var rows := source.get_height() / size.y
	var added := 0
	for ty in rows:
		for tx in cols:
			var tile_img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			tile_img.blit_rect(source, Rect2i(tx * size.x, ty * size.y, size.x, size.y), Vector2i.ZERO)
			tiles.append(tile_img)
			textures.append(ImageTexture.create_from_image(tile_img))
			added += 1
	return added

func add_tile(img: Image) -> int:
	tiles.append(img)
	textures.append(ImageTexture.create_from_image(img))
	return tiles.size() - 1

func get_texture(index: int) -> ImageTexture:
	if index < 0 or index >= textures.size():
		return null
	return textures[index]

func to_dict() -> Dictionary:
	var tile_data := []
	for t in tiles:
		tile_data.append(Marshalls.raw_to_base64(t.save_png_to_buffer()))
	return {
		"tile_width": tile_size.x,
		"tile_height": tile_size.y,
		"tiles": tile_data,
	}

static func from_dict(d: Dictionary) -> TileSetData:
	var ts := TileSetData.new()
	ts.tile_size = Vector2i(d.get("tile_width", 16), d.get("tile_height", 16))
	for b64 in d.get("tiles", []):
		var img := Image.new()
		img.load_png_from_buffer(Marshalls.base64_to_raw(b64))
		ts.tiles.append(img)
		ts.textures.append(ImageTexture.create_from_image(img))
	return ts
