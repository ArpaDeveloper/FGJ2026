extends CharacterBody2D

@export var speed: float = 200.0
@export var detection_range: float = 300.0
@export var detection_angle: float = 60.0 # 60° cone (30° on each side)

var player: Node2D = null
var player_detected: bool = false


func _ready() -> void:
	player = get_tree().root.get_node("Main/CharacterBody2D") # Adjust path to your player


func _physics_process(_delta: float) -> void:
	# Check if player is in detection cone
	player_detected = is_player_in_cone()
	
	if player_detected:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()


func is_player_in_cone() -> bool:
	if not player:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	# Check if within range
	if distance > detection_range:
		return false
	
	# Check if within cone angle
	var angle_to_player = to_player.angle()
	var forward_angle = rotation - PI / 2 # Adjust if sprite faces different direction
	var angle_diff = angle_difference(angle_to_player, forward_angle)
	
	return abs(angle_diff) < deg_to_rad(detection_angle / 2)


func angle_difference(angle1: float, angle2: float) -> float:
	var diff = angle1 - angle2
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff
