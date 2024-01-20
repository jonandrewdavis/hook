class_name Player

extends CharacterBody3D

signal health_changed(new_value)
signal health_healed(new_value)
signal last_kill(by)

@export var TEAM = ''

@onready var HEALTH_DEFAULT = 100
@onready var max_health = HEALTH_DEFAULT
@export var health = 100
@onready var last_damage_source = null

@export var ACCELERATION_DEFAULT: float = 0.08
@export var SPEED_DEFAULT: float = 4.0
@export var SPEED_SPRINTING: float = 6
@export var SPEED_CROUCH: float = 1.5

@export var ACCELERATION: float = 0.08
@export var DECELERATION: float = 0.25

@export var JUMP_VELOCITY : float = 5.5
@export_range(5, 10) var CROUCH_SPEED: float = 7
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-89.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(89.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
#@export var CROUCH_SHAPECAST: Node3D
@export var TOGGLE_CROUCH: bool
@export var DEATH_CAM: Camera3D

@export var CAPTURE_SPEED = 21

@onready var NAMELABEL = $NameLabel
@onready var LOOKPOINT = $CameraControllerHolder/PlayerCamera/LOOKPOINT 
@onready var COLLISION: CollisionShape3D = $CollisionShape3D
@onready var MODEL: Node3D = $character_skeleton_mage
@onready var HOOK: Node3D = $CameraControllerHolder/PlayerCamera/Hook
@onready var WEAPONS: WeaponsManager = $CameraControllerHolder/PlayerCamera/Weapons_Manager

@onready var HOOK_STARTING_CHARGES = 2
@onready var HOOK_CHARGES = HOOK_STARTING_CHARGES
@onready var HOOK_RECHARGE_TIMER: Timer = $HookRecharge

@onready var FSM: Node = $PlayerStateMachine
@onready var WEAPON_CAST: RayCast3D = $CameraControllerHolder/PlayerCamera/WeaponCast
@onready var PICK_MARKER: Marker3D = $CameraControllerHolder/PlayerCamera/PickMarker
@onready var AUDIO: AnimationPlayer = $PlayerAudio

@onready var HEALTH_TIMER = $Health
@onready var HEALTH_RECOVER_TIMER = $Recover

@export var UI_SCENE: PackedScene

@export var is_damage_over_time = 0

var UI = null
var id = null
var my_team_ids = []

var _speed: float
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _is_crouching = false

var air_jump: int = 1
var input_dir = Vector3.ZERO
var direction = Vector3.ZERO
var captured_by: Player

var HEAD_SCENE = load("res://Environment/SkullHead.tscn")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	id = str(name).to_int()

# TODO: Probably want determinsitic lockstep on physics:
# https://gafferongames.com/post/deterministic_lockstep/
func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_unhandled_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	invincible = true
	if (is_multiplayer_authority()):
		Store.e.connect(refresh)
		ready_client_only_nodes()

	await get_tree().create_timer(1).timeout
	invincible = false
	set_team()
	NAMELABEL.show()

# TODO: Clean all thes up, it's really a mashup of responsibilities. 
func ready_client_only_nodes():
	#$Sample.modulate = Store.client_join_info.color.lightened(0.2)
	_speed = SPEED_DEFAULT

	# add crouch check shapecast collision exception
	#CROUCH_SHAPECAST.add_exception($".")
	# add some ui
	var newUI = UI_SCENE.instantiate()
	newUI.player = self
	UI = newUI
	add_child(newUI)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	MODEL.hide()

	if multiplayer.is_server() and id == 1:
		Store.set_state('client_join', Store.client_join_info)

	if Store.client_join_info.nickname != '':
		$NameLabel.text = Store.client_join_info.nickname
	else:
		$NameLabel.text = 'Unnamed Noob'
	$NameLabel.hide()

	if get_tree().get_nodes_in_group("Players").size() % 2 == 0:
		add_to_group("Red")
		TEAM = "Red"
	else: 
		add_to_group("Blue")
		TEAM = "Blue"


var	spawns = []
	
func set_team():
	Store.set_player.rpc(id, 'team', TEAM)	
	if is_multiplayer_authority():
		# TODO: push down team mates to each player, calling refresh, removing team ids 
		set_team_spawns()
		respawn()
		show_mesh()
		
func swap_team():
	if is_multiplayer_authority():
		if TEAM == 'Red':
			remove_from_group('Red')
			add_to_group('Blue')
			TEAM = 'Blue'
			await get_tree().create_timer(0.2).timeout
			set_team()
		elif TEAM == 'Blue':
			remove_from_group('Blue')
			add_to_group('Red')
			TEAM = 'Red'
			await get_tree().create_timer(0.2).timeout
			set_team()

		
func show_mesh():
	if TEAM == 'Red':
		MODEL.MESH_BLUE.visible = false
		MODEL.MESH_RED.visible = true
	elif TEAM == 'Blue':
		MODEL.MESH_BLUE.visible = true
		MODEL.MESH_RED.visible = false
	
func set_team_spawns():
	var level = get_parent().get_node('Level')
	var spawn_nodes = null
	# clear out possible spawns
	spawns = []

	if TEAM == 'Red':
		spawn_nodes = level.get_node('SpawnsRed').get_children()
	elif TEAM == 'Blue':
		spawn_nodes = level.get_node('SpawnsBlue').get_children()

	for spawn_position in spawn_nodes:
		spawns.append(spawn_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if FSM.CURRENT_STATE.name == 'Busy':
			if $HookInputTimer.time_left > 0:
				_rotation_input = -event.relative.x * MOUSE_SENSITIVITY /15
				_tilt_input = -event.relative.y * MOUSE_SENSITIVITY / 15
			else:
				_rotation_input = -event.relative.x * MOUSE_SENSITIVITY / 30
				_tilt_input = -event.relative.y * MOUSE_SENSITIVITY / 30
		else:
			_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
			_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

	elif event.is_action_pressed('score'):
		UI.toggle_scoreboard()
	elif not ['Dead', 'Stunned', 'Busy'].has(FSM.CURRENT_STATE.name) and event.is_action_pressed('menu'):
		UI.toggleMenu()


func _process(_delta):
	if not ['Dead', 'Stunned', 'Busy', 'Locked'].has(FSM.CURRENT_STATE.name):
		get_input()

func get_input():
	if Input.is_action_pressed("exit"):
		get_tree().quit()

	if Input.is_action_just_pressed("hook") and HOOK.is_on_cooldown == false and HOOK_CHARGES > 0:
		HOOK_CHARGES -= 1
		FSM.set_state('Busy')
		if HOOK_RECHARGE_TIMER.is_stopped():
			$HookRecharge.start()
		$HookInputTimer.start()
		$HookMaxTimer.start()
		AUDIO.play("extend")
		HOOK.launch_hook()
		UI.refresh()
	elif Input.is_action_just_pressed("hook") and HOOK_CHARGES == 0:
		UI.HOOK_PANEL_CIRCLE.visible = false
		await get_tree().create_timer(0.1).timeout
		UI.HOOK_PANEL_CIRCLE.visible = true
		await get_tree().create_timer(0.1).timeout
		UI.HOOK_PANEL_CIRCLE.visible = false
		await get_tree().create_timer(0.1).timeout
		UI.HOOK_PANEL_CIRCLE.visible = true
		
	# 2 = pulling self, this cancels it during 
	if Input.is_action_just_pressed("hook") and HOOK.curr == 2:
		HOOK.cancel_hook()
		UI.refresh()

	if Input.is_action_just_pressed('sprint'):
		FSM.set_state('Sprint')

	if Input.is_action_just_released('sprint'):
		FSM.set_state('Walking')
		
	if Input.is_action_just_pressed('interact'):
		if picked_object == null:
			pick_object()
		elif picked_object != null:
			drop_object()

	if Input.is_action_just_pressed('Primary_Fire') and picked_object != null and global_position.distance_to(picked_object.global_position) < 3:
		picked_object.launch.rpc()
		picked_object = null
	elif Input.is_action_just_pressed('Primary_Fire') and picked_object != null and global_position.distance_to(picked_object.global_position) > 3:
		picked_object = null
		
		
	# CROUCH logic
	if Input.is_action_pressed("crouch") and TOGGLE_CROUCH == true:
		toggle_crouch()
	# Fires only if toggle mode is hold:
	if Input.is_action_pressed("crouch") and TOGGLE_CROUCH == false and _is_crouching == false:
		crouching(true)
	if Input.is_action_just_released("crouch") and TOGGLE_CROUCH == false:
		crouching(false)
		#if CROUCH_SHAPECAST.is_colliding() == false:
			#crouching(false)
		#elif CROUCH_SHAPECAST.is_colliding() == true:
			#uncrouch_check()

func _update_camera(delta):
	if FSM.CURRENT_STATE.name == 'Stunned':
		look_at(captured_by.global_position)
		CAMERA_CONTROLLER.transform.basis = Basis.from_euler(Vector3(transform.origin.direction_to(captured_by.global_position).y,0.0,0.0))
		_mouse_rotation.y = global_transform.basis.get_euler().y
		_mouse_rotation.x = CAMERA_CONTROLLER.transform.basis.get_euler().x
	else:
		# Rotates camera using euler rotation
		_mouse_rotation.x += _tilt_input * delta
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
		_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	if FSM.CURRENT_STATE.name == 'Dead':
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT /3 , TILT_UPPER_LIMIT /3)
		DEATH_CAM.transform.basis = Basis.from_euler(Vector3(_mouse_rotation.x, 0.0, 0.0))
	else:
		CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
		global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0


# what if, you could shanlnge 'em, shlinge 'em?
# TODO: Essentially "Record input from mouse rotation, input from the time of connection?
func _physics_process(delta):
	_update_camera(delta)
	if WEAPON_CAST.get_collider() != null and picked_object == null: 
		UI._update_picked_collision(WEAPON_CAST.get_collider())
	else: 
		UI._update_picked_collision(null)
	if FSM.CURRENT_STATE.name == 'Dead':
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)
		move_and_slide()
		return
	# Stun the player, locking them in place briefly
	if FSM.CURRENT_STATE.name == 'Stunned' and not $HookStunnedTimer.is_stopped():
		velocity.x = 0
		velocity.z = 0
		return
	if FSM.CURRENT_STATE.name == 'Stunned' and global_position.distance_to(captured_by.global_position) > 1.5:
		direction = global_position.direction_to(captured_by.global_position)
		velocity = direction * CAPTURE_SPEED
		move_and_slide()
		return
	elif FSM.CURRENT_STATE.name == 'Stunned':
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		arrive_at_hook()
		return
		
	# Update camera movement based on mouse movement
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Handle Jump.	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("jump") and air_jump > 0:
		air_jump -= 1
		velocity.y = JUMP_VELOCITY
		
	if is_on_floor() and air_jump == 0:
		air_jump = 1
				
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# TODO: Flying movement 
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor() and _is_crouching == true and _speed > 2:
		set_movement_speed('crouching')

	if direction:
		velocity.x = lerp(velocity.x, direction.x * _speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * _speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)

	move_and_slide()

