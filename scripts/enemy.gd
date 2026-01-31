extends CharacterBody2D

@export var speed: float = 100.0
@export var detection_range: float = 300.0
@export var detection_angle: float = 60.0
@export var chase_angle: float = 120.0 # Wider angle while chasing
@export var show_cone: bool = true
@export var rotation_smoothing: float = 3.0 # higher = faster rotation

var player: Node2D = null
var player_in_cone: bool = false
var is_chasing: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	var current_angle = chase_angle if is_chasing else detection_angle
	player_in_cone = is_player_in_cone(current_angle)
	
	# Chase while player is in cone
	is_chasing = player_in_cone
	
	if is_chasing:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		# Smoothly rotate to face the player
		var target_rotation = direction.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_smoothing * delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Check if touching the player
	if is_chasing:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("player"):
				trigger_fail()
				return
	
	if show_cone:
		queue_redraw()


func trigger_fail() -> void:
	get_tree().change_scene_to_file("res://scenes/failmenu.tscn")


func _draw() -> void:
	if not show_cone:
		return
	
	# Draw current active cone
	var current_angle = chase_angle if is_chasing else detection_angle
	var half_angle = deg_to_rad(current_angle / 2)
	var start_angle = - PI / 2 - half_angle
	var end_angle = - PI / 2 + half_angle
	
	# Color changes based on detection
	var cone_color = Color(1, 0, 0, 0.2) if is_chasing else Color(1, 1, 0, 0.15)
	var outline_color = Color(1, 0, 0, 0.5) if is_chasing else Color(1, 1, 0, 0.4)
	
	# Draw filled cone
	var points = PackedVector2Array([Vector2.ZERO])
	var num_points = 32
	for i in range(num_points + 1):
		var angle = start_angle + (end_angle - start_angle) * i / num_points
		var point = Vector2(cos(angle), sin(angle)) * detection_range
		points.append(point)
	draw_colored_polygon(points, cone_color)
	
	# Draw cone outline
	draw_line(Vector2.ZERO, Vector2(cos(start_angle), sin(start_angle)) * detection_range, outline_color, 2.0)
	draw_line(Vector2.ZERO, Vector2(cos(end_angle), sin(end_angle)) * detection_range, outline_color, 2.0)
	draw_arc(Vector2.ZERO, detection_range, start_angle, end_angle, num_points, outline_color, 2.0)


func is_player_in_cone(cone_angle: float) -> bool:
	if not player:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	# Check if within range
	if distance > detection_range:
		return false
	
	# Check if within cone angle
	var angle_to_player = to_player.angle()
	var forward_angle = rotation - PI / 2
	var angle_diff = angle_difference(angle_to_player, forward_angle)
	
	return abs(angle_diff) < deg_to_rad(cone_angle / 2)


func angle_difference(angle1: float, angle2: float) -> float:
	var diff = angle1 - angle2
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff
