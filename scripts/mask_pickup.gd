extends Area2D

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Give player the mask ability
		if body.has_method("collect_mask"):
			body.collect_mask()
		
		collected.emit()
		queue_free()
