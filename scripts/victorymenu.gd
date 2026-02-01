extends Control

@onready var victory_menu := self

func _ready() -> void:
	victory_menu.visible = true

func _on_next_level_button_pressed() -> void:
	get_tree().paused = false
	var current_level = GameState.current_level_path
	var filename = current_level.get_file().get_basename().to_lower()

	# Extract the number from the filename (handle "level1", "level 5", etc.)
	var level_number = 0
	for c in filename:
		if c.is_valid_int():
			level_number = level_number * 10 + int(c)

	# After level 5, go to end credits
	if level_number >= 5:
		get_tree().change_scene_to_file("res://scenes/endcredits.tscn")
		return

	# Build the next level path
	var next_level_number = level_number + 1
	var next_scene_path = "res://scenes/Levels/level%d.tscn" % next_level_number

	# Check if the next level exists before changing
	if FileAccess.file_exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		get_tree().change_scene_to_file("res://scenes/endcredits.tscn")

func _on_menu_victory_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
