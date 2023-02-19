extends Control

onready var mana_value = get_node("Grid/ManaControls/ManaValue")
onready var color = get_node("Grid/Color")
onready var type = get_node("Grid/Type")
onready var rarity = get_node("Grid/Rarity")
onready var sets = get_node("SetContainer/SetList")

func _ready():
	color.add_item("Any")
	color.add_item("White")
	color.add_item("Blue")
	color.add_item("Black")
	color.add_item("Red")
	color.add_item("Green")
	color.add_item("Colorless")
	color.add_item("Multicolor")
	
	type.add_item("Any")
	type.add_item("Land")
	type.add_item("Creature")
	type.add_item("Instant")
	type.add_item("Sorcery")
	type.add_item("Artifact")
	type.add_item("Enchantment")
	type.add_item("Planeswalker")
	type.add_item("Tribal")
	
	rarity.add_item("Any")
	rarity.add_item("Common")
	rarity.add_item("Uncommon")
	rarity.add_item("Rare")
	rarity.add_item("Mythic")
	rarity.add_item("Special")
	
	sets.add_item("Any Set")
	for s in DataHelper.get_sets():
		sets.add_item(s[0])
	
	sets.select(0)

func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		mana_value.editable = false
	else:
		mana_value.editable = true
