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
	
	# Draw current active cone with occlusion
	var current_angle = chase_angle if is_chasing else detection_angle
	var half_angle = deg_to_rad(current_angle / 2)
	var start_angle = - PI / 2 - half_angle
	var end_angle = - PI / 2 + half_angle
	
	# Colors: purple (idle) -> red (fully aimed)
	var idle_color = Color(0.5, 0, 1, 0.15)
	var aimed_color = Color(1, 0, 0, 0.35)
	var idle_outline = Color(0.5, 0, 1, 0.4)
	var aimed_outline = Color(1, 0, 0, 0.8)
	
	var cone_color = idle_color.lerp(aimed_color, aim_progress)
	var outline_color = idle_outline.lerp(aimed_outline, aim_progress)
	
	# Raycast to find visible cone shape
	var space_state = get_world_2d().direct_space_state
	var points = PackedVector2Array([Vector2.ZERO])
	var num_points = 32
	
	for i in range(num_points + 1):
		var angle = start_angle + (end_angle - start_angle) * i / num_points
		var direction = Vector2(cos(angle), sin(angle))
		var world_direction = direction.rotated(rotation)
		var end_point = global_position + world_direction * detection_range
		
		var query = PhysicsRayQueryParameters2D.create(global_position, end_point)
		# Exclude self and player from cone visualization
		var exclude_list: Array[RID] = [get_rid()]
		if player and player is CollisionObject2D:
			exclude_list.append(player.get_rid())
		query.exclude = exclude_list
		query.collide_with_areas = false
		
		var result = space_state.intersect_ray(query)
		
		var local_point: Vector2
		if result.is_empty():
			local_point = direction * detection_range
		else:
			var hit_distance = (result.position - global_position).length()
			local_point = direction * hit_distance
		
		points.append(local_point)
	
	draw_colored_polygon(points, cone_color)
	
	# Draw cone outline
	if points.size() > 1:
		for i in range(1, points.size()):
			draw_line(points[i - 1] if i > 1 else Vector2.ZERO, points[i], outline_color, 1.0)


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
	
	if abs(angle_diff) >= deg_to_rad(cone_angle / 2):
		return false
	
	# Check line of sight with raycast
	return has_line_of_sight()


func has_line_of_sight() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [ self ]
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	
	# If no hit, or hit the player, we have line of sight
	if result.is_empty():
		return true
	return result.collider.is_in_group("player")


func angle_difference(angle1: float, angle2: float) -> float:
	var diff = angle1 - angle2
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff
