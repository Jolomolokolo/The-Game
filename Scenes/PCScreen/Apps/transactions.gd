extends VBoxContainer

@onready var type_all_button : Button = $FilterBar/TypeAllButton
@onready var type_income_button : Button = $FilterBar/TypeIncomeButton
@onready var type_expense_button : Button = $FilterBar/TypeExpenseButton

@onready var range_6m_button : Button = $FilterBar/Range6MButton
@onready var range_2y_button : Button = $FilterBar/Range2YButton
@onready var range_max_button : Button = $FilterBar/RangeMAXButton

@onready var transaction_list : VBoxContainer = $ScrollContainer/HBoxContainer/TransactionList

enum TimeRange { SIX_MONTHS, TWO_YEARS, MAX }
enum TypeFilter { ALL, INCOME, EXPENSE }

var current_range := TimeRange.MAX
var current_type := TypeFilter.ALL

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_POSITIVE := Color(0.29, 0.871, 0.502, 1.0)
const COLOR_NEGATIVE := Color(0.973, 0.443, 0.443, 1.0)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)

func _ready() -> void:
	type_all_button.pressed.connect(_on_type_filter_pressed.bind(TypeFilter.ALL))
	type_income_button.pressed.connect(_on_type_filter_pressed.bind(TypeFilter.INCOME))
	type_expense_button.pressed.connect(_on_type_filter_pressed.bind(TypeFilter.EXPENSE))
	
	range_6m_button.pressed.connect(_on_range_filter_pressed.bind(TimeRange.SIX_MONTHS))
	range_2y_button.pressed.connect(_on_range_filter_pressed.bind(TimeRange.TWO_YEARS))
	range_max_button.pressed.connect(_on_range_filter_pressed.bind(TimeRange.MAX))
	
	GameData.transaction_added.connect(func(_t): _rebuild_list())
	
	type_all_button.button_pressed = true
	range_max_button.button_pressed = true
	_rebuild_list()
	
func _on_type_filter_pressed(value: int) -> void:
	current_type = value
	type_all_button.button_pressed = (value == TypeFilter.ALL)
	type_income_button.button_pressed = (value == TypeFilter.INCOME)
	type_expense_button.button_pressed = (value == TypeFilter.EXPENSE)
	_rebuild_list()
	
func _on_range_filter_pressed(value: int) -> void:
	current_range = value
	range_6m_button.button_pressed = (value == TimeRange.SIX_MONTHS)
	range_2y_button.button_pressed = (value == TimeRange.TWO_YEARS)
	range_max_button.button_pressed = (value == TimeRange.MAX)
	_rebuild_list()
	
func _get_filtered_transactions() -> Array:
	var current_absolute := GameData.current_year * 12 + GameData.current_month
	
	return GameData.transactions.filter(func(t):
		if current_range != TimeRange.MAX:
			var t_absolute = t["year"] * 12 + t["month"]
			var months_ago = current_absolute - t_absolute
			var max_months = 6 if current_range == TimeRange.SIX_MONTHS else 24
			if months_ago > max_months:
				return false
		
		if current_type == TypeFilter.INCOME and t["amount"] <= 0:
			return false
		if current_type == TypeFilter.EXPENSE and t["amount"] >= 0:
			return false
		
		return true
		)
	
func _rebuild_list() -> void:
	for child in transaction_list.get_children():
		child.queue_free()
	
	var filtered := _get_filtered_transactions()
	filtered.reverse()
	
	if filtered.is_empty():
		_add_empty_label()
		return
	
	var last_month := -1
	var last_year := -1
	
	for t in filtered:
		if t["month"] != last_month or t["year"] != last_year:
			_add_month_header(t["month"], t["year"])
			last_month = t["month"]
			last_year = t["year"]
		
		_add_transaction_row(t)
	
func _add_month_header(month: int, year: int) -> void:
	var label := Label.new()
	label.text = "%02d/%d" % [month, year]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	transaction_list.add_child(label)
	
func _add_empty_label() -> void:
	var label := Label.new()
	label.text = "No transactions for this billing period"
	label.add_theme_color_override("font_color", COLOR_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transaction_list.add_child(label)
	
func _add_transaction_row(t: Dictionary) -> void:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_BG
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	row.add_theme_stylebox_override("panel", style)
	transaction_list.add_child(row)
	
	var hbox := HBoxContainer.new()
	row.add_child(hbox)
	
	var reason_label := Label.new()
	reason_label.text = t["reason"] if t["reason"] != "" else "Transaction"
	reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(reason_label)
	
	
	# DATE LABEL MIT GAME ZEITEN
	#var date_label := Label.new()
	#date_label.text = Time.get_datetime_string_from_unix_time(int(t["timestamp"]), true).replace("T", " ")
	#date_label.add_theme_color_override("font_color", COLOR_MUTED)
	#date_label.add_theme_font_size_override("font_size", 13)
	#hbox.add_child(date_label)
	
	var amount : int = t["amount"]
	var sign_str := "+" if amount > 0 else ""
	var amount_label := Label.new()
	amount_label.text = "%s%d €" % [sign_str, amount]
	amount_label.add_theme_color_override(
		"font_color",
		COLOR_POSITIVE if amount > 0 else COLOR_NEGATIVE
	)
	hbox.add_child(amount_label)
	
