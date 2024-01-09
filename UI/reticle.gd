extends CenterContainer

@export var DOT_RADIUS: float = 2.0
@export var DOT_COLOR: Color = Color.WHITE
@export var RETICLE_LINES : Array[Line2D]
@export var RETICLE_SPEED: float = 0.15
@export var RETICLE_DISTANCE: float = 3.0

@export var root: Node

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _process(_delta):
	if root.player != null:
		adjust_reticle_lines()

func _draw():
	draw_circle(Vector2(0,0), DOT_RADIUS,  DOT_COLOR)

func adjust_reticle_lines():
	var vel = root.player.get_real_velocity()
	var origin = Vector3.ZERO
	var pos = Vector2.ZERO
	var speed = origin.distance_to(vel)
	
	RETICLE_LINES[0].position = lerp(RETICLE_LINES[0].position, pos + Vector2(0, -speed * RETICLE_DISTANCE), RETICLE_SPEED)
	RETICLE_LINES[1].position = lerp(RETICLE_LINES[1].position, pos + Vector2(speed * RETICLE_DISTANCE, 0), RETICLE_SPEED)
	RETICLE_LINES[2].position = lerp(RETICLE_LINES[2].position, pos + Vector2(0, speed * RETICLE_DISTANCE), RETICLE_SPEED)
	RETICLE_LINES[3].position = lerp(RETICLE_LINES[3].position, pos + Vector2(-speed * RETICLE_DISTANCE, 0), RETICLE_SPEED)	
