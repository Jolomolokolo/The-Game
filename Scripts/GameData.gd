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
	
signal cash_changed(new_value: int, difference: int)
signal transaction_added(transaction: Dictionary)
signal finances_updated

var cash : int = 0
var stocks_value : float = 0.0
var real_estate_value : float = 0.0
var company_value : float = 0.0
var company_monthly_profit : float = 0.0

var current_month : int = 1
var current_year : int = 1

var net_worth_history : Array[float] = []
var cash_history : Array[float] = []
var debt_history : Array[float] = []
var debt : float = 0.0

var transactions : Array[Dictionary] = []
const MAX_TRANSACTIONS := 500

func _ready() -> void:
	cash = start_cash
	
func add_cash(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
		
	cash += amount
	
	var transaction := {
		"amount": amount,
		"reason": reason,
		"balance_after": cash,
		"month": current_month,
		"year": current_year,
		"timestamp": Time.get_unix_time_from_system()
	}
	transactions.append(transaction)
	
	if transactions.size() > MAX_TRANSACTIONS:
		transactions.pop_front()
	
	cash_changed.emit(cash, amount)
	transaction_added.emit(transaction)
	
	# TRANSACTION CODES HERE
	
func get_net_worth() -> float:
	return cash + stocks_value + real_estate_value + company_value - debt
	
func advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	net_worth_history.append(get_net_worth())
	cash_history.append(float(cash))
	debt_history.append(debt)
	
	finances_updated.emit()
	
