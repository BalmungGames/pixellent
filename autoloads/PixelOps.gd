extends RefCounted
class_name PixelOps

## Static pixel-drawing algorithms shared by all tools. Operates directly on an
## Image (RGBA8). All coordinates are integer pixel coordinates in image space.

static func in_bounds(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()

## Coordinate offsets covered by a brush stamp centered on (0,0). "round" gives a
## circular brush (nicer for painting), false gives the classic square pixel brush
## (nicer for hard tile/pixel edges) — both are what RPG-Maker-style tile painting
## and most pixel editors offer as the two basic brush shapes.
static func brush_offsets(brush_size: int, round_shape: bool = false) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	var r := int(brush_size / 2)
	var radius := brush_size / 2.0
	for oy in range(-r, brush_size - r):
		for ox in range(-r, brush_size - r):
			if round_shape and brush_size > 2:
				# +0.5 offset centers the circle test on each pixel cell
				if Vector2(ox, oy).length() > radius - 0.5:
					continue
			offsets.append(Vector2i(ox, oy))
	return offsets

static func set_pixel_brush(img: Image, x: int, y: int, color: Color, brush_size: int, round_shape: bool = false) -> void:
	for off in brush_offsets(brush_size, round_shape):
		var px := x + off.x
		var py := y + off.y
		if in_bounds(img, px, py):
			img.set_pixel(px, py, color)

## Bresenham line, stamps a brush at every step so brush_size > 1 gives a thick line.
static func draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, brush_size: int = 1, round_shape: bool = false) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		set_pixel_brush(img, x, y, color, brush_size, round_shape)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

## Same traversal as draw_line but returns the covered pixel coordinates instead of
## setting a fixed color — used by tools that compute a per-pixel result (Shade tool
## darkens/lightens whatever color is already there, Dither tool alternates two colors).
static func line_pixels(x0: int, y0: int, x1: int, y1: int, brush_size: int = 1, round_shape: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen := {}
	var offsets := brush_offsets(brush_size, round_shape)
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		for off in offsets:
			var p := Vector2i(x + off.x, y + off.y)
			var key := p.y * 1000000 + p.x
			if not seen.has(key):
				seen[key] = true
				result.append(p)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return result

static func draw_rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, filled: bool) -> void:
	var min_x := mini(x0, x1)
	var max_x := maxi(x0, x1)
	var min_y := mini(y0, y1)
	var max_y := maxi(y0, y1)
	if filled:
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				if in_bounds(img, x, y):
					img.set_pixel(x, y, color)
	else:
		draw_line(img, min_x, min_y, max_x, min_y, color)
		draw_line(img, min_x, max_y, max_x, max_y, color)
		draw_line(img, min_x, min_y, min_x, max_y, color)
		draw_line(img, max_x, min_y, max_x, max_y, color)

## Midpoint ellipse algorithm, bounded by (x0,y0)-(x1,y1) rectangle.
static func draw_ellipse(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, filled: bool) -> void:
	var cx := (x0 + x1) / 2.0
	var cy := (y0 + y1) / 2.0
	var rx := absf(x1 - x0) / 2.0
	var ry := absf(y1 - y0) / 2.0
	if rx < 0.5 or ry < 0.5:
		if in_bounds(img, x0, y0):
			img.set_pixel(x0, y0, color)
		return
	var steps := int(max(rx, ry) * 4.0) + 8
	var prev_scan := {}
	for i in range(steps + 1):
		var t := (TAU * float(i)) / float(steps)
		var x := int(round(cx + rx * cos(t)))
		var y := int(round(cy + ry * sin(t)))
		if filled:
			# accumulate min/max x per scanline, fill afterwards
			if not prev_scan.has(y):
				prev_scan[y] = [x, x]
			else:
				prev_scan[y][0] = mini(prev_scan[y][0], x)
				prev_scan[y][1] = maxi(prev_scan[y][1], x)
		elif in_bounds(img, x, y):
			img.set_pixel(x, y, color)
	if filled:
		for y in prev_scan.keys():
			var span: Array = prev_scan[y]
			for x in range(span[0], span[1] + 1):
				if in_bounds(img, x, y):
					img.set_pixel(x, y, color)

## Flood fill (4-directional) starting at (x,y), matching contiguous same-color area.
static func flood_fill(img: Image, x: int, y: int, new_color: Color, tolerance: float = 0.02) -> void:
	if not in_bounds(img, x, y):
		return
	var target := img.get_pixel(x, y)
	if _color_close(target, new_color, tolerance):
		return
	var w := img.get_width()
	var h := img.get_height()
	var stack: Array = [Vector2i(x, y)]
	var visited := {}
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var key := p.y * w + p.x
		if visited.has(key):
			continue
		var c := img.get_pixel(p.x, p.y)
		if not _color_close(c, target, tolerance):
			continue
		visited[key] = true
		img.set_pixel(p.x, p.y, new_color)
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))

static func _color_close(a: Color, b: Color, tol: float) -> bool:
	return absf(a.r - b.r) <= tol and absf(a.g - b.g) <= tol \
		and absf(a.b - b.b) <= tol and absf(a.a - b.a) <= tol

## ---- Symmetry helpers ----

static func mirror_x(p: Vector2i, width: int) -> Vector2i:
	return Vector2i(width - 1 - p.x, p.y)

static func mirror_y(p: Vector2i, height: int) -> Vector2i:
	return Vector2i(p.x, height - 1 - p.y)

## ---- Color helpers (used by Photo-to-Pixel-Art and Color-ramp Shading) ----

## Reduces color depth per channel to `levels` steps — a cheap posterize that gives
## flat "limited palette" pixel-art blocks of color instead of smooth photo gradients.
static func posterize(c: Color, levels: int) -> Color:
	if levels <= 1:
		return c
	var step := 1.0 / float(levels - 1)
	return Color(
		roundi(c.r / step) * step,
		roundi(c.g / step) * step,
		roundi(c.b / step) * step,
		c.a
	)

static func nearest_color(c: Color, palette: Array) -> Color:
	if palette.is_empty():
		return c
	var best: Color = palette[0]
	var best_dist := INF
	for p in palette:
		var pc: Color = p
		var d := (c.r - pc.r) ** 2 + (c.g - pc.g) ** 2 + (c.b - pc.b) ** 2
		if d < best_dist:
			best_dist = d
			best = pc
	return Color(best.r, best.g, best.b, c.a)

## Shifts a color's HSV value (brightness) up/down a step, nudging hue slightly toward
## blue when darkening / yellow when lightening — the classic pixel-art hand-shading
## trick ("hue shifting") used by the Shade tool.
static func shade_step(c: Color, darken: bool, amount: float = 0.08) -> Color:
	var h := c.h
	var s := c.s
	var v := c.v
	if darken:
		v = clampf(v - amount, 0.0, 1.0)
		s = clampf(s + amount * 0.6, 0.0, 1.0)
		h = fposmod(h - 0.015, 1.0)
	else:
		v = clampf(v + amount, 0.0, 1.0)
		s = clampf(s - amount * 0.6, 0.0, 1.0)
		h = fposmod(h + 0.015, 1.0)
	return Color.from_hsv(h, s, v, c.a)

## 4x4 Bayer ordered-dither matrix (values 0..15). Used by the Dither tool to blend
## two colors in a classic pixel-art crosshatch pattern instead of a flat blend.
const BAYER_4X4 := [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5],
]

static func bayer_threshold(x: int, y: int) -> float:
	return float(BAYER_4X4[y % 4][x % 4]) / 16.0
