extends PixellentPlugin

## Example filter plugin. Inverts RGB of every opaque pixel in the current layer.

func register(api: PluginAPI) -> void:
	api.register_filter("invert", "Invert Colors", _apply_invert)

func _apply_invert(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			img.set_pixel(x, y, Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a))
