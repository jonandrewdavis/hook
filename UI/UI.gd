extends Node

@export var score = 0
@export var peer_list = []

# TODO: Use that tutorial's FPS and stats settings thing

# TODO: Make unique and use %, combine with debug, or use one or the other.
@onready var menu_ref = $CanvasLayer/SettingsMenu
@onready var players_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Players
@onready var host_ip_container = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer
@onready var hidden_ip = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP

@onready var HOOK_PANEL_CIRCLE = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle
@onready var hooks_count = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/Panel/HookCount
@onready var HOOK_RECHARGE_PROGRESS = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/HookRechargeProgress
@onready var HOOK_SPRITE = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/PanelCircle/HookSprite

@onready var HEALTH_BAR: ProgressBar = $CanvasLayer/HUD/BottomLeft/MarginContainer/VBoxContainer/HealthBar
@onready var HELPER_TEXT: Label = $CanvasLayer/HUD/HelperText

@onready var RED_PLAYERS_LABEL = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Red/RedPlayers/RedPlayersLabel
@onready var BLUE_PLAYERS_LABEL = $CanvasLayer/Scoreboard/MarginContainer/PanelContainer/TeamsMargin/Teams/Blue/BluePlayers/BluePlayersLabel

@onready var BLOOD = $CanvasLayer/blood

var player: Player


func _process(_delta):
	if player.WEAPON_CAST.get_collider() != null and player.picked_object == null: 
		_update_picked_collision(player.WEAPON_CAST.get_collider())
	else: 
		_update_picked_collision(null)

	if player.HOOK_CHARGES < player.HOOK_STARTING_CHARGES:
		HOOK_RECHARGE_PROGRESS.value = player.HOOK_RECHARGE_TIMER.time_left * 100

		
func _ready():
	menu_ref.hide()
	Store.e.connect(refresh)
	player.health_changed.connect(flash_damage)
	HOOK_RECHARGE_PROGRESS.max_value = player.HOOK_RECHARGE_TIMER.wait_time * 100
	if Store.upnp_host_ip != '':
		host_ip_container.visible = true
		hidden_ip.text = Store.upnp_host_ip
	refresh()
	player.health_changed.connect(update_health)
	HEALTH_BAR.max_value = player.HEALTH_DEFAULT
	HEALTH_BAR.value = player.HEALTH_DEFAULT


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
			player_string += str(player_data[k]) + ' | '

		if player_data.team == "Red":
			redPlayers += player_string + '\n'
		else:
			bluePlayers += player_string + '\n'		
		 

	RED_PLAYERS_LABEL.text = redPlayers
	BLUE_PLAYERS_LABEL.text = bluePlayers

	hooks_count.text = str(player.HOOK_CHARGES)
		
	if player.HOOK_CHARGES == 0:
		HOOK_SPRITE.modulate = Color(0, 0, 0, 0.3)
	else:
		HOOK_SPRITE.modulate = Color(0, 0, 0, 1)
	
func toggle_debug():
	if menu_ref.visible: menu_ref.hide()
	else: menu_ref.show()

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
