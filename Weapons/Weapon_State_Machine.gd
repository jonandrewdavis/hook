extends Node3D


class_name WeaponsManager

signal Weapon_Changed
signal Update_Ammo
signal Update_WeaponStack
signal Add_Signal_To_HUD

signal Connect_Weapon_To_HUD

@export var Animation_Player: AnimationPlayer
@onready var Bullet_Point = get_node("%BulletPoint")

@onready var Debug_Bullet = preload("res://Weapons/Spawnable_Objects/hit_debug.tscn")
@onready var WORLD = get_tree().get_root().get_node('Main').get_node('World')
@onready var PLAYER: Player = get_parent().get_parent().get_parent() 

@onready var BULLET_SCENE = preload("res://Weapons/Spawnable_Objects/bullet.tscn")

# TODO: Refactor to use no proper case...

var Melee_Shake:= Vector3(0,0,2.5)
var Melee_Shake_Magnetude:= Vector4(1,1,1,1)

#var Secondary_Mode = false

@export var Current_Weapon: Weapon_Resource = null

var WeaponStack = [] #An Array of weapons currently in possesion by the player

#var WeaponIndicator = 0
@export var Next_Weapon: String

#WEAPON TYPE ENUMERATOR TO HELP WITH CODE READABILITY
enum {NULL,HITSCAN, PROJECTILE}

var Collision_Exclusion: Array

#The List of All Available weapons in the game
var Weapons_List = {
}

#An Array of weapon resources to make dictionary creation easier
@export var _weapon_resources: Array[Weapon_Resource]
@export var Start_Weapons: Array[String]


func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_unhandled_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())

	Animation_Player.animation_finished.connect(_on_animation_finished)
	Initialize(Start_Weapons) #current starts on the first weapon in the stack

func _input(event):
	if not is_multiplayer_authority():
		return
	if ['Dead', 'Stunned', 'Busy', 'Locked'].has(PLAYER.FSM.CURRENT_STATE.name):
		return

	if event.is_action_pressed("Weapon_Up"):
		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
		GetRef = min(GetRef+1,WeaponStack.size()-1)
		
		exit(WeaponStack[GetRef])

	if event.is_action_pressed("Weapon_Down"):
		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
		GetRef = max(GetRef-1,0)

		exit(WeaponStack[GetRef])
		
	if event.is_action_pressed("Secondary_Fire"):
		secondary()
		
	if event.is_action_released("Secondary_Fire"):
		reset_secondary()
		
	if event.is_action_pressed("Primary_Fire") and PLAYER.picked_object == null:
		shoot()
		
	if event.is_action_released("Primary_Fire"):
		Current_Weapon.Spray_Count_Update()
		
	if event.is_action_pressed("Reload"):
		reload()

	if event.is_action_pressed("Drop_Weapon"):
		drop(Current_Weapon.Weapon_Name)
		
	if event.is_action_pressed("Melee"):
		melee()
		
func Initialize(_Start_Weapons: Array):
	if not is_multiplayer_authority():
		return
	for Weapons in _weapon_resources:
		Weapons.ready()
		Weapons_List[Weapons.Weapon_Name] = Weapons
		Connect_Weapon_To_HUD.emit(Weapons)
		
	for child in _Start_Weapons:
		WeaponStack.push_back(child)

	Current_Weapon = Weapons_List[WeaponStack[0]]

	Update_WeaponStack.emit(WeaponStack)
	enter()

func enter():
	if not is_multiplayer_authority():
		return
	Animation_Player.queue(Current_Weapon.Pick_Up_Anim)
	Current_Weapon.Spray_Count_Update()
	Weapon_Changed.emit(Current_Weapon.Weapon_Name)
	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

func exit(_next_weapon: String):
	if not _next_weapon: 
		return
	if not is_multiplayer_authority():
		return
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Change_Anim:
			if Current_Weapon.Secondary_Mode == true:
				reset_secondary()
			Animation_Player.queue(Current_Weapon.Change_Anim)
			Next_Weapon = _next_weapon

func Change_Weapon(weapon_name: String):
	if not weapon_name: 
		return
	if not is_multiplayer_authority():
		return
	Current_Weapon = Weapons_List[str(weapon_name)]
	Next_Weapon = ""
	enter()
	Animation_Player.queue('weapon_animation/show_%s' % weapon_name)
		
func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if not Animation_Player.is_playing():
			PLAYER.AUDIO.play(Current_Weapon.Audio_Animation)
			Animation_Player.play(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var Camera_Collission =  GetCameraCollision(Current_Weapon.Fire_Range)
			match Current_Weapon.Type:
				NULL:
					pass
				HITSCAN:
					HitScanCollision(Camera_Collission)
				PROJECTILE:
					LaunchProjectile(Camera_Collission[1])
	else:
		reload()


func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif not Animation_Player.is_playing():
		
		if Current_Weapon.Reserve_Ammo != 0:		
			if Current_Weapon.Secondary_Mode == true:
				reset_secondary()
				
			Animation_Player.queue(Current_Weapon.Reload_Anim)
			PLAYER.AUDIO.queue("reload")
		else:
			Animation_Player.queue(Current_Weapon.Out_Of_Ammo_Anim)

func Calculate_Reload():
	var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo,Current_Weapon.Magazine,Current_Weapon.Reserve_Ammo)

	Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo+Reload_Amount
	Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo-Reload_Amount
	Current_Weapon.Spray_Count_Update()
	
	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])


