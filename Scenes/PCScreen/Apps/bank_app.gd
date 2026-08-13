extends Control

@onready var chart = $VBoxContainer/Content/ContentRow/LeftColumn/HBoxContainer/ChartPanel/FinancialChart/VBoxContainer/GraphArea

func _ready() -> void:
	GameData.finances_updated.connect(_on_gamedata_finances_updated)
	
func _on_gamedata_finances_updated() -> void:
	# NETWORTH LABEL UND ALLE ANDEREN LABELS HIER DANN AKTUALISIEREN
	chart.set_data(GameData.net_worth_history, GameData.cash_history, GameData.debt_history)
