extends Control

onready var mana_value = get_node("Controls/Grid/ManaControls/ManaValue")
onready var color = get_node("Controls/Grid/Color")
onready var type = get_node("Controls/Grid/Type")
onready var rarity = get_node("Controls/Grid/Rarity")
onready var sets = get_node("Controls/SetContainer/SetList")

var card_scene = preload("res://Card.tscn")
var cards = []
var card_textures = []

var colors = ["w", "u", "b", "r", "g", "c", "m"]
var types = ["land", "creature", "instant", "sorcery", "artifact", "enchantment", "planeswalker", "tribal"]
var rarities = ["common", "uncommon", "rare", "mythic", "special"]
var set_codes = []
var any_mv = true

var base_query = "-banned:legacy -t:basic not:funny not:rebalanced (st:commander or st:core or st:expansion or st:masters or st:draft_innovation or st:starter or st:funny)"
var banned_sets = "-e:one -e:4bb -e:j21 -e:fbb -e:sum"

var json_buffer = []
var texture_buffer = []

signal card_requests_completed(err)
signal card_downloads_completed(err)

func _ready():
	load_history()
	load_set_codes()
# warning-ignore:return_value_discarded
	$Scryfall.connect("request_completed", self, "_on_request_completed")
# warning-ignore:return_value_discarded
	$CardDownload.connect("request_completed", self, "_on_download_completed")

func _on_button_pressed():
	$Controls/GetCard.disabled = true
	$Spinner.visible = true
	
	var query = "%s %s" % [base_query, banned_sets]
	
	if !any_mv:
		var mv = "mv:%s" % mana_value.get_line_edit().text
		query = "%s %s" % [query, mv]
	
	if color.selected != 0:
		var c = "c:%s" % colors[color.selected - 1]
		query = "%s %s" % [query, c]
	
	if type.selected != 0:
		var t = "t:%s" % types[type.selected - 1]
		query = "%s %s" % [query, t]
	
	if rarity.selected != 0:
		var r = "r:%s" % rarities[rarity.selected - 1]
		query = "%s %s" % [query, r]
	
	if !sets.get_selected_items().empty() and sets.get_selected_items()[0] != 0:
		var e = "e:%s" % set_codes[sets.get_selected_items()[0] - 1]
		query = "%s %s" % [query, e]
	
	request_cards(query)
	var rq_err = yield(self, "card_requests_completed")
	if rq_err != OK:
		$Controls/GetCard.disabled = false
		return
	
	download_cards()
	var dl_err = yield(self, "card_downloads_completed")
	if dl_err != OK:
		$Controls/GetCard.disabled = false
		return
	
	$Spinner.visible = false
	
	show_card_selection()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_history()
		get_tree().quit()

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		$Controls/Fail.visible = false
		var json = JSON.parse(body.get_string_from_utf8())
		json_buffer.append(json)
	else:
		$Controls/Fail.visible = true
		$Spinner.visible = false

func _on_download_completed(_result, _response_code, _headers, body):
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		print("An error occurred while trying to get the card image.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	texture_buffer.append(texture)

func load_set_codes():
	var file = File.new()
	file.open("res://text/set_codes.txt", File.READ)
	while !file.eof_reached():
		set_codes.append(file.get_line())
	file.close()

func request_cards(query):
	var url = "https://api.scryfall.com/cards/random?q=%s" % query
	
	json_buffer.clear()
	
	var status = OK
	var result = []
	
	for _i in range(3): 
		var err = $Scryfall.request(url)		
		if err != OK:
			push_error("An error occurred in the HTTP request")
		result = yield($Scryfall, "request_completed")
		
		if result[1] != 200:
			status = FAILED
		
		yield(get_tree().create_timer(0.1), "timeout")
	
	emit_signal("card_requests_completed", status)

func download_cards():
	texture_buffer.clear()
	card_textures.clear()
	
	for i in range(3):
		var data = json_buffer[i].result
		
		if "image_uris" in data:
			var image_uri = data["image_uris"]["large"]
			
			download_card_image(image_uri)
			yield($CardDownload, "request_completed")
			yield(get_tree().create_timer(0.1), "timeout")
			
			var t = []
			t.append(texture_buffer[-1])
			
			card_textures.append(t)
		elif "card_faces" in data:
			var front_uri = data["card_faces"][0]["image_uris"]["large"]
			var back_uri = data["card_faces"][1]["image_uris"]["large"]
			
			download_card_image(front_uri)
			yield($CardDownload, "request_completed")
			yield(get_tree().create_timer(0.1), "timeout")
			
			download_card_image(back_uri)
			yield($CardDownload, "request_completed")
			yield(get_tree().create_timer(0.1), "timeout")
			
			var t = []
			t.append(texture_buffer[-2])
			t.append(texture_buffer[-1])
			
			card_textures.append(t)
	
	emit_signal("card_downloads_completed", OK)

func show_card_selection():
	for i in range(3):
		var card = card_scene.instance()
		card.id = i + 1
		card.name = str("Card", i + 1)
		card.connect("card_revealed", self, "_on_card_revealed")
		cards.append(card)
	
	cards[0].position = $CardSelection/CardPos1.position
	cards[1].position = $CardSelection/CardPos2.position
	cards[2].position = $CardSelection/CardPos3.position
	
	for i in range(3):
		if len(card_textures[i]) == 2:
			cards[i].has_back = true
			cards[i].front_texture = card_textures[i][0]
			cards[i].back_texture = card_textures[i][1]
		else:
			cards[i].has_back = false
			cards[i].front_texture = card_textures[i][0]
	
	for i in range(3):
		add_child(cards[i])
	
	$Controls.visible = false
	$CardSelection.visible = true

func show_controls():
	for card in cards:
		card.free()
	
	cards.clear()
	
	$Controls/GetCard.disabled = false
	
	$CardSelection.visible = false
	$CardSelection/Take1.visible = false
	$CardSelection/Take2.visible = false
	$CardSelection/Take3.visible = false
	$Controls.visible = true

func download_card_image(url):
	var err = $CardDownload.request(url)
	if err != OK:
		push_error("An error occurred in the HTTP request")

func add_card_to_history(index):
	var card_name = json_buffer[index].result["name"]
	$Controls/CardHistory.text += str(card_name, "\n")

func save_history():
	var file = File.new()
	file.open("user://card_history.txt", File.WRITE)
	file.store_string($Controls/CardHistory.text)
	file.close()

func load_history():
	var file = File.new()
	if file.file_exists("user://card_history.txt"):
		file.open("user://card_history.txt", File.READ)
		var history = file.get_as_text()
		$Controls/CardHistory.text = history
		file.close()

func _on_CheckButton_toggled(button_pressed):
	any_mv = button_pressed

func _on_card_revealed(id):
	match id:
		1:
			$CardSelection/Take1.visible = true
		2:
			$CardSelection/Take2.visible = true
		3:
			$CardSelection/Take3.visible = true

func _on_CardHistoryToggle_toggled(button_pressed):
	$Controls/CardHistory.visible = button_pressed

func _on_Take1_pressed():
	add_card_to_history(0)
	show_controls()

func _on_Take2_pressed():
	add_card_to_history(1)
	show_controls()

func _on_Take3_pressed():
	add_card_to_history(2)
	show_controls()

func _on_ClearHistory_pressed():
	$Controls/CardHistory.set_text("")
