extends Control

onready var mana_value = get_node("Controls/Grid/ManaControls/ManaValue")
onready var color = get_node("Controls/Grid/Color")
onready var type = get_node("Controls/Grid/Type")
onready var rarity = get_node("Controls/Grid/Rarity")
onready var sets = get_node("Controls/SetContainer/SetList")
onready var legendary = get_node("Controls/Legendary")
onready var info = get_node("Controls/InfoLabel")

onready var setlist = DataHelper.get_sets()

var num_cards = 3
var cards = []
var card_sprites = []

var card_scene = preload("res://Card.tscn")

var colors = ["w", "u", "b", "r", "g", "c", "m"]
var types = ["land", "creature", "instant", "sorcery", "artifact", "enchantment", "planeswalker", "tribal"]
var rarities = ["common", "uncommon", "rare", "mythic", "special"]
var any_mv = true

var base_query = "-t:basic not:funny not:rebalanced (st:commander or st:core or st:expansion or st:masters or st:draft_innovation or st:starter or st:funny)"
var banned_sets = "-e:4bb -e:j21 -e:fbb -e:sum"

signal card_requests_completed(err)
signal card_downloads_completed(err)
signal texture_downloaded(texture)

func _ready():
	$Scryfall.connect("request_completed", self, "_on_request_completed")
	$CardDownload.connect("request_completed", self, "_on_download_completed")
	update_card_history()
	
	var info_text : String = "Format:"
	
	match DataHelper.get_mode():
		DataHelper.Mode.MODERN:
			legendary.hide()
			info_text = "%s %s" % [info_text, "Modern"]
		DataHelper.Mode.LEGACY:
			legendary.hide()
			info_text = "%s %s" % [info_text, "Legacy"]
		DataHelper.Mode.COMMANDER:
			legendary.show()
			info_text = "%s %s" % [info_text, "Duel Commander"]
		_:
			info_text = "%s %s" % [info_text, "???"]
			legendary.hide()
	
	if DataHelper.is_singleton():
		info_text = "%s %s" % [info_text, "Singleton"]
	
	info.set_text(info_text)


func _on_button_pressed():
	$Controls/GetCard.disabled = true
	$Spinner.visible = true
	$Controls/Fail.visible = false
	$Controls/Fail2.visible = false
	
	DataHelper.clear_card_objects()
	
	request_cards(build_query())
	var rq_err = yield(self, "card_requests_completed")
	if rq_err != OK:
		$Controls/GetCard.disabled = false
		return
	
	match DataHelper.get_mode():
		DataHelper.Mode.COMMANDER:
			cards = DataHelper.get_random_cards(num_cards, false)
		_:
			if DataHelper.is_singleton():
				cards = DataHelper.get_random_cards(num_cards, false)
			else:
				cards = DataHelper.get_random_cards(num_cards, true)
	
	if cards.empty():
		$Controls/Fail2.visible = true
		$Controls/GetCard.disabled = false
		$Spinner.visible = false
		return
	
	for i in range(num_cards):
		var card = card_scene.instance()
		card.id = i + 1
		card.name = str("Card", i + 1)
		card.connect("card_revealed", self, "_on_card_revealed")
		card_sprites.append(card)
	
	download_card_images()
	var dl_err = yield(self, "card_downloads_completed")
	if dl_err != OK:
		$Controls/GetCard.disabled = false
		return

	$Spinner.visible = false

	show_card_selection()


