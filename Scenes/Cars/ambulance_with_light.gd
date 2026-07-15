extends Node3D

@onready var blue_lights : Array[MeshInstance3D] = [
	$RoofLightFrontRight, $RoofLightFrontLeft,
	$RoofLightMiddleRight, $RoofLightMiddleLeft,
	$RoofLightBackRight, $RoofLightBackLeft
]

@onready var red_lights : Array[MeshInstance3D] = [
	$CaseLightFrontRight, $CaseLightFrontLeft,
	$CaseLightSideRight, $CaseLightSideLeft
]

var off_material_blue : StandardMaterial3D
var off_material_red : StandardMaterial3D
var mat_blue : StandardMaterial3D
var mat_red : StandardMaterial3D

var step_duration := 0.15
var pattern_index := 0

var patterns := []

func _ready():
	_build_materials()
	_build_patterns()
	_run_light_loop()
	
func _build_materials():
	off_material_blue = StandardMaterial3D.new()
	off_material_blue.albedo_color = Color(0, 0, 0.8)
	
	off_material_red = StandardMaterial3D.new()
	off_material_red.albedo_color = Color(0.8, 0, 0)
	
	mat_blue = _make_glow_material(Color(0, 0, 1))
	mat_red = _make_glow_material(Color(1, 0, 0))
	
func _make_glow_material(color : Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 5.0
	return mat
	
func _build_patterns():
	
	patterns.append([
		_frame([1,0,1,0,1,0, 0,1,0,1]),
		_frame([0,1,0,1,0,1, 1,0,1,0])
	])
	
	patterns.append([
		_frame([1,1,0,0,0,0, 1,1,0,0]),
		_frame([0,0,1,1,0,0, 0,0,1,1]),
		_frame([0,0,0,0,1,1, 0,0,0,0])
	])
	
	patterns.append([
		_frame([1,1,1,1,1,1, 1,1,1,1]),
		_frame([0,0,0,0,0,0, 0,0,0,0]),
		_frame([1,1,1,1,1,1, 1,1,1,1]),
		_frame([0,0,0,0,0,0, 0,0,0,0])
	])
	
	patterns.append([
		_frame([1,1,1,1,1,1, 0,0,0,0]),
		_frame([0,0,0,0,0,0, 1,1,1,1])
	])
	
func _frame(states: Array) -> Array:
	return states
	
func _run_light_loop():
	while true:
		var pattern = patterns[pattern_index]
		var repeats = randi_range(2, 4)
		for r in repeats:
			for frame in pattern:
				_apply_frame(frame)
				await get_tree().create_timer(step_duration).timeout
		pattern_index = (pattern_index + 1) % patterns.size()
	
func _apply_frame(frame: Array):
	for i in blue_lights.size():
		blue_lights[i].material_override = mat_blue if frame[i] == 1 else off_material_blue
	for i in red_lights.size():
		var frame_idx = blue_lights.size() + i
		red_lights[i].material_override = mat_red if frame[frame_idx] == 1 else off_material_red
