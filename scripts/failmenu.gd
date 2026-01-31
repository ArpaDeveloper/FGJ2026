extends Control

@onready var fail_menu := self

func _ready() -> void:
	fail_menu.visible = true

func _on_restart_level_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test.tscn")

func _on_menu_fail_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
