extends Control

@onready var pause_menu := self

func _ready() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func resume():
	pause_menu.visible = false
	get_tree().paused = false

func pause():
	pause_menu.visible = true
	get_tree().paused = true

func _input(event):
	if event.is_action_pressed("resume_pause"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
