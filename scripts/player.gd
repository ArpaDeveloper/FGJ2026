extends CharacterBody2D

@export var speed: float = 400.0
@export var acceleration: float = 2500.0
@export var friction: float = 2200.0

func _physics_process(delta: float) -> void:
	# Get input direction
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Apply acceleration or friction
	if input_direction.length() > 0:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Rotate character to face movement direction
	if velocity.length() > 0:
		rotation = velocity.angle() + PI / 2
	
	# Move character
	move_and_slide()
	
	# Animation handling (only if AnimatedSprite2D exists)
	if has_node("AnimatedSprite2D"):
		var animated_sprite_2d: AnimatedSprite2D = get_node("AnimatedSprite2D")
		var is_moving := velocity.length() > 0
		
		# Play appropriate animation
		animated_sprite_2d.play("run" if is_moving else "idle")
