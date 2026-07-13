extends RefCounted
class_name PluginAPI

## Passed to every plugin's register(api) call. Plugins should only ever touch
## Pixellent through this object — it forwards into PluginManager, which is what
## actually stores/exposes what got registered to the rest of the app (menus, tool
## list, etc). Keeping this indirection means a plugin can't accidentally corrupt
## PluginManager's internal bookkeeping.

var _manager: Node

func _init(manager: Node) -> void:
	_manager = manager

## A filter is `func(img: Image) -> void` that mutates the image in place (e.g.
## grayscale, invert, blur). Appears as a button under "Plugins" that applies it to
## the current layer with a proper undo step already wired up.
func register_filter(id: String, display_name: String, apply_fn: Callable) -> void:
	_manager._register_filter(id, display_name, apply_fn)

## A tool factory is `func() -> Tool` returning a fresh instance of a class that
## extends "res://scenes/tools/Tool.gd" (override _apply_point at minimum). Appears
## as a selectable tool button alongside the built-in ones.
func register_tool(id: String, display_name: String, tool_factory: Callable) -> void:
	_manager._register_tool(id, display_name, tool_factory)

## A menu action is `func() -> void` for anything that doesn't fit the filter/tool
## shape (e.g. "Export all frames as a game-ready .tres", batch operations, etc).
func register_menu_action(label: String, action_fn: Callable) -> void:
	_manager._register_menu_action(label, action_fn)

## Convenience read accessor. Plugins should treat the returned Image as read-only
## unless they're inside a filter's apply_fn (which is allowed to mutate it).
func get_current_layer_image() -> Image:
	return Global.get_current_layer().image

func get_canvas_size() -> Vector2i:
	return Vector2i(Global.canvas_width, Global.canvas_height)
