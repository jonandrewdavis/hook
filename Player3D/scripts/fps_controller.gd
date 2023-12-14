extends CharacterBody3D
class_name Player

@export var SPEED_DEFAULT: float = 4.5
@export var SPEED_SPRINTING: float = 6.5
@export var SPEED_CROUCH: float = 2.0

@export var ACCELERATION : float = 0.08
@export var DECELERATION : float = 0.25

@export var SPEED : float = 5.0
@export var JUMP_VELOCITY : float = 4.5
@export_range(5, 10) var CROUCH_SPEED: float = 7
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST: Node3D
@export var TOGGLE_CROUCH: bool

@export var UI_SCENE: PackedScene
var UI = null

signal damage

var _speed: float
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _is_crouching = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	add_to_group("players") # lowercase or upper? I like lower for now.
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_unhandled_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	
	if is_multiplayer_authority():
		ready_client_only_nodes()
		respawn()
	
# TODO: Clean all thes up, it's really a mashup of responsibilities. 
func ready_client_only_nodes():
	#$Sample.modulate = 	Store.client_join_info.color.lightened(0.2)
	#$Nickname.text = Store.client_join_info.nickname
	damage.connect(take_damage)
	_speed = SPEED_DEFAULT
	
	# add crouch check shapecast collision exception
	CROUCH_SHAPECAST.add_exception($".")
	CAMERA_CONTROLLER.current = true	
	# add some ui
	var newUI = UI_SCENE.instantiate()
	newUI.player = self
	UI = newUI
	add_child(newUI)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
	elif event.is_action_pressed('debug'):
		UI.toggle_debug()

func _process(_delta):
	get_input()

func get_input():
	if Input.is_action_pressed("exit"):
		get_tree().quit()
	if Input.is_action_pressed("crouch") and TOGGLE_CROUCH == true:
		toggle_crouch()

	if Input.is_action_just_pressed('shoot'):
		shoot()
		
	# Fires only if toggle mode is hold:
	if Input.is_action_pressed("crouch") and TOGGLE_CROUCH == false and _is_crouching == false:
		print(get_multiplayer_authority(), ', cronch')
		crouching(true)
	if Input.is_action_just_released("crouch") and TOGGLE_CROUCH == false:
		if CROUCH_SHAPECAST.is_colliding() == false:
			crouching(false)
		elif CROUCH_SHAPECAST.is_colliding() == true:
			uncrouch_check()
	
func _update_camera(delta):
	# Rotates camera using euler rotation
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0

func _physics_process(delta):	
	# Update camera movement based on mouse movement
	_update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor() and _is_crouching == true and _speed > 2:
		set_movement_speed('crouching')
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * _speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * _speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)

	move_and_slide()

func uncrouch_check():
	if CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false)
	if CROUCH_SHAPECAST.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func toggle_crouch():
	if _is_crouching == true and CROUCH_SHAPECAST.is_colliding() == false:
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

func take_damage(_damage):
	print('damage', _damage)
	position = Vector3.ZERO


func respawn():
	var level = get_parent().get_node('Level')
	var spawns = []
	for spawn_position in level.get_node('Spawns').get_children():
		spawns.append(spawn_position)
	
	var rng = RandomNumberGenerator.new()
	var random_position =  spawns[rng.randi_range(0, int(spawns.size() - 1))].global_position
	var rndX = int(rng.randi_range(int(random_position.x) - 5, int(random_position.x) + 5))
	var rndZ = int(rng.randi_range(int(random_position.z) - 5, int(random_position.z) + 5))
	# y is up and down, so don't change that.
	position = Vector3(rndX, random_position.y, rndZ )

@onready var gun = $CameraController/Camera3D/Gun
func shoot():
	if gun.animation_player.is_playing() == false:
		gun.animation_player.play('shoot')
		var newVal = Store.store.score + 1
		Store.set_state.rpc('score', newVal)
		# Because player input isn't synced and spawn happens on the server
		# we need to pass in the mouse position of the player who casted it.
		spawn_bullet.rpc(gun.barrel.global_position, gun.barrel.global_transform.basis)

# TODO: Bullet "pool"
var bullet_scene = load("res://Projectiles/Shell.tscn")
var bullet

@rpc("call_local", "reliable")
func spawn_bullet(pos, rot):
	if multiplayer.is_server():
		bullet = bullet_scene.instantiate()
		bullet.position = pos
		bullet.transform.basis = rot
		# I learned the hard way only the server should add things the MultiplayerSpawner will handle the rest.
		get_parent().add_child(bullet, true)
