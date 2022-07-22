extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var playerScene = preload('res://Player.tscn')
var players = []
var roundNum = 0
var battleOffset = 1

export var debug = false
# Called when the node enters the scene tree for the first time.
func _ready():
	Global.game = self
	$StartMenu.connect('started', self, 'start')
	start()
	pass # Replace with function body.
	
func start():
	$StartMenu.hide()
	var newPlayer = playerScene.instance()
	
	
	add_child(newPlayer)
	Global.player = newPlayer

func startOld(var numPlayers):
	$StartMenu.hide()
	print('starting game. adding ',numPlayers,' players: ')
	for i in range(numPlayers):
		var newPlayer = playerScene.instance()
		add_child(newPlayer)
		newPlayer.rect_global_position.x = i*1500
		players.append(newPlayer)
		if i == 0:
			newPlayer.name = 'User'
			newPlayer.isUser = true
			newPlayer.get_node("Camera2D").current = true
			Global.player = newPlayer
		else:
			newPlayer.name = 'Bot'+str(i)
		newPlayer.update()
		newPlayer.game = self
		print(newPlayer.name)
	
		
func nextRound():
	roundNum+=1
	print('ROUND ',roundNum)
	if battleOffset >= players.size():
		battleOffset = 1
	var i = 0
	for player in players:
		if i+battleOffset>=players.size():
			i -= players.size()
		player.battleAgainst(players[i+battleOffset])
		i+=1
	battleOffset+=1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_key_input(event):
	if event.pressed && event.scancode == KEY_1:
		players[0].cam.current = true
	if event.pressed && event.scancode == KEY_2:
		players[1].cam.current = true
	if event.pressed && event.scancode == KEY_3:
		players[2].cam.current = true
	if event.pressed && event.scancode == KEY_4:
		players[3].cam.current = true
