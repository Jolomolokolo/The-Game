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
	
	if GameData.loans.size() >= GameData.MAX_LOANS:
		amount_slider.editable = false
		apply_button.disabled = true
		amount_label.text = "Maximum of %d loans reached" % GameData.MAX_LOANS
		rate_label.text = ""
		monthly_preview_label.text = "Pay off any existing loans to borrow more"
	else:
		amount_slider.editable = true
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
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_BG
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	loan_list.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label := Label.new()
	name_label.text = loan["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var rate_display := Label.new()
	rate_display.text = "%.1f%% APR" % (loan["interest_rate"] * 100.0)
	rate_display.add_theme_color_override("font_color", COLOR_MUTED)
	header.add_child(rate_display)
	
	var numbers_row := HBoxContainer.new()
	vbox.add_child(numbers_row)
	
	var remaining_label := Label.new()
	remaining_label.text = "Remaining: %s" % NumberFormat.format(loan["remaining"])
	remaining_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	numbers_row.add_child(remaining_label)
	
	var monthly_label := Label.new()
	monthly_label.text = "Monthly: %s" % NumberFormat.format(loan["monthly_payment"])
	numbers_row.add_child(monthly_label)
	
	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = loan["principal"]
	progress.value = loan["principal"] - loan["remaining"]
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(progress)
	
func _on_slider_changed(value: float) -> void:
	_update_new_loan_preview(value)
	
func _update_new_loan_preview(amount: float) -> void:
	amount_label.text = "Amount: %s" % NumberFormat.format(amount)
	
	if amount <= 0:
		rate_label.text = "Rate: -"
		monthly_preview_label.text = "Monthly Payment: -"
		apply_button.disabled = true
		return
	
	var rate = GameData.get_interest_rate_for_amount(amount)
	var monthly_rate = rate / 12.0
	var monthly_payment = amount * (monthly_rate * pow(1 + monthly_rate, TERM_MONTHS)) / (pow(1 + monthly_rate, TERM_MONTHS) - 1)
	
	rate_label.text = "Rate: %.1f%% APR" % (rate * 100.0)
	monthly_preview_label.text = "Monthly Payment: %s (%d months)" % [NumberFormat.format(monthly_payment), TERM_MONTHS]
	apply_button.disabled = false
	
func _on_apply_pressed() -> void:
	var success = GameData.apply_for_loan(amount_slider.value, TERM_MONTHS)
	if success:
		amount_slider.value = 0
	
