extends Node3D

var grapple_point = Vector3()
var grappling = false
var gpoint_distance = 0

@onready var grapplecast = $RayCast3D
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent()
@onready var grapple_timer = $GrappleTimer
@onready var line = $HookMesh/Line
@onready var grappleMesh = $HookMesh/MeshInstance3D
# TODO: End of the hook mesh!
# @onready var hook = $HookMesh/MeshInstance3D
@onready var lookpoint = $Lookpoint

func _ready() -> void:
	pass

#add time spent grappling to lerp, to counter for overchared negative gravity

func grapple():
	if Input.is_action_just_pressed("hook"):
		print('grapple time!')
		if grapplecast.is_colliding():
			var body = grapplecast.get_collider()
			if not body.is_in_group("player"):
				grapple_timer.start()
				find_point()
				if not grappling == true:
					grappling = true
	if grappling == true:
		# hook.visible = false
		line.visible = true
		player.gravity = -9.8
		grappleMesh.look_at(grapple_point, Vector3(0,1,0))
		grappleMesh.rotate_object_local(Vector3(0,1,0), 3.14)
		gpoint_distance = grapple_point.distance_to(player.transform.origin)
		if grapple_point.distance_to(player.transform.origin) > 1:
			player.transform.origin = lerp(player.transform.origin, grapple_point, 0.005)
		if player.position.y > grapple_point.y + 3:
			player.gravity = 9.8
	else:
		grappleMesh.look_at(Vector3(lookpoint.global_transform.origin.x, lookpoint.global_transform.origin.y, lookpoint.global_transform.origin.z), Vector3(0,1,0))
		player.gravity = 9.8
		line.visible = false
		# hook.visible = true
	if Input.is_action_just_pressed("jump"):
		if grappling:
			# player.gravity_vec = Vector3.UP * player.jump
			grappling = false

func find_point():
	grapple_point = grapplecast.get_collision_point()

func _on_grapple_timer_timeout():
	grappling = false
