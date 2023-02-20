extends Control

onready var format1 = get_node("NewNameDialog/VBox/Format")
onready var format2 = get_node("ImportDialog/VBox/Format")

onready var main_scene = preload("res://MultiPull.tscn")

var formats = ["Modern", "Legacy", "Duel Commander"]

signal new_name_entered
signal deck_loaded

func _ready():
	for f in formats:
		format1.add_item(f)
		format2.add_item(f)


func _on_New_pressed():
	$NewNameDialog.popup_centered()
	yield(self, "new_name_entered")
	DataHelper.set_mode(formats[format1.selected])
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()


func _on_Load_pressed():
	$LoadDialog.popup_centered()
	yield(self, "deck_loaded")
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()


func _on_NewNameDialog_confirmed():
	if $NewNameDialog/VBox/Name.text.empty():
		$NewNameDialog/VBox/Err.show()
		return
	
	DataHelper.new_deck($NewNameDialog/VBox/Name.text)
	
	$NewNameDialog/VBox/Err.hide()
	$NewNameDialog.hide()
	
	emit_signal("new_name_entered")


func _on_NewNameDialog_about_to_show():
	$NewNameDialog/VBox/Name.clear()


func _on_LoadDialog_file_selected(path):
	DataHelper.load_deck(path)
	$LoadDialog.hide()
	emit_signal("deck_loaded")


func _on_LoadDialog_about_to_show():
	$LoadDialog.set_current_dir("user://saves")


func _on_ImportDialog_confirmed():
	if $ImportDialog/VBox/Name.text.empty():
		$ImportDialog/VBox/Err.show()
		return
	
	if $ImportDialog/VBox/List.text.empty():
		$ImportDialog/VBox/Err2.show()
		return
	
	var deck_name = $ImportDialog/VBox/Name.text
	var deck_list = $ImportDialog/VBox/List.text
	
	
	
	DataHelper.import_deck(deck_name, deck_list, formats[format2.selected])
	
	$ImportDialog/VBox/Err.hide()
	$ImportDialog/VBox/Err2.hide()
	$ImportDialog.hide()


func _on_ImportDialog_about_to_show():
	$ImportDialog/VBox/Name.clear()


func _on_Import_pressed():
	$ImportDialog.popup_centered()
