extends Control

signal _return_desktop

@onready var tab_buttons : Array[Button] = [
	$VBoxContainer/TabBar/TabJobs,
	$VBoxContainer/TabBar/TabEmployees,
	$VBoxContainer/TabBar/TabCalender,
	$VBoxContainer/TabBar/TabSalaries,
	$VBoxContainer/TabBar/TabKPI
]

@onready var tab_pages : Array = [
	$VBoxContainer/Content/Jobs,
	$VBoxContainer/Content/Employees,
	$VBoxContainer/Content/Calender,
	$VBoxContainer/Content/Salaries,
	$VBoxContainer/Content/KPI
]

func _ready() -> void:
	for i in tab_buttons.size():
		tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
	_on_tab_pressed(0)
	
func _on_tab_pressed(index: int) -> void:
	for i in tab_buttons.size():
		tab_buttons[i].button_pressed = (i == index)
		tab_pages[i].visible = (i == index)
	
func _on_tab_close_pressed() -> void:
	_return_desktop.emit()
	
func _on_home_button_pressed() -> void:
	_return_desktop.emit()

func _on_close_button_pressed() -> void:
	_return_desktop.emit()
