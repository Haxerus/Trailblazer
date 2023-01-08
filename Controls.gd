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
	
	var set_text = load_sets()
	for s in set_text:
		sets.add_item(s)
	
	sets.select(0)

func load_sets():
	var file = File.new()
	file.open("res://text/sets.txt", File.READ)
	var content = []
	while !file.eof_reached():
		content.append(file.get_line())
	file.close()
	return content

func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		mana_value.editable = false
	else:
		mana_value.editable = true
