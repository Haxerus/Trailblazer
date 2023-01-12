extends Node

enum Mode {
	STANDARD, 
	COMMANDER
}

var mode = Mode.STANDARD

var save_path : String

var sets : Array
var set_codes : Array

var card_objects = []
var collection = []

func _ready():
	randomize()
	make_save_dir()
	sets = load_sets()
	set_codes = load_set_codes()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_deck()


func set_mode(m):
	mode = m


func get_mode():
	return mode

func clear_card_objects():
	card_objects.clear()


func add_card_object(card):
	card_objects.append(card)


func add_to_collection(card):
	if "name" in card:
		collection.append(card["name"])
	else:
		collection.append(card)


func get_collection_as_text():
	var coll_text = ""
	
	for card in collection:
		coll_text += str(card, "\n")
	
	return coll_text


func get_cards_without_duplicates():
	var filtered_cards = []
	
	for card in card_objects:
		if card["name"] in collection:
			continue
		
		filtered_cards.append(card)
	
	return filtered_cards


func get_random_cards(n, allow_dupes):
	var result = []
	var cards : Array
	if allow_dupes:
		cards = card_objects.duplicate()
	else:
		cards = get_cards_without_duplicates()
	
	if cards.empty():
		return result
	
	var cards_full = cards.duplicate()
	cards.shuffle()
	
	for _i in range(n):
		if cards.empty():
			cards = cards_full.duplicate()
			cards.shuffle()
		result.append(cards.pop_front())
	
	return result


func import_deck(deck_name, deck_list):
	var file = File.new()
	
	save_path = "user://saves/%s.tbz" % deck_name
	if file.file_exists(save_path):
		var index = 1
		var modified_path = "user://saves/%s-%s.tbz" % [deck_name, index]
		
		while file.file_exists(modified_path):
			index += 1
			modified_path = "user://saves/%s-%s.tbz" % [deck_name, index]
		
		save_path = modified_path
	
	var err = file.open(save_path, File.WRITE)
	if err != OK:
		push_error("An error occurred while creating the list file.")
	
	var lines = deck_list.split("\n")
	for i in range(len(lines)):
		# var count = line.substr(0, 1)
		var card_name = lines[i].substr(2)
		
		if card_name.empty():
			continue
		
		if i < len(lines) - 1:
			file.store_string(str(card_name, "\n"))
		else:
			file.store_string(card_name)
	
	file.close()

func new_deck(new_name):	
	var file = File.new()
	
	save_path = "user://saves/%s.tbz" % new_name
	if file.file_exists(save_path):
		var index = 1
		var modified_path = "user://saves/%s-%s.tbz" % [new_name, index]
		
		while file.file_exists(modified_path):
			index += 1
			modified_path = "user://saves/%s-%s.tbz" % [new_name, index]
		
		save_path = modified_path
	
	var err = file.open(save_path, File.WRITE)
	if err != OK:
		push_error("An error occurred while creating the list file.")
	
	file.close()


func load_deck(path):
	save_path = path
	
	var file = File.new()
	
	var err = file.open(path, File.READ)
	if err != OK:
		push_error("An error occurred while opening the list file.")
	
	collection.clear()
	
	var text = file.get_as_text()
	var tokens = text.split("\n")
	for t in tokens:
		if !t.empty():
			add_to_collection(t)
	
	file.close()


func save_deck():
	var file = File.new()
	
	var err = file.open(save_path, File.WRITE)
	if err != OK:
		push_error("An error occurred while opening the list file.")
	
	var text = ""
	
	for i in range(len(collection)):
		if i < len(collection) - 1:
			text += str(collection[i], "\n")
		else:
			text += collection[i]
	
	file.store_string(text)
	
	file.close()

func make_save_dir():
	var dir = Directory.new()
	if dir.open("user://") == OK:
		if !dir.dir_exists("saves"):
			dir.make_dir("saves")
	else:
		push_error("An error occured while trying to access the user file path")


func load_sets():
	var file = File.new()
	file.open("res://text/sets.txt", File.READ)
	var content = []
	while !file.eof_reached():
		content.append(file.get_line())
	file.close()
	return content


func load_set_codes():
	var file = File.new()
	file.open("res://text/set_codes.txt", File.READ)
	var content = []
	while !file.eof_reached():
		content.append(file.get_line())
	file.close()
	return content
