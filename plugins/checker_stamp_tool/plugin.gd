extends PixellentPlugin

## Entry point loaded by PluginManager. Registers the CheckerStampTool defined in
## checker_stamp_tool.gd (kept as a separate file since it's a full Tool subclass,
## not a one-line filter — plugin.gd can be as small as this and just wire things up).

const CheckerStampTool := preload("res://plugins/checker_stamp_tool/checker_stamp_tool.gd")

func register(api: PluginAPI) -> void:
	api.register_tool("checker_stamp", "Checker Stamp", func(): return CheckerStampTool.new())
