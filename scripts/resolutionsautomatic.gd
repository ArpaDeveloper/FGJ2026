extends OptionButton

var resolutions = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(960, 540)
]


func _ready():
	clear()
	for res in resolutions:
		add_item("%d x %d" % [res.x, res.y])
	
	# Select current resolution
	var current_size = DisplayServer.window_get_size()
	for i in range(resolutions.size()):
		if resolutions[i] == current_size:
			select(i)
			break
	
	item_selected.connect(_on_resolution_selected)


func _on_resolution_selected(index: int) -> void:
	var new_res = resolutions[index]
	DisplayServer.window_set_size(new_res)
	# Center the window
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - new_res) / 2
	DisplayServer.window_set_position(window_pos)
