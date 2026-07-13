extends "res://scenes/tools/Tool.gd"
class_name DitherTool

## Paints an ordered (Bayer) dither pattern mixing Global.primary_color and
## Global.secondary_color — the classic way pixel artists fake extra shading steps
## with only a couple of palette colors. Global.dither_intensity (0..1) controls the
## ratio of primary vs secondary in the pattern; useful for gradients/shadows/texture
## without needing dozens of hand-picked ramp colors.

func _apply_point(from: Vector2i, to: Vector2i) -> void:
	var img := _current_image()
	for p in PixelOps.line_pixels(from.x, from.y, to.x, to.y, Global.brush_size, Global.brush_round):
		if not PixelOps.in_bounds(img, p.x, p.y):
			continue
		var threshold := PixelOps.bayer_threshold(p.x, p.y)
		var c := Global.primary_color if threshold < Global.dither_intensity else Global.secondary_color
		img.set_pixel(p.x, p.y, c)
	_refresh()

func get_action_name() -> String:
	return "Dither"
