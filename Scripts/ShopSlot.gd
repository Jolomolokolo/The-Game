extends PanelContainer

signal item_selected(item: ShopItem)

@onready var icon_rect : TextureRect = $VBoxContainer/Icon
@onready var name_label : Label = $VBoxContainer/NameLabel
@onready var price_label : Label = $VBoxContainer/PriceLabel
@onready var buy_button : Button = $VBoxContainer/BuyButton

var item: ShopItem

func setup(shop_item: ShopItem):
	item = shop_item
	icon_rect.texture = item.icon
	name_label.text = item.item_name
	price_label.text = str(item.price) + " Cash"
	
func _on_buy_button_pressed() -> void:
	item_selected.emit(item)
