extends Control

onready var main_scene = preload("res://MultiPull.tscn")

signal new_name_entered
signal deck_loaded

func _on_StdNew_pressed():
	$NewNameDialog.popup_centered()
	yield(self, "new_name_entered")
	DataHelper.set_mode(DataHelper.Mode.STANDARD)
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()


func _on_StdLoad_pressed():
	$LoadDialog.popup_centered()
	yield(self, "deck_loaded")
	DataHelper.set_mode(DataHelper.Mode.STANDARD)
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()

func _on_ComNew_pressed():
	$NewNameDialog.popup_centered()
	yield(self, "new_name_entered")
	DataHelper.set_mode(DataHelper.Mode.COMMANDER)
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()

func _on_ComLoad_pressed():
	$LoadDialog.popup_centered()
	yield(self, "deck_loaded")
	DataHelper.set_mode(DataHelper.Mode.COMMANDER)
	# get_tree().change_scene_to(main_scene)
	get_tree().get_root().add_child(main_scene.instance())
	self.hide()


func _on_NewNameDialog_confirmed():
	if $NewNameDialog/NameVBox/Name.text.empty():
		$NewNameDialog/NameVBox/Err.show()
		return
	
	DataHelper.new_deck($NewNameDialog/NameVBox/Name.text)
	
	$NewNameDialog/NameVBox/Err.hide()
	$NewNameDialog.hide()
	
	emit_signal("new_name_entered")


func _on_NewNameDialog_about_to_show():
	$NewNameDialog/NameVBox/Name.clear()


func _on_LoadDialog_file_selected(path):
	DataHelper.load_deck(path)
	$LoadDialog.hide()
	emit_signal("deck_loaded")


func _on_LoadDialog_about_to_show():
	$LoadDialog.set_current_dir("user://saves")
