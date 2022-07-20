extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal death

var held = false
var player
var state = 'store'
var hp
var attack
var id
var desc
var level = 1
var unitName
var maxHp
var types = []
var hasAttacked = false
var battle
var curTarget = null

onready var tween = $Tween
onready var hpLabel = $HealthRect/HpLabel
onready var attackLabel = $AttackRect/AttackLabel

var scalingUp = true
var baseScale
var animSpeedRand
# Called when the node enters the scene tree for the first time.
func _ready():
	$MoveParticles.emitting = false
	baseScale = $Sprite.scale
	animSpeedRand = Global.rng.randf_range(0.9,1.1)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var xRate = 0.03
	var yRate = 0.07
	var maxDiff = 0.05
	if scalingUp:
		$Sprite.scale.y *= 1 + delta*(yRate * animSpeedRand)
		$Sprite.scale.x *= 1 - delta*(xRate * animSpeedRand)
		if $Sprite.scale.y >= baseScale.y*(1+maxDiff):
			scalingUp = false
	else:
		$Sprite.scale.x *= 1 + delta*(xRate* animSpeedRand)
		$Sprite.scale.y *= 1 - delta*(yRate* animSpeedRand)
		if $Sprite.scale.y <= baseScale.y*(1-maxDiff):
			scalingUp = true
	pass
func render(_id, _level = 1):
	var data = Global.unitLibrary[_id]
	hp = data.hp
	unitName = data.name
	types = data.types
	maxHp = hp
	attack = data.attack
	id = _id
	desc = data.desc
	
	$Sprite.texture = load(str('res://units/sprites/',unitName, '.png'))
	$MoveParticles.texture = $Sprite.texture
	$MoveParticles.scale = $Sprite.scale
	#$Sprite.scale = Vector2(0.25,0.25)
	z_as_relative = false
	z_index +=1
	
	$Type1.texture = load(str('res://types/sprites/', types[0],'.png'))
	$Type2.texture = load(str('res://types/sprites/', types[1],'.png'))
	while (_level > 1):
		levelUp(false)
		_level -= 1
	update()
	

func levelUp(emitParticles = false):
	level+=1
	hp*=2
	maxHp*=2
	
	attack*=2
	$CombineParticles.emitting = true
	$Sprite.scale *= 1.5
	$MoveParticles.scale = $Sprite.scale
	baseScale = $Sprite.scale
	update()
	
	
func update():
	$AttackRect/AttackLabel.text = str(attack)
	$HealthIndicator/HpLabel.text = str(hp)
	
	
	$HealthIndicator.set(hp, maxHp)
	


func setEnemy():
	scale.x *=-1
	$HealthIndicator.set_scale(Vector2($HealthIndicator.get_scale().x*-1, 1))
	#$AttackRect.set_scale(Vector2($AttackRect.get_scale().x*-1,1))
	

	
func randomTarget(enemyArray):
	var rand = Global.rng.randi_range(0,enemyArray.size()-1)
	
	return enemyArray[rand]
	
func attack(enemyArray):
	print(unitName, ' attacking enemy')
	curTarget = randomTarget(enemyArray)
	$MoveParticles.emitting = true
	tweenToAnd(curTarget.global_position, 'attackAction')
	
func attackAction():
	$MoveParticles.emitting = false
	curTarget.takeDamage(attack)
	returnToSpot()
	pass
	
func returnToSpot():
	tweenToAnd(get_parent().get_node('Pos').global_position, 'attackDone')
	
	
func attackDone():
	battle.nextAttack()
	
func takeDamage(amount):
	hp-= amount
	if hp <= 0:
		die()
	update()
		
func die():
	
	emit_signal("death")
	
	if player!= null:
		
		player.unitDie(self)
	else:
		queue_free()
	
func tweenToAnd(pos, afterMethod = ''):
	tween.interpolate_property(self, "global_position",
		global_position, pos, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	if afterMethod != '':
		tween.connect("tween_all_completed", self, afterMethod, [], CONNECT_ONESHOT)
	
	
