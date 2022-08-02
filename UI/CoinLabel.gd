extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var initialCount = 0
export var isOwned = false
export var isPrice = false
var coinsNeeded = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	setCoins(initialCount)
	if isOwned:
		var easing = Anima.EASING.EASE_IN_OUT
		var anima = Anima.begin($TextureRect)
		var dis = 10
		anima.then({property = 'y',to = -dis, duration = 1.25, relative = true, easing = easing })
		anima.then({property = 'y',to = dis, duration = 1.25, relative = true, easing = easing})
		anima.loop(-1)
		anima.play()
	call_deferred('connectUpdate')
	
	pass # Replace with function body.

func connectUpdate():
	if is_instance_valid(Global.player):
		Global.player.connect('needUpdate', self, 'update')
		update()

func setCoins(numCoins):
	$Label.text = str(numCoins)
	if str(numCoins) == 'Free':
		numCoins = 0
	if !isOwned:
		coinsNeeded = numCoins
		
func update():
	if isPrice:
		
		if Global.player.coins < coinsNeeded:
			$Label.modulate = Color(1,0.4,0.4)
		else:
			$Label.modulate = Color(1,1,1)
