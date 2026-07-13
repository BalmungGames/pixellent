extends Node

signal saved(path: String)
signal loaded(path: String)
signal exported(path: String)
signal photo_imported(path: String)
signal error(message: String)

const FORMAT_VERSION := 1

## ---- Project save/load (.pxel = JSON) ----

func save_project(path: String) -> bool:
	var data := {
		"format_version": FORMAT_VERSION,
		"width": Global.canvas_width,
		"height": Global.canvas_height,
		"fps": Global.fps,
		"current_frame": Global.current_frame_index,
		"frames": [],
	}
	for f in Global.frames:
		data["frames"].append(f.to_dict())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		error.emit("Cannot open file for writing: %s" % path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	Global.project_path = path
	saved.emit(path)
	return true

func load_project(path: String) -> bool:
	if not FileAccess.file_exists(path):
		error.emit("File not found: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		error.emit("Cannot open file: %s" % path)
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		error.emit("Invalid .pxel file: %s" % path)
		return false
	var data: Dictionary = parsed
	Global.canvas_width = data.get("width", Global.DEFAULT_WIDTH)
	Global.canvas_height = data.get("height", Global.DEFAULT_HEIGHT)
	Global.fps = data.get("fps", 6)
	Global.frames.clear()
	for fd in data.get("frames", []):
		Global.frames.append(Frame.from_dict(fd))
	if Global.frames.is_empty():
		Global.frames.append(Frame.new(Global.canvas_width, Global.canvas_height))
	Global.current_frame_index = clampi(data.get("current_frame", 0), 0, Global.frames.size() - 1)
	Global.current_layer_index = 0
	Global.project_path = path
	Global.project_loaded.emit()
	Global.frames_updated.emit()
	Global.layers_updated.emit()
	Global.canvas_dirty.emit()
	loaded.emit(path)
	return true

## ---- Tilemap Editor: save/load/export ----

func save_tilemap(path: String) -> bool:
	var layer_data := []
	for l in TilemapState.layers:
		layer_data.append(l.to_dict())
	var data := {
		"format_version": FORMAT_VERSION,
		"map_width": TilemapState.map_width,
		"map_height": TilemapState.map_height,
		"tileset": TilemapState.tileset.to_dict(),
		"layers": layer_data,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		error.emit("Cannot open file for writing: %s" % path)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	TilemapState.project_path = path
	saved.emit(path)
	return true

func load_tilemap(path: String) -> bool:
	if not FileAccess.file_exists(path):
		error.emit("File not found: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		error.emit("Invalid .pxtm file: %s" % path)
		return false
	var data: Dictionary = parsed
	TilemapState.map_width = data.get("map_width", 30)
	TilemapState.map_height = data.get("map_height", 20)
	TilemapState.tileset = TileSetData.from_dict(data.get("tileset", {}))
	TilemapState.layers.clear()
	for ld in data.get("layers", []):
		TilemapState.layers.append(TileMapLayerData.from_dict(ld))
	if TilemapState.layers.is_empty():
		TilemapState.layers.append(TileMapLayerData.new())
	TilemapState.current_layer_index = 0
	TilemapState.project_path = path
	TilemapState.tileset_changed.emit()
	TilemapState.layers_updated.emit()
	TilemapState.mark_dirty()
	loaded.emit(path)
	return true

## Flattens all visible tile layers (bottom -> top, alpha-composited) into one PNG —
## the fast path to a ready-to-use game background/level image.
func export_tilemap_png(path: String) -> bool:
	var ts := TilemapState.tileset
	var tw := ts.tile_size.x
	var th := ts.tile_size.y
	var out := Image.create(TilemapState.map_width * tw, TilemapState.map_height * th, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for layer in TilemapState.layers:
		if not layer.visible_flag or layer.opacity <= 0.0:
			continue
		for pos in layer.cells.keys():
			var idx: int = layer.cells[pos]
			if idx < 0 or idx >= ts.tiles.size():
				continue
			out.blend_rect(ts.tiles[idx], Rect2i(Vector2i.ZERO, ts.tile_size), Vector2i(pos.x * tw, pos.y * th))
	var err := out.save_png(path)
	if err != OK:
		error.emit("Tilemap PNG export failed (%d): %s" % [err, path])
		return false
	exported.emit(path)
	return true

## Exports the tileset as a real Godot/Redot `TileSet` resource (.tres) + its source
## PNG, so it can be dropped into a TileMapLayer node in any Redot project. Cell
## placement data isn't part of a TileSet resource in Godot 4 (that lives on the
## TileMapLayer node itself), so layer/cell data stays in the .pxtm project file —
## see README for the (optional) small import script to recreate cells from JSON.
func export_tileset_godot(tres_path: String) -> bool:
	var ts := TilemapState.tileset
	if ts.tiles.is_empty():
		error.emit("Tileset is empty — import a tileset image first.")
		return false
	var cols := ceili(sqrt(ts.tiles.size()))
	var rows := ceili(float(ts.tiles.size()) / cols)
	var sheet := Image.create(cols * ts.tile_size.x, rows * ts.tile_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in ts.tiles.size():
		var cx := (i % cols) * ts.tile_size.x
		var cy := (i / cols) * ts.tile_size.y
		sheet.blit_rect(ts.tiles[i], Rect2i(Vector2i.ZERO, ts.tile_size), Vector2i(cx, cy))
	var png_path := tres_path.get_basename() + "_source.png"
	if sheet.save_png(png_path) != OK:
		error.emit("Failed writing tileset source PNG: %s" % png_path)
		return false

	var atlas_lines := PackedStringArray()
	for i in ts.tiles.size():
		var cx := i % cols
		var cy := i / cols
		atlas_lines.append("%d:%d/0 = 0" % [cx, cy])

	var png_filename := png_path.get_file()
	var tres := "[gd_resource type=\"TileSet\" load_steps=2 format=3]\n\n"
	tres += "[ext_resource type=\"Texture2D\" path=\"res://%s\" id=\"1\"]\n\n" % png_filename
	tres += "[sub_resource type=\"TileSetAtlasSource\" id=\"1\"]\n"
	tres += "texture = ExtResource(\"1\")\n"
	tres += "texture_region_size = Vector2i(%d, %d)\n" % [ts.tile_size.x, ts.tile_size.y]
	tres += "\n".join(atlas_lines) + "\n\n"
	tres += "[resource]\n"
	tres += "tile_size = Vector2i(%d, %d)\n" % [ts.tile_size.x, ts.tile_size.y]
	tres += "sources/0 = SubResource(\"1\")\n"

	var f := FileAccess.open(tres_path, FileAccess.WRITE)
	if not f:
		error.emit("Cannot open file for writing: %s" % tres_path)
		return false
	f.store_string(tres)
	f.close()
	exported.emit(tres_path)
	return true

## ---- Photo-to-Pixel-Art import (beginner-assist) ----

## Loads a real photo/image, downsamples it to `target_width` pixels wide (height
## keeps the source aspect ratio), then reduces its color count either by snapping
## to the current Palette panel's colors (match_palette=true) or by posterizing
## each channel to `posterize_levels` steps. Replaces the current project with a
## new one sized to the result, ready to touch up by hand.
func import_photo(path: String, target_width: int, posterize_levels: int, match_palette: bool, palette_colors: Array) -> bool:
	var src := Image.new()
	var err := src.load(path)
	if err != OK:
		error.emit("Could not load image (%d): %s" % [err, path])
		return false
	src.convert(Image.FORMAT_RGBA8)
	if src.get_width() <= 0:
		error.emit("Image has zero width: %s" % path)
		return false
	var aspect := float(src.get_height()) / float(src.get_width())
	var target_width_clamped := clampi(target_width, 4, 1024)
	var target_height := maxi(1, roundi(target_width_clamped * aspect))
	# Bilinear downsample first (smooth, avoids moire) — the canvas's own
	# nearest-neighbor zoom is what gives the final image its "pixel art" blockiness.
	src.resize(target_width_clamped, target_height, Image.INTERPOLATE_BILINEAR)
	for y in target_height:
		for x in target_width_clamped:
			var c := src.get_pixel(x, y)
			if match_palette and not palette_colors.is_empty():
				c = PixelOps.nearest_color(c, palette_colors)
			else:
				c = PixelOps.posterize(c, maxi(2, posterize_levels))
			src.set_pixel(x, y, c)
	Global.new_project(target_width_clamped, target_height)
	var layer := Global.get_current_layer()
	layer.image = src
	layer.update_texture()
	Global.canvas_dirty.emit()
	photo_imported.emit(path)
	return true


## Export the currently active frame (flattened) as a single PNG. Also usable
## directly as a game sprite texture, or converted to .jpg by external tools.
func export_current_frame_png(path: String) -> bool:
	var img := Global.get_current_frame().flatten()
	var err := img.save_png(path)
	if err != OK:
		error.emit("PNG export failed (%d): %s" % [err, path])
		return false
	exported.emit(path)
	return true

## Export every frame as PNG files: <basename>_0001.png, _0002.png, ... — the
## standard input format for game engines' AnimatedSprite / sprite-sheet importers.
func export_frame_sequence(base_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := base_path.get_base_dir()
	var base := base_path.get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(dir)
	for i in Global.frames.size():
		var img := Global.frames[i].flatten()
		var p := "%s/%s_%04d.png" % [dir, base, i + 1]
		if img.save_png(p) == OK:
			out.append(p)
	exported.emit(base_path)
	return out

## Export all frames tiled into one spritesheet PNG (grid layout), the format
## used directly by game engines (Sprite2D/AnimatedTexture with hframes/vframes).
func export_spritesheet(path: String, columns: int = -1) -> bool:
	if Global.frames.is_empty():
		return false
	var fw := Global.canvas_width
	var fh := Global.canvas_height
	var n := Global.frames.size()
	var cols := columns if columns > 0 else ceili(sqrt(n))
	var rows := ceili(float(n) / cols)
	var sheet := Image.create(fw * cols, fh * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in n:
		var img := Global.frames[i].flatten()
		var cx := (i % cols) * fw
		var cy := (i / cols) * fh
		sheet.blit_rect(img, Rect2i(0, 0, fw, fh), Vector2i(cx, cy))
	var err := sheet.save_png(path)
	if err != OK:
		error.emit("Spritesheet export failed (%d): %s" % [err, path])
		return false
	exported.emit(path)
	return true

## Export as animated GIF by shelling out to the bundled Python script (uses
## Pillow). Requires `python3` + `pillow` available on PATH; if missing, falls
## back gracefully and reports the error rather than crashing.
func export_gif(path: String) -> bool:
	var tmp_dir := OS.get_user_data_dir() + "/tmp_gif_frames"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var frame_paths := export_frame_sequence(tmp_dir + "/frame")
	if frame_paths.is_empty():
		return false
	var script_path := ProjectSettings.globalize_path("res://scripts/tools/export_spritesheet.py")
	var args := PackedStringArray(["--mode", "gif", "--out", path, "--fps", str(Global.fps)])
	for p in frame_paths:
		args.append(p)
	var output := []
	var exit_code := OS.execute("python3", args, output, true)
	if exit_code != 0:
		error.emit("GIF export failed (python3 exit %d). Is Pillow installed? Output: %s" % [exit_code, str(output)])
		return false
	exported.emit(path)
	return true
