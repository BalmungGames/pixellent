extends Node

## Scans res://plugins/ (bundled with the app) and user://plugins/ (installed by
## the user, editable without rebuilding/exporting the project — genuine runtime
## plugin loading) for folders containing a plugin.gd script extending
## PixellentPlugin, loads + instantiates each one, and calls register(api) so it
## can add filters/tools/menu actions. See plugins/_template/ to write your own.

signal filter_registered(id: String, display_name: String)
signal tool_registered(id: String, display_name: String)
signal menu_action_registered(label: String, index: int)
signal plugin_load_error(message: String)

const BUNDLED_DIR := "res://plugins"
const USER_DIR := "user://plugins"

var api: PluginAPI
var _filters: Dictionary = {}    # id -> {name, fn}
var _tools: Dictionary = {}      # id -> {name, factory}
var _menu_actions: Array = []    # [{label, fn}]
var _plugin_instances: Array = []  # keeps loaded PixellentPlugin instances alive — a
                                    # Callable bound to a RefCounted method does NOT
                                    # by itself keep the object from being freed

func _ready() -> void:
	api = PluginAPI.new(self)
	DirAccess.make_dir_recursive_absolute(USER_DIR)
	_load_plugins_in(BUNDLED_DIR)
	_load_plugins_in(USER_DIR)

func _load_plugins_in(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var folder := dir.get_next()
	while folder != "":
		if dir.current_is_dir() and not folder.begins_with(".") and folder != "_template":
			_load_plugin_folder(root.path_join(folder))
		folder = dir.get_next()
	dir.list_dir_end()

func _load_plugin_folder(folder_path: String) -> void:
	var manifest_path := folder_path.path_join("plugin.json")
	if FileAccess.file_exists(manifest_path):
		var mf := FileAccess.open(manifest_path, FileAccess.READ)
		var parsed = JSON.parse_string(mf.get_as_text())
		mf.close()
		if parsed is Dictionary and parsed.get("enabled", true) == false:
			return  # disabled via manifest, skip without erroring

	var script_path := folder_path.path_join("plugin.gd")
	if not FileAccess.file_exists(script_path):
		return
	var script: GDScript = load(script_path)
	if script == null:
		plugin_load_error.emit("Failed to load script: %s" % script_path)
		return
	var instance = script.new()
	if not (instance is PixellentPlugin):
		plugin_load_error.emit("%s does not extend PixellentPlugin" % script_path)
		return
	instance.register(api)
	_plugin_instances.append(instance)

## ---- called by PluginAPI on behalf of plugins ----

func _register_filter(id: String, display_name: String, fn: Callable) -> void:
	_filters[id] = {"name": display_name, "fn": fn}
	filter_registered.emit(id, display_name)

func _register_tool(id: String, display_name: String, factory: Callable) -> void:
	_tools[id] = {"name": display_name, "factory": factory}
	tool_registered.emit(id, display_name)

func _register_menu_action(label: String, fn: Callable) -> void:
	_menu_actions.append({"label": label, "fn": fn})
	menu_action_registered.emit(label, _menu_actions.size() - 1)

## ---- called by the UI ----

func apply_filter_to_current_layer(fn: Callable) -> void:
	UndoRedoManager.begin_stroke()
	var layer := Global.get_current_layer()
	fn.call(layer.image)
	layer.update_texture()
	Global.canvas_dirty.emit()
	UndoRedoManager.commit_stroke("Filter")

func run_filter(id: String) -> void:
	if _filters.has(id):
		apply_filter_to_current_layer(_filters[id]["fn"])

func run_menu_action(index: int) -> void:
	if index >= 0 and index < _menu_actions.size():
		_menu_actions[index]["fn"].call()

func create_tool(id: String) -> Tool:
	if _tools.has(id):
		return _tools[id]["factory"].call()
	return null

func has_tool(id: String) -> bool:
	return _tools.has(id)

func get_filters() -> Dictionary:
	return _filters

func get_tools() -> Dictionary:
	return _tools

func get_menu_actions() -> Array:
	return _menu_actions
