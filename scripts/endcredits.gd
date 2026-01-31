extends Control

func _on_menu_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
