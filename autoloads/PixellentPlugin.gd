extends RefCounted
class_name PixellentPlugin

## Base class for all Pixellent plugins. A plugin is a single .gd file that extends
## this class and lives in its own folder under res://plugins/ (bundled) or
## user://plugins/ (user-installed — loaded from disk at runtime, no rebuild/export
## needed). PluginManager finds it via that folder's plugin.json manifest, loads the
## script with `load()`, instantiates it, and calls register(api) once at startup.
##
## See plugins/_template/ for a copy-paste starting point and README.md for details.

## Called once when the plugin is loaded. Use `api` to register filters/tools/menu
## actions — do NOT touch Global/TilemapState/UndoRedoManager directly from here;
## go through `api` so Pixellent can keep track of what plugins have registered.
func register(_api: PluginAPI) -> void:
	pass  # override in subclasses
