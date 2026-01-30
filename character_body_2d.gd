extends CharacterBody2D

@export var speed: float = 400.0


func _physics_process(_delta: float) -> void:
	# Get input and set velocity
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	# Move character
	move_and_slide()
	
	# Animation handling (only if AnimatedSprite2D exists)
	if has_node("AnimatedSprite2D"):
		var animated_sprite_2d: AnimatedSprite2D = get_node("AnimatedSprite2D")
		var is_moving := velocity.length() > 0
		
		# Flip sprite based on horizontal movement
		if velocity.x != 0:
			animated_sprite_2d.flip_h = velocity.x < 0
		
		# Play appropriate animation
		animated_sprite_2d.play("run" if is_moving else "idle")
