extends VBoxContainer
class_name Timeline

@onready var frame_list: HBoxContainer = $ScrollContainer/FrameList
@onready var add_button: Button = $Toolbar/AddFrame
@onready var remove_button: Button = $Toolbar/RemoveFrame
@onready var dup_button: Button = $Toolbar/DupFrame
@onready var play_button: Button = $Toolbar/PlayButton
@onready var onion_check: CheckBox = $Toolbar/OnionCheck
@onready var fps_spin: SpinBox = $Toolbar/FpsSpin

const THUMB_SCENE := preload("res://scenes/timeline/FrameThumb.tscn")

var _playing: bool = false
var _play_timer: Timer

func _ready() -> void:
	add_button.pressed.connect(_on_add_frame)
	remove_button.pressed.connect(_on_remove_frame)
	dup_button.pressed.connect(_on_dup_frame)
	play_button.pressed.connect(_on_toggle_play)
	onion_check.toggled.connect(func(v): Global.onion_skin_enabled = v; Global.canvas_dirty.emit())
	fps_spin.value = Global.fps
	fps_spin.value_changed.connect(func(v): Global.fps = int(v))

	_play_timer = Timer.new()
	_play_timer.one_shot = false
	add_child(_play_timer)
	_play_timer.timeout.connect(_advance_playback)

	Global.frames_updated.connect(_rebuild)
	Global.frame_changed.connect(_rebuild)
	Global.project_loaded.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in frame_list.get_children():
		c.queue_free()
	for i in Global.frames.size():
		var thumb := THUMB_SCENE.instantiate()
		frame_list.add_child(thumb)
		thumb.setup(Global.frames[i], i, i == Global.current_frame_index)

func _on_add_frame() -> void:
	var index := Global.current_frame_index + 1
	UndoRedoManager.do_structural(
		"Add Frame",
		func():
			Global.frames.insert(index, Frame.new(Global.canvas_width, Global.canvas_height))
			Global.set_current_frame(index),
		func():
			Global.frames.remove_at(index)
			Global.set_current_frame(clampi(index - 1, 0, Global.frames.size() - 1))
	)
	Global.frames_updated.emit()

func _on_remove_frame() -> void:
	if Global.frames.size() <= 1:
		return
	var index := Global.current_frame_index
	var removed := Global.frames[index]
	UndoRedoManager.do_structural(
		"Remove Frame",
		func():
			Global.frames.remove_at(index)
			Global.set_current_frame(clampi(index - 1, 0, Global.frames.size() - 1)),
		func():
			Global.frames.insert(index, removed)
			Global.set_current_frame(index)
	)
	Global.frames_updated.emit()

func _on_dup_frame() -> void:
	var index := Global.current_frame_index
	var copy := Global.frames[index].duplicate_frame()
	UndoRedoManager.do_structural(
		"Duplicate Frame",
		func():
			Global.frames.insert(index + 1, copy)
			Global.set_current_frame(index + 1),
		func():
			Global.frames.remove_at(index + 1)
			Global.set_current_frame(index)
	)
	Global.frames_updated.emit()

func _on_toggle_play() -> void:
	_playing = not _playing
	play_button.text = "⏸" if _playing else "▶"
	if _playing:
		_play_timer.wait_time = 1.0 / max(1, Global.fps)
		_play_timer.start()
	else:
		_play_timer.stop()

func _advance_playback() -> void:
	var next := (Global.current_frame_index + 1) % Global.frames.size()
	Global.set_current_frame(next)
