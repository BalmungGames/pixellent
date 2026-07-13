extends PixellentPlugin

## Example filter plugin. Converts the current layer to grayscale using the standard
## luminosity formula, preserving alpha. Shows the minimal shape of a filter plugin.

func register(api: PluginAPI) -> void:
	api.register_filter("grayscale", "Grayscale", _apply_grayscale)

func _apply_grayscale(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			img.set_pixel(x, y, Color(l, l, l, c.a))
