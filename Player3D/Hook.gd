extends Node3D

@onready var player: CharacterBody3D = get_parent().get_parent().get_parent()
@onready var grapple_timer = $GrappleTimer

@onready var GRAPPLECAST: RayCast3D = $GrappleCast
@onready var HOOKBODY = $HookMesh
@onready var LINE = $HookMesh/Arm
@onready var CLAW = $HookMesh/Claw
@onready var HAND_MODEL = $HookMesh/Claw/Open
@onready var FIST_MODEL = $HookMesh/Claw/Fist

enum STATE {IDLE, SEEKING_LEDGE, PULLING_SELF, SEEKING_PLAYER, PULLING_ENEMY}
var curr: STATE = STATE.IDLE

var grapple_point = null
var gpoint_distance = 0
var claw_init_position
var line_point_distance

func _ready() -> void:
	claw_init_position = CLAW.position
	cancel()
	pass

func _process(_delta):
	match curr:
		STATE.IDLE:
			pass
		STATE.SEEKING_LEDGE:
			seeking_ledge()
		STATE.PULLING_SELF:
			pulling_self()
		STATE.SEEKING_PLAYER:
			seeking_player(_delta)
			pass
		STATE.PULLING_ENEMY:
			pass

# For Grapple
# If you've targeted a point that can be grappled, set that point, send seeker.
# If you have no collision, send it out, but reset it about 0.3 sec later
func launch_grapple():
	if idle() and grapple_point == null:
		if GRAPPLECAST.is_colliding() and not GRAPPLECAST.get_collider().is_in_group("player"):
			grapple_point = GRAPPLECAST.get_collision_point()
			curr = STATE.SEEKING_LEDGE
			prepare_hand()
	else:
		cancel()

func seeking_ledge():
	gpoint_distance = grapple_point.distance_to(CLAW.global_position)
	if gpoint_distance > 1.25:
		line_point_distance = player.transform.origin.distance_to(CLAW.global_position)
		LINE.set_scale(Vector3(1, 1, line_point_distance))
		# LINE.transform.origin = Vector3(0, 0, - line_point_distance / 2)
		# CLAW MOVE
		CLAW.global_position = lerp(CLAW.global_position, grapple_point, 0.03)
		HOOKBODY.look_at(CLAW.global_position)
	else:
		# CLAW SUCCESS
		HOOKBODY.look_at(grapple_point)
		CLAW.global_position = grapple_point
		FIST_MODEL.show()
		HAND_MODEL.hide()
		curr = STATE.PULLING_SELF
		grapple_timer.start()

func pulling_self():
	## TODO: add time spent grappling to lerp, to counter for overchared negative gravity
	if player.global_position.y > grapple_point.y + 0.5:
		player.gravity = 9.8
	else:
		player.gravity = -9.8
	if player.is_on_floor():
		player.velocity.y = 0.05

	gpoint_distance = grapple_point.distance_to(player.transform.origin)
	line_point_distance = grapple_point.distance_to(HOOKBODY.global_position)
	HOOKBODY.look_at(grapple_point)
	LINE.set_scale(Vector3(1, 1, line_point_distance))
	# LINE.transform.origin = Vector3(0, 0, - line_point_distance / 2)

	# ENDING CONDITION + Move the Player (self)
	if gpoint_distance > 2:
		player.transform.origin = lerp(player.transform.origin, grapple_point, 0.005)
	else:
		cancel()

	if Input.is_action_just_pressed("jump"):
		player.gravity = 9.8
		if player.velocity.y < player.JUMP_VELOCITY * 2: 
			player.velocity.y = player.velocity.y + player.JUMP_VELOCITY
		else: 
			player.velocity.y = player.JUMP_VELOCITY * 2
		cancel()

# For Pull
# Send out a shape along the raycast, if it encounters a body.is_in_group("player"):
func launch_hook():
	curr = STATE.SEEKING_PLAYER
	prepare_hook()
	CLAW.top_level = true
	$HookTimer.start()
	await $HookTimer.timeout
	cancel()
	pass
	

# moving out!
func seeking_player(delta):
	line_point_distance = player.transform.origin.distance_to(CLAW.global_position)
	LINE.set_scale(Vector3(1, 1, line_point_distance))
	# LINE.transform.origin = Vector3(0, 0, - line_point_distance / 2)
	
	CLAW.global_position += transform.basis * Vector3(GRAPPLECAST.target_position) * delta
	HOOKBODY.look_at(CLAW.global_position)
	#if ray.is_colliding():
		#return true

func cancel():
	curr = STATE.IDLE
	grapple_point = null
	reset_hand()

func prepare_hook():
	CLAW.top_level = true
	LINE.visible = true
	FIST_MODEL.hide()
	HAND_MODEL.show()
	await get_tree().create_timer(0.08).timeout
	HAND_MODEL.set_scale(Vector3(1.3,1.3,1.3))
	$GrappleTimer.stop()

func idle():
	return curr == STATE.IDLE
			
func prepare_hand():
	HOOKBODY.look_at(grapple_point)
	CLAW.look_at(grapple_point)	
	CLAW.top_level = true
	LINE.visible = true
	FIST_MODEL.hide()
	HAND_MODEL.show()
	# Small delay on scale to ease in. (TODO: Could be animation!)
	await get_tree().create_timer(0.08).timeout
	HAND_MODEL.set_scale(Vector3(1.3,1.3,1.3))
	$GrappleTimer.stop()
	
func reset_hand():
	HOOKBODY.look_at(GRAPPLECAST.target_position)
	CLAW.look_at(GRAPPLECAST.target_position)
	CLAW.top_level = false
	CLAW.position = claw_init_position
	LINE.visible = false
	LINE.set_scale(Vector3.ONE)
	HAND_MODEL.set_scale(Vector3.ONE)
	FIST_MODEL.hide()
	HAND_MODEL.hide()
	player.gravity = 9.8
	$GrappleTimer.stop()

# TODO: Call a recursive func to play the timer x times instead of this ... 
func _on_grapple_timer_timeout():
	LINE.visible = false
	await get_tree().create_timer(0.1).timeout
	LINE.visible = true
	await get_tree().create_timer(0.1).timeout
	LINE.visible = false
	await get_tree().create_timer(0.1).timeout
	LINE.visible = true
	await get_tree().create_timer(0.1).timeout
	cancel()