func melee():
	if Current_Weapon.Secondary_Mode:
		reset_secondary()
		
	var Current_Anim = Animation_Player.get_current_animation()
	
	if Current_Anim == Current_Weapon.Shoot_Anim:
		return
		
	if Current_Anim != Current_Weapon.Melee_Anim:
		Animation_Player.play(Current_Weapon.Melee_Anim)
		PLAYER.AUDIO.play('melee')
		var Camera_Collission =  GetCameraCollision(2)
		if Camera_Collission[0]:
			var Direction = (Camera_Collission[1] - owner.global_transform.origin).normalized()
			HitScanDamage(Camera_Collission[0],Direction,Camera_Collission[1], Current_Weapon.Melee_Damage)
			
func drop(_name: String):
	if Weapons_List[_name].Can_Be_Dropped and WeaponStack.size() != 1:
		var Weapon_Ref = WeaponStack.find(_name,0)
		if Weapon_Ref != -1:
			WeaponStack.pop_at(Weapon_Ref)
			Update_WeaponStack.emit(WeaponStack)

			if Weapons_List[_name].Weapon_Drop:
				var Weapon_Dropped = Weapons_List[_name].Weapon_Drop.instantiate()
				Weapon_Dropped._current_ammo = Weapons_List[_name].Current_Ammo
				Weapon_Dropped._reserve_ammo = Weapons_List[_name].Reserve_Ammo

				Weapon_Dropped.set_global_transform(Bullet_Point.get_global_transform())
				get_tree().get_root().add_child(Weapon_Dropped)

				Animation_Player.play(Current_Weapon.Drop_Anim)
				Weapon_Ref  = max(Weapon_Ref-1,0)
				exit(WeaponStack[Weapon_Ref])
	else:
		return
		
func _on_animation_finished(anim_name):
	if anim_name == 'weapon_animation/show':
		return
	if not is_multiplayer_authority():
		return
	if anim_name == Current_Weapon.Shoot_Anim:
		if Current_Weapon.AutoFire == true:
				if Input.is_action_pressed("Primary_Fire"):
					shoot()
	
	if anim_name == Current_Weapon.Change_Anim and Next_Weapon:
		Change_Weapon(Next_Weapon)

		
	if anim_name == Current_Weapon.Reload_Anim:
		Calculate_Reload()
	
	CheckSecondaryMode()
	

	
func CheckSecondaryMode():	
	if Current_Weapon.Secondary_Mode == true:
		if !Input.is_action_pressed("Secondary_Fire"):
			reset_secondary()	


@onready var _Camera = get_node('%PlayerCamera')
@onready var _Viewport = get_viewport().get_size()
	
func GetCameraCollision(_fire_range: int)->Array:
	var Spray = Current_Weapon.Get_Spray()
	
	if Current_Weapon.Secondary_Mode == true:
		Spray = Vector2.ZERO
	
	var Ray_Origin = _Camera.project_ray_origin(_Viewport/2)
	var Ray_End = (Ray_Origin + _Camera.project_ray_normal((_Viewport/2)+Vector2i(Spray))*_fire_range)

	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	# New_Intersection.set_exclude(Collision_Exclusion)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Collision = [Intersection.collider,Intersection.position]
		var rd = Debug_Bullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(rd)
		rd.global_translate(Intersection.position)
		return Collision
	else:
		return [null,Ray_End]

func HitScanCollision(Collision: Array):
	var Point = Collision[1]
	if Collision[0]:
		if Collision[0].is_in_group("Target"):
			var Bullet = get_world_3d().direct_space_state

			var Bullet_Direction = (Point - Bullet_Point.global_transform.origin).normalized()
			var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.global_transform.origin,Point+Bullet_Direction*2)

			var Bullet_Collision = Bullet.intersect_ray(New_Intersection)

			if Bullet_Collision:
				HitScanDamage(Bullet_Collision.collider, Bullet_Direction,Bullet_Collision.position,Current_Weapon.Damage)

func HitScanDamage(Collider, Direction, Position, Damage):
	if Collider.is_in_group("Players") and Collider.has_method("Hit_Successful"):
		# print('melee:', Collider.id, PLAYER.id, Damage, Direction, Position)
		Collider.Hit_Successful.rpc_id(Collider.id, PLAYER.id, Damage, Direction, Position)

	if Collider.is_in_group("Head") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Melee.rpc(PLAYER.id, Damage, Direction, Position)

	# TODO: Hitscan for objects.
	# if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		
var spread_min = 0.008
var spread = 0.07
func LaunchProjectile(Point: Vector3):
	var Direction_To_Point = (Point - Bullet_Point.global_transform.origin).normalized()
	var Direction = Direction_To_Point * Current_Weapon.Projectile_Velocity
	#var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
