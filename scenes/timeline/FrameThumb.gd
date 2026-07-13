extends PanelContainer
class_name FrameThumb

@onready var texture_rect: TextureRect = $VBox/TextureRect
@onready var label: Label = $VBox/Label
@onready var button: Button = $VBox/Button

var _index: int

func setup(frame: Frame, index: int, is_selected: bool) -> void:
	_index = index
	label.text = str(index + 1)
	var flat := frame.flatten()
	texture_rect.texture = ImageTexture.create_from_image(flat)
	self_modulate = Color(0.25, 0.35, 0.55) if is_selected else Color(1, 1, 1)
	if not button.pressed.is_connected(_on_pressed):
		button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Global.set_current_frame(_index)
