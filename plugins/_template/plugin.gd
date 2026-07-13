extends PixellentPlugin

## COPY THIS FOLDER to make a new plugin:
##   1. Copy plugins/_template/ to a new folder, e.g. plugins/my_plugin/
##      (or straight into user://plugins/my_plugin/ to skip re-exporting the app —
##      find that folder via the OS file manager: it's wherever Redot puts user://
##      for this project, e.g. %APPDATA%/Godot/app_userdata/Pixellent/plugins/ on
##      Windows, ~/.local/share/godot/app_userdata/Pixellent/plugins/ on Linux)
##   2. Edit plugin.json: change "id" to something unique.
##   3. Edit this file (rename the class if you want, doesn't have to match filename).
##   4. Restart Pixellent — it's picked up automatically, no rebuild/export needed.
##
## Three things a plugin can register (use any combination):

func register(api: PluginAPI) -> void:
	# 1) FILTER — func(img: Image) -> void, mutates the current layer's image in
	#    place. Shows up as a button under "Plugins" in the toolbar.
	api.register_filter("template_sepia", "Sepia (Template Example)", _apply_sepia)

	# 2) TOOL — func() -> Tool, returns a fresh instance of a class extending
	#    "res://scenes/tools/Tool.gd". Shows up as a selectable tool button.
	# api.register_tool("my_tool", "My Tool", func(): return MyToolScript.new())

	# 3) MENU ACTION — func() -> void, for anything else (batch ops, exports, etc).
	#    Shows up as a button under "Plugins".
	# api.register_menu_action("Do Something", _on_do_something)

func _apply_sepia(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			img.set_pixel(x, y, Color(clampf(l * 1.35, 0, 1), clampf(l * 1.1, 0, 1), clampf(l * 0.75, 0, 1), c.a))

# func _on_do_something() -> void:
# 	print("Plugin menu action fired!")