#
	#Bullet_Point.add_child(Projectile)
	#Add_Signal_To_HUD.emit(Projectile)
	#
	#var Projectile_RID = Projectile.get_rid()
	#
	##Collision_Exclusion.push_back(Projectile_RID)
	##Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile_RID))
	#
	#Projectile.set_linear_velocity(Direction*Current_Weapon.Projectile_Velocity)
	#Projectile.Damage = Current_Weapon.Damage

	if Current_Weapon.Count == 1:
		spawn_bullet.rpc(Direction, Current_Weapon.Damage, Bullet_Point.global_transform.origin, PLAYER.WEAPON_CAST.global_basis)
	else:	
		spawn_cluster.rpc(Direction, Current_Weapon.Damage, Bullet_Point.global_transform.origin, PLAYER.WEAPON_CAST.global_basis, Current_Weapon.Count)

@rpc('any_peer', 'call_local')
func spawn_bullet(Direction, Damage, Position, Rotation):
	if multiplayer.is_server():
		var Projectile = BULLET_SCENE.instantiate()
		Projectile.position = Position
		Projectile.transform.basis = Rotation
		Projectile.set_linear_velocity(Direction)
		Projectile.Damage = Damage
		Projectile.Source = multiplayer.get_remote_sender_id()
		# I learned the hard way only the server should add things the MultiplayerSpawner will handle the rest.
		WORLD.add_child(Projectile, true)

		#bullet = bullet_scene.instantiate()
		#bullet.position = pos
		#bullet.transform.basis = rot
		#bullet.is_burst = is_burst
		#bullet.source = multiplayer.get_remote_sender_id()

@rpc('any_peer', 'call_local')
func spawn_cluster(Direction, Damage, Position, Rotation, Count):
	if multiplayer.is_server():
		for n in Count:
			var random_negative = []
			# randomize rotation in 3 directions
			for n2 in 3:
				if randi()%2 == 1:
					random_negative.append(1)
				else:
					random_negative.append(-1)
			var random_rotation = Basis.from_euler(Vector3(randf_range(spread_min, spread) * random_negative[0], randf_range(spread_min, spread) * random_negative[1], randf_range(spread_min, spread) * random_negative[2]))
			var Projectile = BULLET_SCENE.instantiate()
			Projectile.shell = true
			Projectile.position = Position
			Projectile.transform.basis = Rotation
			Projectile.set_linear_velocity(Direction * random_rotation)
			Projectile.Damage = Damage
			Projectile.Source = multiplayer.get_remote_sender_id()
			WORLD.add_child(Projectile, true)

func Remove_Exclusion(_RID):
	Collision_Exclusion.erase(_RID)

func _on_pick_up_detection_body_entered(body):
	var Weapon_In_Stack = WeaponStack.find(body._weapon_name,0)
	
	if Weapon_In_Stack != -1:
		var remaining

		remaining = Add_Ammo(body._weapon_name, body._current_ammo+body._reserve_ammo)
		body._current_ammo = min(remaining, Weapons_List[body._weapon_name].Magazine)
		body._reserve_ammo = max(remaining - body._current_ammo,0)

		if remaining == 0:
			body.queue_free()
		
	elif body.TYPE == "Weapon":
		if body.Pick_Up_Ready == true:
			var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
			WeaponStack.insert(GetRef,body._weapon_name)

			#Zero Out Ammo From the Resource
			Weapons_List[body._weapon_name].Current_Ammo = body._current_ammo
			Weapons_List[body._weapon_name].Reserve_Ammo = body._reserve_ammo

			Update_WeaponStack.emit(WeaponStack)
			exit(body._weapon_name)

			body.queue_free()

func Add_Ammo(_Weapon: String, Ammo: int)->int:
	var _weapon = Weapons_List[_Weapon]

	var Required = _weapon.Max_Ammo - _weapon.Reserve_Ammo
	var Remaining = max(Ammo - Required,0)

	_weapon.Reserve_Ammo += min(Ammo, Required)

	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	return Remaining
	
func secondary():
	if Current_Weapon.Secondary_Fire_Resource:
		if not Animation_Player.is_playing():
			Current_Weapon.Secondary_Fire()
			
			if Current_Weapon.Secondary_Fire_Resource.Secondary_Fire_Shoot:
				Secondary_Shoot(Current_Weapon.Secondary_Fire_Resource)
				
			Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation)

func reset_secondary():
	if Current_Weapon.Secondary_Fire_Resource:
		if Current_Weapon.Secondary_Mode:
			if not Animation_Player.is_playing():
				Current_Weapon.Secondary_Fire_Released()
				if Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset:
					Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset)

func Secondary_Shoot(secondary_resource):
	if secondary_resource.Ammo != 0:
		secondary_resource.Ammo  -= 1
		var CollissionPoint =  GetCameraCollision(Current_Weapon.Fire_Range)
		match secondary_resource.Fire_Type:
			"Hitscan":
				HitScanCollision(CollissionPoint)
			"Projectile":
				LaunchProjectile(CollissionPoint[1])
	reset_secondary()



#### NET NEW

