extends MultiplayerSpawner

@onready var ball_scene = preload("res://scenes/ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_function = spawn_ball
	if is_multiplayer_authority():
		spawn(1)

func spawn_ball(data):
	var b = ball_scene.instantiate()
	b.position.y = 202.0
	b.position.z = -3.2
	b.set_multiplayer_authority(data)
	return b
