extends Node

@export var score = 0
@export var peer_list = []

# TODO: Use that tutorial's FPS and stats settings thing

# TODO: Make unique and use %, combine with debug, or use one or the other.
@onready var SETTINGS_MENU = $CanvasLayer/SettingsMenu
@onready var SCOREBOARD = $CanvasLayer/Scoreboard
# @onready var players_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Players
#@onready var host_ip_container = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer
#@onready var hidden_ip = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP

@onready var HOOK_PANEL_CIRCLE = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle
@onready var hooks_count = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/Panel/HookCount
@onready var HOOK_RECHARGE_PROGRESS = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/HookRechargeProgress
@onready var HOOK_SPRITE = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/HookSprite

@onready var HEALTH_BAR: ProgressBar = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/HealthBar
@onready var HELPER_TEXT: Label = $CanvasLayer/HUD/HelperText

@onready var RED_PLAYERS_LABEL = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Red/RedPlayers/RedPlayersLabel
@onready var BLUE_PLAYERS_LABEL = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Blue/BluePlayers/BluePlayersLabel

@onready var BLUE_SCORE = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Blue/BlueScore
@onready var RED_SCORE = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Red/RedScore

@onready var BLOOD = $CanvasLayer/blood

var player: Player

# Buttons
@onready var RESPAWN = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/buttons/Respawn
@onready var SWITCH = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/buttons/Switch



# settings
@onready var sensitivity_slider: HSlider = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/SensitivitySlider

@onready var master_slider: HSlider = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/Master
@onready var music_slider: HSlider = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/Music
@onready var sfx_slider: HSlider = $CanvasLayer/SettingsMenu/MarginContainer/Panel/MarginContainer/VBoxContainer/SFX

var bus_master = AudioServer.get_bus_index("Master")
var bus_music = AudioServer.get_bus_index("Music")
var bus_sfx = AudioServer.get_bus_index("SFX")

# TODO: programatically do all this from a List[]
var volume_master_value
var volume_music_value
var volume_sfx_value
		
func _ready():
	stretch_blood()
	
	SETTINGS_MENU.hide()
	SCOREBOARD.hide()

	Store.e.connect(refresh)
	player.health_changed.connect(flash_damage)
	HOOK_RECHARGE_PROGRESS.max_value = player.HOOK_RECHARGE_TIMER.wait_time * 100
	#if Store.upnp_host_ip != '':
		#host_ip_container.visible = true
		#hidden_ip.text = Store.upnp_host_ip
	refresh()
	player.health_changed.connect(update_health)
	player.health_healed.connect(update_health)
	player.last_kill.connect(update_last_killed_by)
	HEALTH_BAR.max_value = player.HEALTH_DEFAULT
	HEALTH_BAR.value = player.HEALTH_DEFAULT

	volume_master_value = db_to_linear(AudioServer.get_bus_volume_db(bus_master))
	volume_music_value = db_to_linear(AudioServer.get_bus_volume_db(bus_music))
	volume_sfx_value = db_to_linear(AudioServer.get_bus_volume_db(bus_sfx))

	sensitivity_slider.max_value = player.MOUSE_SENSITIVITY * 2
	sensitivity_slider.value = player.MOUSE_SENSITIVITY
	
	# sliders
	master_slider.max_value = volume_master_value * 2
	music_slider.max_value = volume_music_value * 2
	sfx_slider.max_value = volume_sfx_value * 2
	# values
	master_slider.value = volume_master_value 
	music_slider.value = volume_music_value
	sfx_slider.value = volume_sfx_value

func _process(_delta):
	if player.WEAPON_CAST.get_collider() != null and player.picked_object == null: 
		_update_picked_collision(player.WEAPON_CAST.get_collider())
	else: 
		_update_picked_collision(null)

	if player.HOOK_CHARGES < player.HOOK_STARTING_CHARGES:
		HOOK_RECHARGE_PROGRESS.value = player.HOOK_RECHARGE_TIMER.time_left * 100


