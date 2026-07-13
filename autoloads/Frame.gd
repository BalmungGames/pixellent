extends Resource
class_name Frame

## One animation frame. Holds an ordered list of Layer (bottom -> top).

@export var duration: float = 1.0  # in "frame units" (multiplied by 1/FPS)
var layers: Array[Layer] = []

func _init(width: int = 64, height: int = 64) -> void:
	layers = [Layer.new(width, height, "Layer 1")]

func add_layer(width: int, height: int, at_index: int = -1) -> Layer:
	var l := Layer.new(width, height, "Layer %d" % (layers.size() + 1))
	if at_index < 0 or at_index >= layers.size():
		layers.append(l)
	else:
		layers.insert(at_index, l)
	return l

func remove_layer(index: int) -> void:
	if index >= 0 and index < layers.size() and layers.size() > 1:
		layers.remove_at(index)

func duplicate_frame() -> Frame:
	var f := Frame.new(1, 1)
	f.layers.clear()
	f.duration = duration
	for l in layers:
		f.layers.append(l.duplicate_layer())
	return f

## Composite all visible layers into one flattened Image using blend shaders' CPU
## equivalent (used for thumbnails / export; live canvas compositing is done on GPU).
func flatten() -> Image:
	if layers.is_empty():
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var w := layers[0].image.get_width()
	var h := layers[0].image.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for layer in layers:
		if not layer.visible_flag or layer.opacity <= 0.0:
			continue
		for y in h:
			for x in w:
				var src := layer.image.get_pixel(x, y)
				if src.a <= 0.0:
					continue
				src.a *= layer.opacity
				var dst := out.get_pixel(x, y)
				var out_a := src.a + dst.a * (1.0 - src.a)
				if out_a <= 0.0:
					continue
				var out_c := (src * src.a + dst * dst.a * (1.0 - src.a)) / out_a
				out_c.a = out_a
				out.set_pixel(x, y, out_c)
	return out

func to_dict() -> Dictionary:
	var layer_data := []
	for l in layers:
		layer_data.append(l.to_dict())
	return {"duration": duration, "layers": layer_data}

static func from_dict(d: Dictionary) -> Frame:
	var f := Frame.new(1, 1)
	f.layers.clear()
	f.duration = d.get("duration", 1.0)
	for ld in d.get("layers", []):
		f.layers.append(Layer.from_dict(ld))
	if f.layers.is_empty():
		f.layers.append(Layer.new(64, 64))
	return f
