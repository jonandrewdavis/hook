extends Node

@export var score = 0
@export var peer_list = []

@onready var menu_ref = $CanvasLayer/SettingsMenu
@onready var players_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Players
@onready var score_label = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/Score
@onready var host_ip_container = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer
@onready var hidden_ip = $CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP

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


func _unhandled_input(_event):
	if Input.is_action_just_pressed("esc") or Input.is_action_just_pressed("tab"):
		menu_ref.visible = !menu_ref.visible

func _on_host_ip_button_toggled(toggled_on):
	$CanvasLayer/SettingsMenu/Panel/MarginContainer/VBoxContainer/HostIPContainer/HiddenIP.visible = toggled_on
