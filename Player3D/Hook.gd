extends Node3D

var grapple_point = Vector3()
var gpoint_distance = 0

@onready var grapplecast = $RayCast3D
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent()
@onready var grapple_timer = $GrappleTimer
@onready var line = $HookMesh/Line
@onready var cylinder = $HookMesh/Cylinder
@onready var grappleMesh = $HookMesh
@onready var hand = $"HookMesh/Claw/Skeletal Hand"

@onready var claw = $HookMesh/Claw

# TODO: Termination point of the hook!
# @onready var hook = $HookMesh/MeshInstance3D

@onready var lookpoint = $Lookpoint

var claw_init_position
var line_point_distance

func _ready() -> void:
	claw_init_position = claw.position
	pass

# send out our "Claw" and when it makes contact, flip on grapple.
var grappling = false
var seeking: bool = false
var seeking_complete: bool = false

func seek():
	if Input.is_action_just_pressed("hook"):
		if grapplecast.is_colliding() and seeking == false:	
			var body = grapplecast.get_collider()
			find_point()
			if seeking == false:
				hand.set_scale(Vector3(1.25, 1.25, 1.25))
				claw.look_at(grapple_point)
				seeking = true
		else:
			cancel()

	if seeking == true and seeking_complete == false:

		claw.top_level = true
		line.visible = true
		gpoint_distance = grapple_point.distance_to(claw.global_position)
		if gpoint_distance > 1.25:		
			# this moves us
			# LINE MOVE
			grappleMesh.look_at(grapple_point)
			line_point_distance = grappleMesh.global_position.distance_to(claw.global_position)
			line.set_scale(Vector3(1, 1, line_point_distance))
			line.transform.origin = Vector3(0, 0, - line_point_distance / 2)
			# CLAW MOVE
			claw.global_position = lerp(claw.global_position, grapple_point, 0.04)
		else:
			claw.global_position = grapple_point
			seeking_complete = true
			grapple_timer.start()
			
# add time spent grappling to lerp, to counter for overchared negative gravity
func grapple():
	if Input.is_action_just_pressed("hook"):
		if grapplecast.is_colliding():
			var body = grapplecast.get_collider()
			if not body.is_in_group("player"):
				find_point()
				if not grappling == true:
					grappling = true
	if grappling == true and seeking_complete == true:
		if player.is_on_floor():
			player.velocity.y = 0.1
		# hook.visible = false
		line.visible = true
		# TODO: Edit a bit to prevent floating
		player.gravity = -7.8
		gpoint_distance = grapple_point.distance_to(player.transform.origin)
		line_point_distance = grapple_point.distance_to(grappleMesh.global_position)
		grappleMesh.look_at(grapple_point)
		# cylinder.look_at(grapple_point)
		# line.look_at(grapple_point)
		line.set_scale(Vector3(1, 1, line_point_distance))
		# line.translate(Vector3(0, 0, gpoint_distance / 2))
		# line.transform.basis. = Vector3(0, 0, gpoint_distance) 
		line.transform.origin = Vector3(0, 0, - line_point_distance / 2)
		# ENDING CONDITION
		if gpoint_distance > 2.5:
			# this moves us
			player.transform.origin = lerp(player.transform.origin, grapple_point, 0.005)
			claw.global_position = grapple_point
		else:
			grappling = false
			cancel()
		if player.global_position.y > grapple_point.y + 1.75:
			player.gravity = 9.8
	else:
		player.gravity = 9.8
	if Input.is_action_just_pressed("jump"):
		if grappling:
			player.gravity = 9.8
			if player.velocity.y < player.JUMP_VELOCITY * 2: 
				player.velocity.y = player.velocity.y + player.JUMP_VELOCITY
			else: 
				player.velocity.y = player.JUMP_VELOCITY * 2
			cancel()

func cancel():	
	grappling = false
	seeking = false
	seeking_complete = false
	claw.top_level = false
	claw.global_position = player.transform.origin
	claw.position = claw_init_position
	hand.set_scale(Vector3(0.3, 0.3, 0.3))	
	line.visible = false

func find_point():
	grapple_point = grapplecast.get_collision_point()

func pull():
	pass

func _on_grapple_timer_timeout():
	cancel()
