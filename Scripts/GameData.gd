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

signal cash_changed(new_value: int, difference: int)
signal transaction_added(transaction: Dictionary)
signal finances_updated
signal loan_taken(loan: Dictionary)
signal loan_paid_off(loan: Dictionary)

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
var loans : Array[Dictionary] = []
const MAX_TRANSACTIONS := 500

func apply_preset(preset: Preset) -> void:
	if preset == Preset.CUSTOM:
		return
	var data: Dictionary = PRESETS[preset]
	start_cash = data["start_cash"]
	
func apply_custom_preset(cash: int, health: int) -> void:
	start_cash = cash
	start_health = health
	
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
	
func get_recent_transactions(count: int) -> Array:
	var start_index = max(0, transactions.size() - count)
	return transactions.slice(start_index)
	
func get_transactions_for_month(month: int, year: int) -> Array:
	return transactions.filter(func(t): return t["month"] == month and t["year"] == year)
	
func get_net_worth() -> float:
	return cash + stocks_value + real_estate_value + company_value - debt
	
func get_total_debt() -> float:
	var total := 0.0
	for loan in loans:
		total += loan["remaining"]
	return total
	
func get_total_monthly_payments() -> float:
	var total := 0.0
	for loan in loans:
		total += loan["monthly_payment"]
	
func get_credit_score() -> int:
	var net_worth = get_net_worth()
	var debt = get_total_debt()
	
	var base_score = 580
	base_score += int(clamp(net_worth / 1000.0, 0, 200))
	
	if net_worth > 0:
		var debt_ratio = debt / max(net_worth, 1.0)
		base_score -= int(clamp(debt_ratio * 150.0, 0, 150))
	
	return clampi(base_score, 300, 850)
	
func get_max_loan_amount() -> float:
	var score = get_credit_score()
	var score_factor = float(score - 300) / (850.0 - 300.0)
	return max(cash, get_net_worth() * 0.5) * (0.5 + score_factor * 2.0)
	
func get_interest_rate_for_amount(amount: float) -> float:
	var score = get_credit_score()
	var base_rate := 0.15
	var score_factor = float(score - 300) / (850.0 - 300.0)
	var rate = lerp(base_rate, 0.03, score_factor)
	
	var max_amount = get_max_loan_amount()
	if max_amount > 0:
		rate += (amount / max_amount)
	
	return rate
	
func apply_for_loan(amount: float, term_months: int) -> bool:
	if amount <= 0 or amount > get_max_loan_amount():
		return false
	
	var rate = get_interest_rate_for_amount(amount)
	var monthly_rate = rate / 12.0
	var monthly_payment = amount * (monthly_rate * pow(1 + monthly_rate, term_months)) / (pow(1 + monthly_rate, term_months) - 1)
	
	var loan := {
		"id": "loan_%d" % Time.get_ticks_usec(),
		"name": "Personal Loan",
		"prinicpal": amount,
		"remaining": amount,
		"interest_rate": rate,
		"monthly_payment": monthly_payment,
		"term_months": term_months,
		"months_paid": 0
	}
	
	loans.append(loan)
	add_cash(int(amount), "Loan Received")
	loan_taken.emit(loan)
	finances_updated.emit()
	return true
	
func _process_loan_payments() -> void:
	var paid_off : Array[Dictionary] = []
	
	for loan in loans:
		var payment = min(loan["monthly_payment"], loan["remaining"])
		loan["remaining"] -= payment
		loan["months_paid"] += 1
		add_cash(-int(payment), "Loan Payment: %s" % loan["name"])
		
		if loan["remaining"] <= 0.01:
			paid_off.append(loan)
	
	for loan in paid_off:
		loan.erase(loan)
		loan_paid_off.emit(loan)
	
func advance_month() -> void:
	_process_loan_payments()
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	net_worth_history.append(get_net_worth())
	cash_history.append(float(cash))
	debt_history.append(debt)
	
	finances_updated.emit()
	
