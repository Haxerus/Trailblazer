extends Node

enum Mode {
	MODERN,
	LEGACY, 
	COMMANDER
}

var mode = Mode.MODERN

var save_path : String

var sets : Array
var modern_sets : Array

var card_objects = []
var collection = []

func _ready():
	randomize()
	make_save_dir()
	sets = load_sets("res://text/setlist.txt")
	modern_sets = load_sets("res://text/setlist_modern.txt")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_deck()


func set_mode(mode_string):
	match mode_string:
		"Modern":
			mode = Mode.MODERN
		"Legacy":
			mode = Mode.LEGACY
		"Duel Commander":
			mode = Mode.COMMANDER


func get_mode():
	return mode

func get_sets():
	if mode == Mode.MODERN:
		return modern_sets
	
	return sets

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


func import_deck(deck_name, deck_list, format):
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
	
	file.store_string(str(format, "\n"))
	
	var lines = deck_list.split("\n")
	for i in range(len(lines)):
		# var count = lines[i].substr(0, 1)
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
	
	var format = tokens[0]
	match format:
		"Modern":
			tokens.remove(0)
			set_mode(format)
		"Legacy":
			tokens.remove(0)
			set_mode(format)
		"Duel Commander":
			tokens.remove(0)
			set_mode(format)
		_:
			set_mode("Legacy")
	
	for t in tokens:
		if !t.empty():
			add_to_collection(t)
	
	file.close()


func save_deck():
	var file = File.new()
	
	var err = file.open(save_path, File.WRITE)
	if err != OK:
		push_error("An error occurred while opening the list file.")
	
	var format : String
	match mode:
		Mode.MODERN:
			format = "Modern"
		Mode.LEGACY:
			format = "Legacy"
		Mode.COMMANDER:
			format = "Duel Commander"
	
	file.store_string(str(format, "\n"))
	
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


func load_sets(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = []
	while !file.eof_reached():
		content.append(file.get_line().split("\t"))
	file.close()
	return content
