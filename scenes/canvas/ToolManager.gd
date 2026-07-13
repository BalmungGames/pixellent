extends RefCounted
class_name ToolManager

static func create(tool_name: String) -> Tool:
	match tool_name:
		"pencil":
			return PencilTool.new()
		"eraser":
			return EraserTool.new()
		"bucket":
			return BucketTool.new()
		"line":
			return LineTool.new()
		"rect":
			var rt := RectTool.new()
			rt.filled = Global.get_meta("shape_filled", false)
			return rt
		"ellipse":
			var et := EllipseTool.new()
			et.filled = Global.get_meta("shape_filled", false)
			return et
		"picker":
			return ColorPickerTool.new()
		"select":
			return SelectTool.new()
		"shade":
			return ShadeTool.new()
		"dither":
			return DitherTool.new()
		_:
			if PluginManager.has_tool(tool_name):
				return PluginManager.create_tool(tool_name)
			return PencilTool.new()
