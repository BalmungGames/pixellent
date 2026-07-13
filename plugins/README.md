# Pixellent Plugins

Pixellent loads plugins from two places at startup:

- `res://plugins/` — bundled with the app (ships in the export)
- `user://plugins/` — installed by the user, **loaded straight from disk at
  runtime**. No rebuild or re-export needed — drop a folder in, restart Pixellent.
  On desktop this is typically:
  - Windows: `%APPDATA%\Godot\app_userdata\Pixellent\plugins\`
  - Linux: `~/.local/share/godot/app_userdata/Pixellent/plugins/`
  - macOS: `~/Library/Application Support/Godot/app_userdata/Pixellent/plugins/`

  (Exact path depends on your Redot/Aegis build's data-dir settings — Pixellent
  also creates this folder automatically on first run if it doesn't exist yet.)

## Folder layout

Each plugin is a folder containing:

```
plugins/my_plugin/
  plugin.json   # metadata (id, name, version, enabled true/false)
  plugin.gd     # entry point — must `extends PixellentPlugin`
```

`plugin.json`'s `"enabled": false` disables a plugin without deleting it.

## Writing a plugin

1. Copy `plugins/_template/` to a new folder and rename `plugin.json`'s `"id"`.
2. In `plugin.gd`, override `register(api: PluginAPI)` and call any of:

   - `api.register_filter(id, display_name, func(img: Image) -> void)` — mutates
     the current layer's image in place. Appears as a button under "Plugins".
   - `api.register_tool(id, display_name, func() -> Tool)` — factory returning an
     instance of a class extending `res://scenes/tools/Tool.gd`. Appears as a
     selectable tool button.
   - `api.register_menu_action(label, func() -> void)` — anything else. Appears
     as a button under "Plugins".

3. Restart Pixellent.

See the three bundled examples for working reference implementations:

- `plugins/grayscale_filter/` — simplest possible filter plugin
- `plugins/invert_filter/` — another filter plugin
- `plugins/checker_stamp_tool/` — registers a whole new drawing **tool** (not just
  a filter), split into `plugin.gd` (entry point) + `checker_stamp_tool.gd` (the
  actual `Tool` subclass) to show how to organize a bigger plugin

## What plugins can't do (by design)

Plugins only get a `PluginAPI` object — they can't reach into `Global`,
`UndoRedoManager`, or `TilemapState` directly except through the read-only
accessors (`get_current_layer_image()`, `get_canvas_size()`). Filters run inside
`PluginManager.apply_filter_to_current_layer()`, which wraps the undo step for
you automatically — a filter plugin never needs to touch undo/redo itself.
