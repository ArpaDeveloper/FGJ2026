extends CharacterBody2D

@export var speed: float = 400.0
@export var acceleration: float = 2500.0
@export var friction: float = 2200.0
@export var grace_duration: float = 3.0
@export var mask_cooldown: float = 5.0

var has_mask: bool = false
var grace_active: bool = false
var grace_timer: float = 0.0
var cooldown_timer: float = 0.0
var original_texture: Texture2D = null
var goose_texture: Texture2D = preload("res://assets/Enemies/goose.png")


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


func collect_mask() -> void:
	has_mask = true


func activate_mask() -> void:
	grace_active = true
	grace_timer = grace_duration
	cooldown_timer = mask_cooldown
	_set_grace_visual(true)


func _set_grace_visual(active: bool) -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	
	if active:
		# Store original texture and switch to goose
		if original_texture == null:
			original_texture = sprite.texture
		sprite.texture = goose_texture
	else:
		# Restore original texture
		if original_texture:
			sprite.texture = original_texture
