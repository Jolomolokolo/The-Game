extends Node3D

@onready var warn_light_roof_red : MeshInstance3D = $RoofLightRed
@onready var warn_light_roof_blue : MeshInstance3D = $RoofLightBlue
@onready var warn_light_grill_red : MeshInstance3D = $GrillLightRed
@onready var warn_light_grill_blue : MeshInstance3D = $GrillLightBlue

var off_material : StandardMaterial3D
var mat_red : StandardMaterial3D
var mat_blue : StandardMaterial3D

var in_sequence = false

func _ready():
	_build_materials()
	
func _build_materials():
	off_material = StandardMaterial3D.new()
	off_material.albedo_color = Color(0.12, 0.12, 0.12)
	mat_red = _make_glow_material(Color(1, 0, 0))
	mat_blue = _make_glow_material(Color(0, 0, 1))
	
func _make_glow_material(color: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	return mat
	
func _process(_delta: float):
	if not in_sequence:
		in_sequence = true
		warn_light_roof_red.material_override = mat_red
		warn_light_roof_blue.material_override = off_material
		warn_light_grill_red.material_override = mat_red
		warn_light_grill_blue.material_override = off_material
		await get_tree().create_timer(0.25).timeout
		warn_light_roof_red.material_override = off_material
		warn_light_roof_blue.material_override = mat_blue
		warn_light_grill_red.material_override = off_material
		warn_light_grill_blue.material_override = mat_blue
		await get_tree().create_timer(0.25).timeout
		in_sequence = false
