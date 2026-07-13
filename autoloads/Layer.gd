extends Resource
class_name Layer

## One layer of pixel data for one frame. A sprite frame is a list of Layer.

enum BlendMode { NORMAL, MULTIPLY, SCREEN, OVERLAY, ADD }

@export var layer_name: String = "Layer"
@export var visible_flag: bool = true
@export var opacity: float = 1.0
@export var blend_mode: BlendMode = BlendMode.NORMAL
@export var locked: bool = false

var image: Image
var texture: ImageTexture

func _init(width: int = 64, height: int = 64, p_name: String = "Layer") -> void:
	layer_name = p_name
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)

func duplicate_layer() -> Layer:
	var l := Layer.new(image.get_width(), image.get_height(), layer_name + " copy")
	l.image = image.duplicate()
	l.opacity = opacity
	l.blend_mode = blend_mode
	l.visible_flag = visible_flag
	l.update_texture()
	return l

func update_texture() -> void:
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	else:
		texture.set_image(image)

func resize(width: int, height: int) -> void:
	image.crop(width, height)
	update_texture()

func to_dict() -> Dictionary:
	return {
		"name": layer_name,
		"visible": visible_flag,
		"opacity": opacity,
		"blend_mode": blend_mode,
		"locked": locked,
		"png_b64": Marshalls.raw_to_base64(image.save_png_to_buffer()),
	}

static func from_dict(d: Dictionary) -> Layer:
	var img := Image.new()
	img.load_png_from_buffer(Marshalls.base64_to_raw(d.get("png_b64", "")))
	var l := Layer.new(img.get_width(), img.get_height(), d.get("name", "Layer"))
	l.image = img
	l.visible_flag = d.get("visible", true)
	l.opacity = d.get("opacity", 1.0)
	l.blend_mode = d.get("blend_mode", BlendMode.NORMAL)
	l.locked = d.get("locked", false)
	l.update_texture()
	return l
