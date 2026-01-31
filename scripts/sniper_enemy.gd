extends CharacterBody2D

@export var speed: float = 60.0
@export var detection_range: float = 600.0
@export var detection_angle: float = 20.0
@export var chase_angle: float = 40.0
@export var show_cone: bool = true
@export var aim_time: float = 2.0

var player: Node2D = null
var player_in_cone: bool = false
var is_chasing: bool = false
var aim_progress: float = 0.0 # 0 = just spotted, 1 = fully aimed


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	var current_angle = chase_angle if is_chasing else detection_angle
	player_in_cone = is_player_in_cone(current_angle)
	
	is_chasing = player_in_cone
	
	if is_chasing:
		aim_progress = min(aim_progress + delta / aim_time, 1.0)
		# Sniper shoots when fully aimed
		if aim_progress >= 1.0:
			trigger_fail()
			return
	else:
		aim_progress = max(aim_progress - delta / aim_time, 0.0)
	
	velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Check if touching the player
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
	
	# Colors: purple (idle) -> magenta (spotted) -> red (fully aimed)
	var idle_color = Color(0.5, 0, 1, 0.15)
	var aimed_color = Color(1, 0, 0, 0.35)
	var idle_outline = Color(0.5, 0, 1, 0.4)
	var aimed_outline = Color(1, 0, 0, 0.8)
	
	var cone_color = idle_color.lerp(aimed_color, aim_progress)
	var outline_color = idle_outline.lerp(aimed_outline, aim_progress)
	
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