#func uncrouch_check():
	#if CROUCH_SHAPECAST.is_colliding() == false:
		#crouching(false)
	#if CROUCH_SHAPECAST.is_colliding() == true:
		#await get_tree().create_timer(0.1).timeout
		#uncrouch_check()

func toggle_crouch():
	if _is_crouching == true:
		crouching(false)
	elif _is_crouching == false:
		crouching(true)

func crouching(state: bool):
	match state:
		true:
			ANIMATIONPLAYER.play("crouch", -1, CROUCH_SPEED)
			_is_crouching = !_is_crouching
			if is_on_floor():
				set_movement_speed("crouching")
		false:
			ANIMATIONPLAYER.play("crouch", -1, -CROUCH_SPEED, true)
			_is_crouching = !_is_crouching
			set_movement_speed("default")

func set_movement_speed(state: String):
	match state:
		"default":
			_speed = SPEED_DEFAULT
		"crouching":
			_speed = SPEED_CROUCH

var invincible = false

func take_damage(_last_damage_source, damage: int):
	if _last_damage_source == 0:
		return
	if invincible == false:
		if _last_damage_source != null and _last_damage_source != 0:
			last_damage_source = _last_damage_source

		if health - damage <= 0 and FSM.CURRENT_STATE.name != 'Stunned':
			die()
			health_changed.emit(0)
		else:
			health -= damage
			health_changed.emit(health)
			HEALTH_TIMER.start()
			
