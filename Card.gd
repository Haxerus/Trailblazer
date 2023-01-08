extends Sprite

export var default_texture : Texture
export var front_texture : Texture
export var back_texture : Texture

export var id : int

var revealed = false
var has_back = false
var showing_front = true

signal card_revealed(id)

func _ready():
# warning-ignore:return_value_discarded
	$Anim.connect("animation_finished", self, "_on_animation_finished")
	scale = Vector2(0.4, 0.4)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			if !$Anim.is_playing():
				if !revealed:
					$Anim.play("reveal")
				elif revealed and has_back:
					$Anim.play("flip")

func reset_texture():
	texture = default_texture

func use_front_texture():
	texture = front_texture

func toggle_texture():
	if !has_back:
		return
	
	if showing_front:
		texture = back_texture
		showing_front = false
	else:
		texture = front_texture
		showing_front = true

func _on_animation_finished(anim_name):
	if anim_name == "reveal":
		revealed = true
		emit_signal("card_revealed", id)
