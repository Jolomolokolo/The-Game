extends Node

enum Preset { EASY, NORMAL, HARD, CUSTOM }

var start_cash : int = 250
var start_health : int = 100

const PRESETS := {
	Preset.EASY: {
		start_cash = 500
	},
	Preset.NORMAL: {
		start_cash = 250
	},
	Preset.HARD: {
		start_cash = 100
	}
}

func apply_preset(preset: Preset) -> void:
	if preset == Preset.CUSTOM:
		return
	var data: Dictionary = PRESETS[preset]
	start_cash = data["start_cash"]
	
func apply_custom_preset(cash: int, health: int) -> void:
	start_cash = cash
	start_health = health
