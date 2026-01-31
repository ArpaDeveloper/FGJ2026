extends Button

@onready var sprite = $Sprite2D

func _ready():
	sprite.visible = false

func _on_mouse_entered():
	sprite.visible = true

func _on_mouse_exited():
	sprite.visible = false
