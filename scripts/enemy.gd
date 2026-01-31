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
	

	if is_chasing:
		player_in_cone = is_player_in_cone_no_los(chase_angle)
		is_chasing = player_in_cone
	else:
		# Need LOS to start chasing
		player_in_cone = is_player_in_cone_with_los(detection_angle)
		if player_in_cone:
			is_chasing = true
	
	if is_chasing:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		# Smoothly rotate to face the player
		var target_rotation = direction.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_smoothing * delta)
		
		# Move through obstacles while chasing
		global_position += velocity * delta
		
		# Check collision with player
		if is_touching_player():
			trigger_fail()
			return
	else:
		velocity = Vector2.ZERO
		move_and_slide()
	
	if show_cone:
		queue_redraw()


func is_touching_player() -> bool:
	if not player or not player is CollisionObject2D:
		return false
	
	var space_state = get_world_2d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters2D.new()
	shape_query.shape = $CollisionShape2D.shape
	shape_query.transform = global_transform
	shape_query.exclude = [get_rid()]
	
	var results = space_state.intersect_shape(shape_query)
	for result in results:
		if result.collider and result.collider.is_in_group("player"):
			return true
	return false


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
	
	var points = PackedVector2Array([Vector2.ZERO])
	var num_points = 32
	

	if is_chasing:
		for i in range(num_points + 1):
			var angle = start_angle + (end_angle - start_angle) * i / num_points
			var point = Vector2(cos(angle), sin(angle)) * detection_range
			points.append(point)
	else:
		# Raycast to find visible cone shape
		var space_state = get_world_2d().direct_space_state
		
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


func is_player_in_cone_no_los(cone_angle: float) -> bool:
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


func is_player_in_cone_with_los(cone_angle: float) -> bool:
	if not is_player_in_cone_no_los(cone_angle):
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
