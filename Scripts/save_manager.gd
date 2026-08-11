extends Node

signal save_completed(slot: int)
signal load_completed(slot: int)

const SLOT_PATH_FORMAT = "user://savegame_slot_%d.json"
const PROFILE_PATH = "user://profile.json"
const SLOT_COUNT = 3

var current_slot : int = 1
var current_save_name := ""
var total_playtime := 0.0

var unlocked_achievements : Array[String] = []

var _was_paused := false
var _is_loading := false


# SCHUTZ, DIREKT NACHM LADEN NICHT SCHLIEßEN, SONST "entities" -> LEER


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _ready () -> void:
	_load_profile()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(current_slot, true)
		set_process(false)
		get_tree().quit()
	
func _process(delta: float) -> void:
	total_playtime += delta
	
	var is_paused = GameState.current == GameState.State.PAUSED
	if is_paused and not _was_paused:
		save_game(current_slot)
		print("Game saved on pause")
	_was_paused = is_paused
	
func save_game(slot: int = current_slot, silent: bool = false) -> void:
	current_slot = slot
	
	
	var entities_data : Array = []
	for component in get_tree().get_nodes_in_group("Persist"):
		entities_data.append(component.save())
	
	var player = get_player()
	if player == null:
		push_warning("SaveManager can NOT find Player !")
	var save_data : Dictionary = {
		"name": current_save_name if current_save_name != "" else "Save %d" % slot,
		"cash": player.cash if player else  0,
		"player_position": var_to_str(player.global_position) if player else "",
		"player_rotation": var_to_str(player.global_rotation) if player else "",
		"playtime": roundi(total_playtime),
		"timestamp": Time.get_unix_time_from_system(),
		"entities": entities_data
	}
	
	var file := FileAccess.open(SLOT_PATH_FORMAT % slot, FileAccess.WRITE)
	if file == null:
		push_error("Savegame could not be saved: %s" % FileAccess.get_open_error())
		return
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("Game save on slot %s" % slot)
	print(save_data)
	
	if not silent:
		save_completed.emit(slot)
	
var _scene_load_pending := false
	
func request_load_on_scene_ready(slot: int, silent: bool = false) -> void:
	if _scene_load_pending:
		return
	_scene_load_pending = true
	
	SceneManager.scene_changed.connect(
		func():
			_scene_load_pending = false
			load_game(slot, silent),
		CONNECT_ONE_SHOT
	)
	
func load_game(slot: int, silent: bool = false) -> bool:
	if _is_loading:
		push_warning("SaveManager is already loading Game -  ignored second try !")
		return false
		
	var path := SLOT_PATH_FORMAT % slot
	if not FileAccess.file_exists(path):
		push_warning("No savegame on slot %d" % slot)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Error from parsing file in Slot %d: %s" % [slot, json.get_error_message()])
		return false
	
	_is_loading = true
	
	var save_data : Dictionary = json.data
	current_slot = slot
	current_save_name = save_data.get("name", "Save %d" % slot)
	total_playtime = save_data.get("playtime", 0.0)
	
	var player = get_player()
	if player:
		player.cash = save_data.get("cash", 0)
		if save_data.get("player_position", "") != "":
			player.global_position = str_to_var(save_data["player_position"])
		if save_data.get("player_rotation", "") != "":
			player.global_rotation = str_to_var(save_data["player_rotation"])
	
	await _restore_entities(save_data.get("entities", []))
	
	_is_loading = false
	print("Loaded savegame from Slot %d" % slot)
	if not silent:
		load_completed.emit(slot)
	return true
	
func _restore_entities(entities: Array) -> void:
	for component in get_tree().get_nodes_in_group("Persist"):
		if component.target:
			component.target.queue_free()
	await get_tree().process_frame
	
	var id_to_node : Dictionary = {}
	for entitiy_data in entities:
		var scene : PackedScene = load(entitiy_data["scene"])
		if scene == null:
			push_error("Scene not found: %s" % entitiy_data["scene"])
			continue
		
		var instance = scene.instantiate()
		
		var parent_node : Node = get_tree().current_scene
		var parent_path : String = entitiy_data.get("parent_path", "")
		if parent_path != "":
			var found_parent := get_node_or_null(parent_path)
			if found_parent:
				parent_node = found_parent
			else:
				push_warning("SaveMangager could NOT find original parent '%s' using current_scene" % parent_path)
		
		parent_node.add_child(instance)
		instance.entity_id = entitiy_data["id"]
		instance.global_position = str_to_var(entitiy_data["position"])
		instance.global_rotation = str_to_var(entitiy_data["rotation"])
		
		var component := _find_persistence_component(instance)
		if component:
			component.load_data(entitiy_data)
		
		id_to_node[entitiy_data["id"]] = instance
		
	for entitiy_data in entities:
		var node = id_to_node.get(entitiy_data["id"])
		var component := _find_persistence_component(node) if node else null
		if component:
			component.restore_links(entitiy_data, id_to_node)
	
func _find_persistence_component(node: Node) -> Node:
	for child in node.get_children():
		if child is PersistenceComponent:
			return child
	return null
	
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SLOT_PATH_FORMAT % slot)
	
func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(SLOT_PATH_FORMAT % slot)
	
func rename_save(slot: int, new_name: String) -> bool:
	if not has_save(slot):
		return false
	
	var file := FileAccess.open(SLOT_PATH_FORMAT % slot, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false
	
	var data: Dictionary = json.data
	data["name"] = new_name
	
	var out_file := FileAccess.open(SLOT_PATH_FORMAT % slot, FileAccess.WRITE)
	if out_file == null:
		return false
	out_file.store_string(JSON.stringify(data, "\t"))
	out_file.close()
	
	if slot == current_slot:
		current_save_name = new_name
	
	return true
	
func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	
	var file := FileAccess.open(SLOT_PATH_FORMAT % slot, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var data : Dictionary = json.data
	return {"name": data.get("name", "Save %d" % slot),
		"cash": data.get("cash", 0),
		"playtime": data.get("playtime", 0.0),
		"timestamp": data.get("timestamp", 0)
	}
	
func get_all_slot_infos() -> Array:
	var infos : Array = []
	for i in range(1, SLOT_COUNT + 1):
		infos.append({"slot": i, "info": get_save_info(i)})
	return infos
	
func get_most_recent_slot() -> int:
	var best_slot := -1
	var best_timestamp := -1.0
	
	for entry in get_all_slot_infos():
		var info : Dictionary = entry["info"]
		if info.is_empty():
			continue
		var timestamp : float = info.get("timestamp", 0)
		if timestamp > best_timestamp:
			best_timestamp = timestamp
			best_slot = entry["slot"]
	
	return best_slot
	
func has_any_save() -> bool:
	return get_most_recent_slot() != -1
	
func unlock_achivement(id: String) -> void:
	if id in unlocked_achievements:
		return
	unlocked_achievements.append(id)
	_save_profile()
	print("Achievement unlocked: %s" % id)
	
func has_achivement(id: String) -> bool:
	return id in unlocked_achievements
	
func _save_profile() -> void:
	var profile_data : Dictionary = {
		"achivements": unlocked_achievements
	}
	
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(profile_data, "\t"))
	file.close()
	
func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("Profile could NOT loaded")
		return
	
	var data : Dictionary = json.data
	var achivements : Array = data.get("achievements", [])
	unlocked_achievements.assign(achivements)
	
