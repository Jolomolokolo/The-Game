extends Node3D

func _ready():
	await get_tree().process_frame
	var rail_switch_1 = get_node("RailNetwork/RailSwitch_1")
	
	rail_switch_1.connections = {
		"Track_A": ["Track_B", "Track_C"],
		"Track_B": ["Tack_A"],
		"Track_C": ["Track_A"]
	}
	
	
