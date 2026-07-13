extends "res://scenes/tools/Tool.gd"
class_name ShadeTool

## Beginner-assist "auto shading" tool (same idea as Aseprite's Shade tool). It does
## NOT paint a fixed color — instead it shifts whatever color is already under the
## brush one step darker/lighter (with a slight hue shift), so shading a sprite is
## just "paint over the area you want shaded" instead of hand-picking exact shadow
## colors. Left-click darkens, right-click (alt_mode) lightens.

func _apply_point(from: Vector2i, to: Vector2i) -> void:
	var img := _current_image()
	var darken := not alt_mode
	for p in PixelOps.line_pixels(from.x, from.y, to.x, to.y, Global.brush_size, Global.brush_round):
		if not PixelOps.in_bounds(img, p.x, p.y):
			continue
		var c := img.get_pixel(p.x, p.y)
		if c.a <= 0.0:
			continue  # don't shade empty/transparent pixels
		img.set_pixel(p.x, p.y, PixelOps.shade_step(c, darken))
	_refresh()

func get_action_name() -> String:
	return "Shade"
