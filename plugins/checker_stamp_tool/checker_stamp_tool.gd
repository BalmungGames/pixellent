extends "res://scenes/tools/Tool.gd"

## Example TOOL plugin (not just a filter) — proves the plugin system can add a real
## new drawing tool, not only image filters. Stamps a hard 1px checkerboard pattern
## alternating Global.primary_color / Global.secondary_color, useful for quick
## textures/dividers. Registered as "checker_stamp" below.

func _apply_point(from: Vector2i, to: Vector2i) -> void:
	var img := _current_image()
	for p in PixelOps.line_pixels(from.x, from.y, to.x, to.y, Global.brush_size, Global.brush_round):
		if not PixelOps.in_bounds(img, p.x, p.y):
			continue
		var c := Global.primary_color if (p.x + p.y) % 2 == 0 else Global.secondary_color
		img.set_pixel(p.x, p.y, c)
	_refresh()

func get_action_name() -> String:
	return "Checker Stamp"
