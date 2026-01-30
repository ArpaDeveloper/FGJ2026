extends Control

#Reference to the menu, options
@onready var menu = $Menu1
@onready var options = $Menu2

#volume slider
func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

#mute toggle
func _on_mute_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)

#resolutions
func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))


#This is backbutton
func _on_back_pressed() -> void:
	menu.visible = true
	options.visible = false
