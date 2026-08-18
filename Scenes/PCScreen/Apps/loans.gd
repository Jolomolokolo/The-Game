extends VBoxContainer

@onready var total_debt_value : Label = $SummaryBar/TotalDebt/TotalDebtLabel
@onready var monthly_payments_value : Label = $SummaryBar/MonthlyPayments/MonthlyPaymentsLabel
@onready var credit_score_value : Label = $SummaryBar/CreditScore/CreditScoreLabel

@onready var loan_list : VBoxContainer = $HBoxContainer/ScrollContainer/VBoxContainer

@onready var amount_slider : HSlider = $HBoxContainer/NewLoanPanel/HBoxContainer/VBoxContainer/AmountSlider
@onready var amount_label : Label = $HBoxContainer/NewLoanPanel/HBoxContainer/VBoxContainer/AmountLabel
@onready var rate_label : Label = $HBoxContainer/NewLoanPanel/HBoxContainer/VBoxContainer/RateLabel
@onready var monthly_preview_label : Label = $HBoxContainer/NewLoanPanel/HBoxContainer/VBoxContainer/MonthlyPreviewLabel
@onready var apply_button : Button = $HBoxContainer/NewLoanPanel/HBoxContainer/VBoxContainer/ApplyButton

const TERM_MONTHS := 24

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_NEGATIVE := Color(0.973, 0.443, 0.443, 1.0)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)

func _ready() -> void:
	GameData.finances_updated.connect(_refresh_all)
	GameData.loan_taken.connect(func(_1): _refresh_all())
	GameData.loan_paid_off.connect(func(_1): _refresh_all())
	
	amount_slider.min_value = 0
	amount_slider.max_value = GameData.get_max_loan_amount()
	amount_slider.value_changed.connect(_on_slider_changed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	_refresh_all()
	
func _refresh_all() -> void:
	total_debt_value.text = NumberFormat.format(GameData.get_total_debt())
	monthly_payments_value.text = NumberFormat.format(GameData.get_total_monthly_payments()) + " /mo"
	credit_score_value.text = str(GameData.get_credit_score())
	
	amount_slider.max_value = GameData.get_max_loan_amount()
	_update_new_loan_preview(amount_slider.value)
	
	_rebuild_loan_list()
	
func _rebuild_loan_list() -> void:
	for child in loan_list.get_children():
		child.queue_free()
	
	if GameData.loans.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active loans"
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		loan_list.add_child(empty_label)
		return
	
	for loan in GameData.loans:
		_add_loan_card(loan)
	
func _add_loan_card(loan: Dictionary) -> void:
	var card := PanelContainer.new()
	
	
	
	
	
	
	
