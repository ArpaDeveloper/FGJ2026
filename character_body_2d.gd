extends CharacterBody2D

@export var speed: float = 400.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	# Get input and set velocity
	var input_direction := Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	
	# Move character
	move_and_slide()
	
	# Check if moving based on actual velocity
	var is_moving := velocity.length() > 0
	
	# Flip sprite based on horizontal movement
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0
	
	# Play appropriate animation
	animated_sprite_2d.play("run" if is_moving else "idle")
