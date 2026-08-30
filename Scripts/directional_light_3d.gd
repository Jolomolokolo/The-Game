extends DirectionalLight3D

@export var day_duration := 1200.0

var time := 8.0
var day_color := Color(1.0, 0.95, 0.8)
var sunset_color := Color(1.0, 0.5, 0.2)
var night_color := Color(0.05, 0.05, 0.2)

func _ready():
	add_to_group("day_night")

func _process(delta):
	time += (24.0 / day_duration) * delta
	if time >= 24.0:
		time = 0.0
		GameData.advance_day()
	
	var sun_progress = time / 24.0
	rotation_degrees.x = lerp(-180.0, 180.0, sun_progress) - 90.0
	
	var sun_visible = rotation_degrees.x > -179.0 and rotation_degrees.x < -1.0
	
	if not sun_visible:
		light_energy = lerp(light_energy, 0.0, delta * 5.0)
		shadow_enabled = false
	elif time < 7.0:
		var progress = (time - 5.0) / 2.0
		light_color = night_color.lerp(sunset_color, progress)
		light_energy = lerp(light_energy, lerp(0.0, 0.5, progress), delta * 0.8)
		shadow_enabled = false
	elif time < 9.0:
		var progress = (time - 7.0) / 2.0
		light_color = sunset_color.lerp(day_color, progress)
		light_energy = lerp(light_energy, lerp(0.5, 1.5, progress), delta * 1.0)
		shadow_enabled = true
	elif time < 17.0:
		light_color = light_color.lerp(day_color, delta * 1.0)
		light_energy = lerp(light_energy, 1.5, delta * 1.0)
		shadow_enabled = true
	elif time < 19.0:
		var progress = (time - 17.0) / 2.0
		light_color = day_color.lerp(sunset_color, progress)
		light_energy = lerp(light_energy, lerp(1.5, 0.3, progress), delta * 1.0)
		shadow_enabled = true
	elif time < 21.0:
		var progress = (time - 19.0) / 2.0
		light_color = sunset_color.lerp(night_color, progress)
		light_energy = lerp(light_energy, lerp(0.3, 0.0, progress), delta * 1.5)
		shadow_enabled = false
	else:
		light_color = light_color.lerp(night_color, delta * 0.5)
		light_energy = lerp(light_energy, 0.0, delta * 0.5)
		shadow_enabled = false
	
	_update_environment(delta)

func _update_environment(delta):
	var env = $"../WorldEnvironment".environment
	if env == null:
		return
	
	if time < 5.0 or time > 21.0:
		env.background_energy_multiplier = lerp(env.background_energy_multiplier, 0.04, delta * 0.5)
		env.ambient_light_energy = lerp(env.ambient_light_energy, 0.08, delta * 0.5)
		env.ambient_light_sky_contribution = lerp(env.ambient_light_sky_contribution, 0.0, delta * 0.5)
	elif time < 7.0 or time > 19.0:
		env.background_energy_multiplier = lerp(env.background_energy_multiplier, 0.2, delta * 0.5)
		env.ambient_light_energy = lerp(env.ambient_light_energy, 0.2, delta * 0.5)
		env.ambient_light_sky_contribution = lerp(env.ambient_light_sky_contribution, 0.1, delta * 0.5)
	elif time < 9.0 or time > 17.0:
		env.background_energy_multiplier = lerp(env.background_energy_multiplier, 0.6, delta * 0.5)
		env.ambient_light_energy = lerp(env.ambient_light_energy, 0.5, delta * 0.5)
		env.ambient_light_sky_contribution = lerp(env.ambient_light_sky_contribution, 0.4, delta * 0.5)
	else:
		env.background_energy_multiplier = lerp(env.background_energy_multiplier, 1.0, delta * 0.5)
		env.ambient_light_energy = lerp(env.ambient_light_energy, 1.0, delta * 0.5)
		env.ambient_light_sky_contribution = lerp(env.ambient_light_sky_contribution, 1.0, delta * 0.5)
