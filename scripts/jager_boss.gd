extends CharacterBody2D

@export var speed: float = 100.0
@export var patrol_speed: float = 50.0
@export var detection_range: float = 300.0
@export var detection_angle: float = 60.0
@export var chase_angle: float = 120.0
@export var show_cone: bool = true
@export var rotation_smoothing: float = 3.0
@export var patrol_points: Array[Vector2] = []
@export var patrol_wait_time: float = 1.0
@export var return_delay: float = 2.0

@export var aim_time: float = 1.5

var player: Node2D = null
var player_in_cone: bool = false
var is_chasing: bool = false
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var is_waiting: bool = false
var is_returning: bool = false
var return_timer: float = 0.0
var start_position: Vector2
var detection_delay_timer: float = 0.0
var aim_progress: float = 0.0 # 0 = just spotted, 1 = fully aimed


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	start_position = global_position
	
	if patrol_points.is_empty():
		var path = get_node_or_null("Path2D")
		if path and path.curve:
			for i in range(path.curve.point_count):
				patrol_points.append(path.curve.get_point_position(i))


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	if is_chasing:
		player_in_cone = is_player_in_cone_no_los(chase_angle)
		if not player_in_cone:
			is_chasing = false
			is_returning = true
			return_timer = return_delay
			detection_delay_timer = 0.0
			aim_progress = 0.0
	else:
		player_in_cone = is_player_in_cone_with_los(detection_angle)
		if player_in_cone:
			var grace_time = 0.0
			if player.get("grace_active") and player.get("grace_timer") != null:
				grace_time = player.grace_timer
			
			if grace_time > 0:
				detection_delay_timer += delta
				if detection_delay_timer >= grace_time:
					is_chasing = true
					is_returning = false
					detection_delay_timer = 0.0
			else:
				is_chasing = true
				is_returning = false
		else:
			detection_delay_timer = 0.0
			aim_progress = max(aim_progress - delta / aim_time, 0.0)
	
	if is_chasing:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		var target_rotation = direction.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_smoothing * delta)
		
		global_position += velocity * delta
		
		# Aim at player while chasing
		aim_progress = min(aim_progress + delta / aim_time, 1.0)
		if aim_progress >= 1.0:
			trigger_fail()
			return
		
		# Also check direct collision
		if is_touching_player():
			trigger_fail()
			return
	elif is_returning:
		return_timer -= delta
		velocity = Vector2.ZERO
		aim_progress = max(aim_progress - delta / aim_time, 0.0)
		if return_timer <= 0:
			is_returning = false
			find_nearest_patrol_point()
	else:
		patrol(delta)
		aim_progress = max(aim_progress - delta / aim_time, 0.0)
	
	_update_animation()
	
	if show_cone:
		queue_redraw()


func _update_animation() -> void:
	if not has_node("AnimatedSprite2D"):
		return
	var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
	if velocity.length() > 10:
		anim_sprite.play("walk")
	else:
		anim_sprite.play("idle")


func find_nearest_patrol_point() -> void:
	if patrol_points.is_empty():
		return
	
	var min_distance = INF
	var nearest_index = 0
	
	for i in range(patrol_points.size()):
		var global_point = start_position + patrol_points[i]
		var distance = global_position.distance_to(global_point)
		if distance < min_distance:
			min_distance = distance
			nearest_index = i
	
	current_patrol_index = nearest_index


func patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return
	
	if is_waiting:
		patrol_wait_timer -= delta
		if patrol_wait_timer <= 0:
			is_waiting = false
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var target = patrol_points[current_patrol_index]
	var global_target = start_position + target
	var direction = (global_target - global_position)
	var distance = direction.length()
	
	if distance < 10:
		is_waiting = true
		patrol_wait_timer = patrol_wait_time
		velocity = Vector2.ZERO
	else:
		direction = direction.normalized()
		velocity = direction * patrol_speed
		
		var target_rotation = direction.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_smoothing * delta)
	
	move_and_slide()


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
	
	var current_angle = chase_angle if is_chasing else detection_angle
	var half_angle = deg_to_rad(current_angle / 2)
	var start_angle = - PI / 2 - half_angle
	var end_angle = - PI / 2 + half_angle
	
	var idle_color = Color(1, 1, 0, 0.15)
	var chase_color = Color(1, 0.5, 0, 0.25)
	var aimed_color = Color(1, 0, 0, 0.35)
	
	var cone_color: Color
	if is_chasing:
		cone_color = chase_color.lerp(aimed_color, aim_progress)
	else:
		cone_color = idle_color
	
	var idle_outline = Color(1, 1, 0, 0.4)
	var chase_outline = Color(1, 0.5, 0, 0.6)
	var aimed_outline = Color(1, 0, 0, 0.8)
	
	var outline_color: Color
	if is_chasing:
		outline_color = chase_outline.lerp(aimed_outline, aim_progress)
	else:
		outline_color = idle_outline
	
	var points = PackedVector2Array([Vector2.ZERO])
	var num_points = 32
	
	if is_chasing:
		for i in range(num_points + 1):
			var angle = start_angle + (end_angle - start_angle) * i / num_points
			var point = Vector2(cos(angle), sin(angle)) * detection_range
			points.append(point)
	else:
		var space_state = get_world_2d().direct_space_state
		
		for i in range(num_points + 1):
			var angle = start_angle + (end_angle - start_angle) * i / num_points
			var direction = Vector2(cos(angle), sin(angle))
			var world_direction = direction.rotated(rotation)
			var end_point = global_position + world_direction * detection_range
			
			var query = PhysicsRayQueryParameters2D.create(global_position, end_point)
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
	
	if points.size() > 1:
		for i in range(1, points.size()):
			draw_line(points[i - 1] if i > 1 else Vector2.ZERO, points[i], outline_color, 1.0)


func is_player_in_cone_no_los(cone_angle: float) -> bool:
	if not player:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance > detection_range:
		return false
	
	var angle_to_player = to_player.angle()
	var forward_angle = rotation - PI / 2
	var angle_diff = angle_difference(angle_to_player, forward_angle)
	
	return abs(angle_diff) < deg_to_rad(cone_angle / 2)


func is_player_in_cone_with_los(cone_angle: float) -> bool:
	if not is_player_in_cone_no_los(cone_angle):
		return false
	
	return has_line_of_sight()


func has_line_of_sight() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [ self ]
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	
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
