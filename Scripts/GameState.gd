extends Node

enum State { PLAYING, UI , PAUSED }
enum VehicleType { NONE, CAR, TRAIN }

var current: State = State.PLAYING
var current_vehicle_type := VehicleType.NONE

func set_state(new_state: State) -> void:
	if current == new_state:
		return
	
	current = new_state
	
	match current:
		State.PLAYING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		State.UI:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		State.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func set_vehicle(type: VehicleType) -> void:
	if current_vehicle_type == type:
		return
	
	current_vehicle_type = type
	
func can_player_move() -> bool:
	return current == State.PLAYING
	
func is_vehicle_active() -> bool:
	return current_vehicle_type != VehicleType.NONE
	
