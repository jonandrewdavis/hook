extends Node3D

var grapple_point = Vector3()
var grappling = false
var gpoint_distance = 0

@onready var grapplecast = $RayCast3D
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent()
@onready var grapple_timer = $GrappleTimer
@onready var line = $HookMesh/Line
@onready var cylinder = $HookMesh/Cylinder
@onready var grappleMesh = $HookMesh

# TODO: Termination point of the hook!
# @onready var hook = $HookMesh/MeshInstance3D

@onready var lookpoint = $Lookpoint

func _ready() -> void:
	pass

# add time spent grappling to lerp, to counter for overchared negative gravity
func grapple():
	if Input.is_action_just_pressed("hook"):
		if grapplecast.is_colliding():
			var body = grapplecast.get_collider()
			if not body.is_in_group("player"):
				grapple_timer.start()
				find_point()
				if not grappling == true:
					grappling = true
	if grappling == true:
		if player.is_on_floor():
			player.velocity.y = 0.1
		# hook.visible = false
		line.visible = true
		player.gravity = -9.8
		gpoint_distance = grapple_point.distance_to(player.transform.origin)
		grappleMesh.look_at(grapple_point)
		# cylinder.look_at(grapple_point)
		line.set_scale(Vector3(1, 1, gpoint_distance))
		# line.translate(Vector3(0, 0, gpoint_distance / 2))
		# line.transform.basis. = Vector3(0, 0, gpoint_distance) 
		line.transform.origin = Vector3(0, 0, - gpoint_distance / 2)
		if gpoint_distance > 2.5:
			# this moves us
			player.transform.origin = lerp(player.transform.origin, grapple_point, 0.005)
		else:
			grappling = false
		if player.global_position.y > grapple_point.y + 0.5:
			player.gravity = 9.8
	else:
		player.gravity = 9.8
		line.visible = false
		# hook.visible = true
	if Input.is_action_just_pressed("jump"):
		if grappling:
			player.gravity = 9.8
			player.jump()
			grappling = false

func find_point():
	grapple_point = grapplecast.get_collision_point()

func _on_grapple_timer_timeout():
	grappling = false