func die():	
	if invincible == false:
		gravity = 0	
		drop_object()
		HOOK.cancel_hook()
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		FSM.set_state('Dead')
		# TODO: Rules on spawn death head. Only if a player dies "offsides"
		if FSM.CURRENT_STATE.name == "Dead":
			report_death()
			if is_damage_over_time == 2:
				spawn_death_head.rpc(MODEL.HEAD.global_position, global_position.direction_to(LOOKPOINT.global_position))

		if FSM.CURRENT_STATE.name == "Dead":	
			await get_tree().create_timer(5).timeout
			show_level_cam()
			
func show_level_cam():
	if FSM.CURRENT_STATE.name == "Dead":
		set_level_cam()

func report_death():
	# Death occured, but no source to credit, we're done here
	if last_damage_source == null:
		Store.set_player.rpc(id, 'deaths', null)
	else:
		# We have a source, so credit the kill and report the death.
		if Store.store.players.has(last_damage_source):
			last_kill.emit(Store.store.players[last_damage_source].nickname)
		Store.set_player.rpc(last_damage_source, 'kills', null)
		Store.set_player.rpc(id, 'deaths', null)

func respawn():
	CAMERA_CONTROLLER.current = true
	set_collision_layer_value(6, true)
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(24, true)
	$DOT.stop()
	is_damage_over_time = 0
	health = HEALTH_DEFAULT
	health_changed.emit(HEALTH_DEFAULT)
	max_health = HEALTH_DEFAULT
	last_damage_source = null
	HOOK.ready_hook()
	HOOK.show()
	show_mesh()
	NAMELABEL.show()
	# does double reload first time, but necessary for respawning to reset.
	# WEAPONS.Initialize(WEAPONS.Start_Weapons)


	var rng = RandomNumberGenerator.new()
	var random_position =  spawns[rng.randi_range(0, int(spawns.size() - 1))].global_position
	var rndX = int(rng.randi_range(int(random_position.x) - 5, int(random_position.x) + 5))
	var rndZ = int(rng.randi_range(int(random_position.z) - 5, int(random_position.z) + 5))

	var new_spawn = Vector3(rndX, random_position.y, rndZ)
	global_position = new_spawn


