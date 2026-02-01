extends CharacterBody2D

@export var speed: float = 400.0
@export var acceleration: float = 2500.0
@export var friction: float = 2200.0
@export var grace_duration: float = 3.0
@export var mask_cooldown: float = 5.0
@export var mask_speed_bonus: float = 50.0

var has_mask: bool = false
var grace_active: bool = false
var grace_timer: float = 0.0
var cooldown_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if grace_active:
		grace_timer -= delta
		if grace_timer <= 0:
			grace_active = false
			_set_grace_visual(false)
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if Input.is_action_just_pressed("ui_accept") and has_mask and not grace_active and cooldown_timer <= 0:
		activate_mask()
	
	# Get input direction
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var current_speed = speed + (mask_speed_bonus if grace_active else 0.0)
	
	# Apply acceleration or friction
	if input_direction.length() > 0:
		velocity = velocity.move_toward(input_direction * current_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Rotate character to face movement direction
	if velocity.length() > 0:
		rotation = velocity.angle() + PI / 2
	
	# Move character
	move_and_slide()
	
	# Animation handling
	if has_node("AnimatedSprite2D"):
		var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
		var is_moving = velocity.length() > 10
		
		if grace_active:
			if is_moving:
				anim_sprite.play("stealth")
			else:
				anim_sprite.play("stealth_idle")
		elif is_moving:
			anim_sprite.play("walk")
		else:
			anim_sprite.play("idle")


func collect_mask() -> void:
	has_mask = true


func activate_mask() -> void:
	grace_active = true
	grace_timer = grace_duration
	cooldown_timer = mask_cooldown


func _set_grace_visual(_active: bool) -> void:
	# Animation is now handled in _physics_process
	pass