func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		var card_list = json.result["data"]
		
		for card in card_list:
			if card["name"] in DataHelper.custom_banlist:
				continue
			
			var card_obj = {}
			card_obj["name"] = card["name"]
			
			if "image_uris" in card:
				card_obj["front"] = card["image_uris"]["large"]
			else:
				var faces = card["card_faces"]
				card_obj["front"] = faces[0]["image_uris"]["large"]
				card_obj["back"] = faces[1]["image_uris"]["large"]
			
			DataHelper.add_card_object(card_obj)
		
		if json.result["has_more"]:
			var url = json.result["next_page"]
			
			yield(get_tree().create_timer(0.1), "timeout")
			
			var err = $Scryfall.request(url)
			if err != OK:
				push_error("An error occurred in the HTTP request")
		else:
			emit_signal("card_requests_completed", OK)
		
		$Controls/Fail.visible = false
	else:
		emit_signal("card_requests_completed", FAILED)
		
		$Controls/Fail.visible = true
		$Spinner.visible = false


func _on_download_completed(_result, _response_code, _headers, body):
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		push_error("An error occurred while trying to get the card image.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	emit_signal("texture_downloaded", texture)


func build_query():
	var banlist : String
	match DataHelper.get_mode():
		DataHelper.Mode.MODERN:
			banlist = "f:modern -banned:modern"
		DataHelper.Mode.LEGACY:
			banlist = "-banned:legacy"
		DataHelper.Mode.COMMANDER:
			banlist = "-banned:duel"
	
	var query = "%s %s %s" % [base_query, banned_sets, banlist]
	
	if DataHelper.get_mode() == DataHelper.Mode.COMMANDER:
		if legendary.pressed:
			var leg = "t:legend"
			query = "%s %s" % [query, leg]
	
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
		var e = "e:%s" % setlist[sets.get_selected_items()[0] - 1][1]
		query = "%s %s" % [query, e]
	
	return query


func request_cards(query):
	var url = "https://api.scryfall.com/cards/search?q=%s" % query
	
	var err = $Scryfall.request(url)		
	if err != OK:
		push_error("An error occurred in the HTTP request")


func download_card_images():
	for i in range(len(cards)):
		download_image(cards[i]["front"])
		card_sprites[i].front_texture = yield(self, "texture_downloaded").duplicate()
		
		if "back" in cards[i]:
			download_image(cards[i]["back"])
			card_sprites[i].has_back = true
			card_sprites[i].back_texture = yield(self, "texture_downloaded").duplicate()
	
	emit_signal("card_downloads_completed", OK)


func show_card_selection():
	card_sprites[0].position = $CardSelection/CardPos1.position
	card_sprites[1].position = $CardSelection/CardPos2.position
	card_sprites[2].position = $CardSelection/CardPos3.position
	
	for i in range(len(card_sprites)):
		add_child(card_sprites[i])
	
	$Controls.visible = false
	$CardSelection.visible = true


func show_controls():
	for sprite in card_sprites:
		sprite.free()
	
	card_sprites.clear()
	
	$Controls/GetCard.disabled = false
	
	$CardSelection.visible = false
	$CardSelection/Take1.visible = false
	$CardSelection/Take2.visible = false
	$CardSelection/Take3.visible = false
	$Controls.visible = true


func download_image(url):
	var err = $CardDownload.request(url)
	if err != OK:
		push_error("An error occurred in the HTTP request")


func update_card_history():
	$Controls/CardHistory.text = DataHelper.get_collection_as_text()

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
	$Controls/HistoryLabel.visible = button_pressed


func _on_BanlistToggle_toggled(button_pressed):
	$Controls/Banlist.visible = button_pressed
	$Controls/BanlistLabel.visible = button_pressed


func _on_Take1_pressed():
	DataHelper.add_to_collection(cards[0])
	update_card_history()
	show_controls()


func _on_Take2_pressed():
	DataHelper.add_to_collection(cards[1])
	update_card_history()
	show_controls()


func _on_Take3_pressed():
	DataHelper.add_to_collection(cards[2])
	update_card_history()
	show_controls()


func _on_ClearHistory_pressed():
	$Controls/CardHistory.set_text("")


func _on_MainMenu_pressed():
	DataHelper.save_deck()
	get_node("/root/ModeSelect").show()
	hide()
	get_node("/root/MultiPull").queue_free()

