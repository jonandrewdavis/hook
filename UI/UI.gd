extends Node

@export var score = 0
@export var peer_list = []

# TODO: Make unique and use %, combine with debug, or use one or the other.
@onready var menu_ref = $CanvasLayer/SettingsMenu
@onready var players_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Players
@onready var score_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Score
@onready var host_ip_container = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer
@onready var hidden_ip = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP

var player: Player

func _ready():
	menu_ref.hide()
	Store.e.connect(refresh)
	if Store.upnp_host_ip != '':
		host_ip_container.visible = true
		hidden_ip.text = Store.upnp_host_ip

func refresh():
	score_label.text = str(Store.store.score)
	var completePlayers = ""
	for id in Store.store.players: 
		var single = ""
		for k in Store.store.players[id]:
			single += k + ': ' + str(Store.store.players[id][k]) + ', '
		completePlayers += single + '\n'
	players_label.text = completePlayers
	
func toggle_debug():
	if menu_ref.visible: menu_ref.hide()
	else: menu_ref.show()

func _on_host_ip_button_toggled(toggled_on):
	$CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP.visible = toggled_on
