extends PanelContainer
class_name LayerRow

@onready var visible_check: CheckBox = $HBox/VisibleCheck
@onready var name_label: Label = $HBox/NameLabel
@onready var opacity_slider: HSlider = $HBox/OpacitySlider
@onready var select_button: Button = $HBox/SelectArea

var _layer: Layer
var _index: int

func setup(layer: Layer, index: int, is_selected: bool) -> void:
	_layer = layer
	_index = index
	name_label.text = layer.layer_name
	visible_check.button_pressed = layer.visible_flag
	opacity_slider.value = layer.opacity * 100.0
	modulate = Color(1, 1, 1, 1) if is_selected else Color(0.82, 0.82, 0.82, 1)
	self_modulate = Color(0.25, 0.35, 0.55) if is_selected else Color(1, 1, 1)

	if not visible_check.toggled.is_connected(_on_visible_toggled):
		visible_check.toggled.connect(_on_visible_toggled)
	if not opacity_slider.value_changed.is_connected(_on_opacity_changed):
		opacity_slider.value_changed.connect(_on_opacity_changed)
	if not select_button.pressed.is_connected(_on_select):
		select_button.pressed.connect(_on_select)
	if not name_label.gui_input.is_connected(_on_name_input):
		name_label.gui_input.connect(_on_name_input)

func _on_visible_toggled(pressed: bool) -> void:
	_layer.visible_flag = pressed
	Global.canvas_dirty.emit()

func _on_opacity_changed(value: float) -> void:
	_layer.opacity = value / 100.0
	Global.canvas_dirty.emit()

func _on_select() -> void:
	Global.set_current_layer(_index)

func _on_name_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		var edit := LineEdit.new()
		edit.text = _layer.layer_name
		name_label.get_parent().add_child(edit)
		edit.grab_focus()
		name_label.hide()
		edit.text_submitted.connect(func(t):
			_layer.layer_name = t if t != "" else _layer.layer_name
			name_label.text = _layer.layer_name
			name_label.show()
			edit.queue_free()
		)
		edit.focus_exited.connect(func():
			if is_instance_valid(edit):
				name_label.show()
				edit.queue_free()
		)