func update_health(new_value):
	HEALTH_BAR.value = new_value

func refresh():
	var redPlayers = ""
	var bluePlayers = ""

	for id in Store.store.players: 
		var player_string = ""
		var player_data = Store.store.players[id]
		# k = key
		for k in player_data:
			if k == 'id':
				pass
			else:
				player_string += str(player_data[k]) + ' | '

		if player_data.team == "Red":
			redPlayers += player_string + '\n'
			RED_PLAYERS_LABEL.text = redPlayers
		elif player_data.team == "Blue":
			bluePlayers += player_string + '\n'		
			BLUE_PLAYERS_LABEL.text = bluePlayers


	hooks_count.text = str(player.HOOK_CHARGES)
	RED_SCORE.text = str(Store.store.red_score)
	BLUE_SCORE.text = str(Store.store.blue_score)
		
	if player.HOOK_CHARGES == 0:
		HOOK_SPRITE.modulate = Color(0, 0, 0, 0.3)
	else:
		HOOK_SPRITE.modulate = Color(0, 0, 0, 1)
		
	$CanvasLayer/HUD/Log.text = Store.store.log
	
func toggle_scoreboard():
	if SCOREBOARD.visible: SCOREBOARD.hide()
	else: SCOREBOARD.show()

func toggleMenu():
	SETTINGS_MENU.visible = !SETTINGS_MENU.visible
	if (SETTINGS_MENU.visible == true):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.FSM.set_state("Locked")		
	else: 
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.FSM.set_state("Idle")		
		
func _on_host_ip_button_toggled(toggled_on):
	$CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP.visible = toggled_on

var help_head = 'Pick up (E)'

func _update_picked_collision(collider):
	if collider != null and collider.is_in_group('Head') and HELPER_TEXT.visible == false:
		HELPER_TEXT.visible = true
		HELPER_TEXT.text = help_head
	elif collider == null and HELPER_TEXT.visible == true:
		HELPER_TEXT.visible = false

func flash_damage(_damage):
	if _damage != 100:
		$CanvasLayer/AnimationPlayer.stop()
		$CanvasLayer/AnimationPlayer.play('blood')


func _on_quit_pressed():
	get_tree().quit()	
	pass # Replace with function body.


func _on_sensitivity_slider_value_changed(value):
	player.MOUSE_SENSITIVITY = value
	pass # Replace with function body.

func _on_master_value_changed(value):
	AudioServer.set_bus_volume_db(bus_master, linear_to_db(value))
	pass # Replace with function body.


func _on_sfx_value_changed(value):
	AudioServer.set_bus_volume_db(bus_music, linear_to_db(value))
	pass # Replace with function body.


func _on_music_value_changed(value):
	AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(value))
	pass # Replace with function body.

func _on_switch_pressed():
	SWITCH.disabled = true
	RESPAWN.disabled = true
	$TeamTimer.start()
	toggleMenu()
	await get_tree().create_timer(0.2).timeout
	player.swap_team()
	pass # Replace with function body.


func _on_respawn_pressed():
	SWITCH.disabled = true
	RESPAWN.disabled = true
	$TeamTimer.start()
	toggleMenu()
	await get_tree().create_timer(0.2).timeout
	player.die()
	pass # Replace with function body.


func _on_team_timer_timeout():
	SWITCH.disabled = false
	RESPAWN.disabled = false	
	pass # Replace with function body.

func update_last_killed_by(player_name):
	if player_name:
		$CanvasLayer/Scoreboard/LastKill.text = 'Last killed by: ' + player_name

@onready var base_size = Vector2(1920, 1080)

func stretch_blood():
	var window_size = DisplayServer.window_get_size()
	var scale = min(window_size.x / base_size.x, window_size.y / base_size.y)
	$CanvasLayer/blood/BloodSprite.scale.x = scale * 1.15
	$CanvasLayer/blood/BloodSprite.scale.y = scale * 1.2