func change_team():
	pass
	
# Trying to make the hooked target look at the player
# I don't understand basis / Eulers and shit, so this is brain breaking, but, I figured out since y is always 1, that this 
# is a top down mapping of mouse movement. Mouse movement is on a 2D plane, this maps to the 3d in X and Z, so if we look at z
# X is left and right
# Z is up and down looking
# Ended up just doing look_at and capturing that transform.basis and mapping it back to mouse somehow (in stunned) behavior.
@rpc('call_local', 'any_peer')
func get_hooked():
	if captured_by == null:
		HOOK.cancel_hook()
		FSM.set_state('Stunned')
		# STUN TIMER
		$HookStunnedTimer.start(0.45)
		$HookMaxTimer.start()
		var playerId = multiplayer.get_remote_sender_id()
		captured_by = get_parent().get_node(str(playerId))
		take_damage(playerId, 1)
		# captured_by.HOOK.hide_hook()
	else: 
		captured_by = null

func arrive_at_hook():
	FSM.set_state("Busy")
	await get_tree().create_timer(0.5).timeout
	captured_by = null
	FSM.set_state("Idle")
	# if last_damage_source != null: get_parent().get_node(str(last_damage_source)).HOOK.unhide_hook()

func _on_hook_recharge_timeout():
	if HOOK_CHARGES < HOOK_STARTING_CHARGES:
		if HOOK_CHARGES == 0: HOOK.unhide_hook()
		HOOK_CHARGES += 1
		UI.refresh()
	else:
		$HookRecharge.stop()

@rpc("any_peer", "call_local")
func Hit_Successful(Source, Damage, _Direction, _Position):
	# print('Hit Successful Called on Player:', get_multiplayer_authority(), ': ', Damage, 'from: ', Source)
	# This check effectively prevents self damage.
	if Source != get_multiplayer_authority():
		if my_team_ids.find(Source) == -1:
			take_damage(Source, Damage)

func refresh():
	var players_store = Store.store.players
	my_team_ids = []
	for key in players_store:
		if players_store[key].team == TEAM:
			my_team_ids.append(key)

@rpc("call_local", "any_peer", "reliable")
func spawn_death_head(pos, rot):
	if multiplayer.is_server():
		var new_head = HEAD_SCENE.instantiate()
		new_head.position = pos
		new_head.set_linear_velocity(rot * 3.0)
		get_parent().add_child(new_head, true)

var picked_object;

func pick_object():
	var collider = WEAPON_CAST.get_collider()
	if collider != null and collider.is_in_group('Head'): 
		picked_object = collider
		picked_object.reserve.rpc(true)
		
				
func drop_object():
	if picked_object != null:
		picked_object.reserve.rpc(false)
		picked_object = null

func _on_hook_max_timer_timeout():
	if FSM.CURRENT_STATE.name == 'Busy':
		FSM.set_state("Idle")
	if FSM.CURRENT_STATE.name == 'Stunned' and captured_by != null:
		arrive_at_hook()
	pass # Replace with function body.

@rpc('any_peer', 'call_local')
func toggle_damage_over_time(value):
	is_damage_over_time = value
	take_damage_over_time()

func take_damage_over_time():
	if is_damage_over_time != 0 and FSM.CURRENT_STATE.name != 'Dead':
		take_damage(null, is_damage_over_time)
		$DOT.start()
		
func _on_dot_timeout():
	if is_damage_over_time != 0:
		take_damage_over_time()
	else:
		$DOT.stop()

func set_level_cam():
	var level = get_parent().get_node('Level')
	level.LEVEL_CAM.current = true


func _on_health_timeout():
	if not ['Dead', 'Stunned', 'Busy', 'Locked'].has(FSM.CURRENT_STATE.name):
		print(FSM.CURRENT_STATE.name)
		HEALTH_RECOVER_TIMER.start()
	elif health < HEALTH_DEFAULT:
		HEALTH_TIMER.start() 
	pass # Replace with function body.


func _on_recover_timeout():
	if not ['Dead', 'Stunned', 'Busy', 'Locked'].has(FSM.CURRENT_STATE.name) and HEALTH_TIMER.is_stopped() and health < HEALTH_DEFAULT:
			health += 2
			HEALTH_RECOVER_TIMER.start()
			health_healed.emit(health)

@rpc('any_peer', 'call_local')
func drop_object_server():
	drop_object()
