extends Control

# Abkürzungen für Millionen, Milliarden und eventuell tausend, damit nicht so clustered

signal _return_desktop

@onready var tab_buttons : Array[Button] = [
	$VBoxContainer/TabBar/TabDashboard,
	$VBoxContainer/TabBar/TabTransactions,
	$VBoxContainer/TabBar/TabLoans,
	$VBoxContainer/TabBar/TabRealEstates
]

@onready var tab_pages : Array = [
	$VBoxContainer/Content/Dashboard,
	$VBoxContainer/Content/Transactions,
	$VBoxContainer/Content/Loans,
	$VBoxContainer/Content/RealEstates
]

@onready var cash_label = $VBoxContainer/StatusBar/HBoxContainer/CashDisplay/CashLabel
@onready var networth_label_dashboard = $VBoxContainer/Content/Dashboard/LeftColumn/SummaryRow/NetWorth/NetWorthLabel
@onready var cash_label_dashboard = $VBoxContainer/Content/Dashboard/LeftColumn/SummaryRow/Cash/CashLabel
@onready var monthlyflow_label_dashboard = $VBoxContainer/Content/Dashboard/LeftColumn/SummaryRow/MonthlyFlow/MonthlyFlowLabel
@onready var chart = $VBoxContainer/Content/Dashboard/LeftColumn/HBoxContainer/ChartPanel/FinancialChart/VBoxContainer/GraphArea
#@onready var transaction_list_container = $VBoxContainer/Content/Transactions/VBoxContainer

func _ready() -> void:
	GameData.finances_updated.connect(_on_gamedata_finances_updated)
	GameData.transaction_added.connect(_on_transaction_added)
	
	for i in tab_buttons.size():
		tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
	_on_tab_pressed(0)
	
func _on_tab_pressed(index: int) -> void:
	for i in tab_buttons.size():
		tab_buttons[i].button_pressed = (i == index)
		tab_pages[i].visible = (i == index)
	
func _on_gamedata_finances_updated() -> void:
	chart.set_data(GameData.net_worth_history, GameData.cash_history, GameData.debt_history)
	
func _on_transaction_added(transaction: Dictionary) -> void:
	var entry := Label.new()
	var sign_str = "+" if transaction["amount"] > 0 else ""
	entry.text = "%s%d € - %s" % [sign_str, transaction["amount"], transaction["reason"]]
	entry.modulate = Color(0.3, 1, 0.3) if transaction["amount"] > 0 else Color(1, 0.3, 0.3)
	#transaction_list_container.add_child(entry)
	#transaction_list_container.move_child(entry, 0)
	
	# NETWORTH LABEL UND ALLE ANDEREN LABELS HIER DANN AKTUALISIEREN
	cash_label.text = NumberFormat.format(GameData.cash)
	cash_label_dashboard.text = NumberFormat.format(GameData.cash)

func _on_tab_close_pressed() -> void:
	_return_desktop.emit()
