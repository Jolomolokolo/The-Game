extends Control

@onready var save1_button = $Save1/Save1
@onready var save2_button = $Save2/Save2
@onready var save3_button = $Save3/Save3

@onready var save1_description = $Save1/SaveDescription1
@onready var save2_description = $Save2/SaveDescription2
@onready var save3_description = $Save3/SaveDescription3

@onready var save1_name = $Save1/SaveName1
@onready var save2_name = $Save2/SaveName2
@onready var save3_name = $Save3/SaveName3

@onready var name_input = $NameInput
@onready var rename_button = $NameInput/RenameButton
@onready var delete_button = $DeleteButton

var start = false
var selected_slot : int = 1
var _delete_armed_slot : int = -1

const SELECTED_COLOR := Color(1, 1, 0.6)
const UNSELECTED_COLOR := Color.WHITE
const DELETE_LABEL_DEFAULT := "Delete"
const DELETE_LABEL_CONFIRMATION := "Confirm Deletion"

func _ready() -> void:
	_refresh_description()
	_select_slot(1)

func _process(_delta: float) -> void:
	if start:
		start = false
		if SaveManager.has_save(selected_slot):
			SaveManager.request_load_on_scene_ready(selected_slot)
		else:
			SaveManager.current_slot = selected_slot
	
		SceneManager.change_scene("res://main.tscn")
	
func _on_target_scene_ready() -> void:
	SaveManager.load_game(selected_slot)
	
func _refresh_description():
	save1_description.text = _format_slot_info(1)
	save2_description.text = _format_slot_info(2)
	save3_description.text = _format_slot_info(3)
	
	save1_name.text = _format_slot_title(1)
	save2_name.text = _format_slot_title(2)
	save3_name.text = _format_slot_title(3)
	
func _format_slot_title(slot: int) -> String:
	var info : Dictionary = SaveManager.get_save_info(slot)
	
	if info.is_empty():
		return "Empty Slot %d" % slot
	
	return info.get("name", "Save %d" % slot)
	
func _format_slot_info(slot: int) -> String:
	var info : Dictionary = SaveManager.get_save_info(slot)
	
	if info.is_empty():
		return "No Save"
	
	var total_seconds : int = int(info.get("playtime", 0))
	var minutes := total_seconds / 60
	var hours := total_seconds % 60
	var datetime := Time.get_datetime_string_from_unix_time(info.get("timestamp", 0))
	
	return "Cash: %d\nPlaytime: %02d:%02d\nSaved: %s" % [
		info.get("cash", 0), minutes, hours, datetime
	]
	
func _on_return_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/StartPage.tscn")
	
func _select_slot(slot: int) -> void:
	selected_slot = slot
	_delete_armed_slot = -1
	
	save1_button.modulate = SELECTED_COLOR if slot == 1 else UNSELECTED_COLOR
	save2_button.modulate = SELECTED_COLOR if slot == 2 else UNSELECTED_COLOR
	save3_button.modulate = SELECTED_COLOR if slot == 3 else UNSELECTED_COLOR
	
	var info : Dictionary = SaveManager.get_save_info(slot)
	name_input.text = info.get("name", "")
	name_input.editable = not info.is_empty()
	
	delete_button.text = DELETE_LABEL_DEFAULT
	delete_button.disabled = info.is_empty()
	
func _on_save_1_pressed() -> void:
	_select_slot(1)
	save2_button.release_focus()
	save3_button.release_focus()
	
func _on_save_2_pressed() -> void:
	_select_slot(2)
	save1_button.release_focus()
	save3_button.release_focus()
	
func _on_save_3_pressed() -> void:
	_select_slot(3)
	save1_button.release_focus()
	save2_button.release_focus()

func _on_start_button_pressed() -> void:
	start = true

func _on_rename_button_pressed() -> void:
	var new_name = name_input.text.strip_edges()
	if new_name == "":
		return
	
	if SaveManager.rename_save(selected_slot, new_name):
		_refresh_description()
	
func _on_delete_button_pressed() -> void:
	if _delete_armed_slot != selected_slot:
		_delete_armed_slot = selected_slot
		delete_button.text = DELETE_LABEL_CONFIRMATION
		return
	
	SaveManager.delete_save(selected_slot)
	_delete_armed_slot = -1
	_refresh_description()
	_select_slot(selected_slot)
	
