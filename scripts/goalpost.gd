extends Area2D

signal goal_reached

@export var next_level: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		goal_reached.emit()
		
		if next_level.is_empty():
			get_tree().call_deferred("change_scene_to_file", "res://scenes/victorymenu.tscn")
		else:
			get_tree().call_deferred("change_scene_to_file", next_level)
