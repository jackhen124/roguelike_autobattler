extends Node2D
class_name Unit

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
var hasDoneRoundEnd = false
var battle
var curTarget = null
var attackFromPos = null

onready var tween = $Tween
onready var hpLabel = $HealthRect/HpLabel
onready var attackLabel = $AttackRect/AttackLabel

var actionQueue = []

var scalingUp = true
var baseScale
var animSpeedRand
 
enum battleStates {idle, preAttackMove, preAttackStop, attack, postAttack, waiting, roundEnd}
var battleState = battleStates.idle

var preAttackStopTimer = 0

var hasOnAttack = false
var nextState = null

var waitTime = 0
var afterWaitMethod = ''
var afterWaitArgs = []

var statuses = {}
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
			
	
	var attackFromDisFromTarget = 100
	var moveSpeed = 250
	var bonusSpeed
	if is_instance_valid(curTarget):
		attackFromPos = Vector2(move_toward(curTarget.global_position.x,battle.centerPos.x, 80), curTarget.global_position.y)
		
	else:
		attackFromPos = null
	if battleState == battleStates.waiting:
		waitTime -= delta
		if waitTime <= 0: 
			battleState = nextState
			waitTime = 0
			if afterWaitMethod!= '':
				#print(id+' calling afterWaitMethod: '+afterWaitMethod + str(afterWaitArgs))
				callv(afterWaitMethod, afterWaitArgs)
				afterWaitMethod = ''
				afterWaitArgs = []
	else:
		if battleState == battleStates.preAttackMove:
			bonusSpeed = global_position.distance_to(curTarget.global_position)*0.6
			global_position = global_position.move_toward(attackFromPos, delta*(moveSpeed+bonusSpeed))
			if global_position == attackFromPos:
				battleState = battleStates.preAttackStop
				preAttackStopTimer = 0
		if battleState == battleStates.preAttackStop:
			preAttackStopTimer+=delta
			if preAttackStopTimer >= 0.25:
				if hasOnAttack:
					waitAnd(0.5, 'changeBattleState', [battleStates.attack])
					onAttack()
				else:
					
					battleState = battleStates.attack
		if battleState == battleStates.attack:
			global_position = global_position.move_toward(curTarget.global_position, delta*moveSpeed)
			if global_position.distance_to(curTarget.global_position) < attackFromDisFromTarget/2:
				attackAction()
				battleState = battleStates.postAttack
				curTarget = null
		if battleState == battleStates.postAttack:
			global_position = global_position.move_toward(get_parent().global_position, delta*moveSpeed*2)
			if global_position == get_parent().global_position:
				battleState = battleStates.idle
				turnDone()
		
	update()
	pass
	
func changeBattleState(newState):
	battleState = newState
	
	
func render(_id, _level = 1):
	var data = Global.unitLibrary[_id]
	hp = data.hp
	unitName = _id
	types = data.types
	maxHp = hp
	attack = data.attack
	id = _id
	desc = data.desc
	
	$Sprite.texture = load(str('res://units/sprites/',unitName, '.png'))
	$MoveParticles.texture = $Sprite.texture
	#$MoveParticles.scale = $Sprite.scale
	
	z_as_relative = false
	z_index +=1
	
	$Type1.texture = load(str('res://types/sprites/', types[0],'.png'))
	$Type2.texture = load(str('res://types/sprites/', types[1],'.png'))
	while (_level > 1):
		levelUp(false)
		_level -= 1
	updateInfo()
	
func _draw():
	if attackFromPos != null:
		draw_line(Vector2(0,0), attackFromPos - global_position, Color(1,0.5,0.5), 3)

func levelUp(emitParticles = false):
	level+=1
	hp*=2
	maxHp*=2
	
	attack*=2
	$CombineParticles.emitting = true
	$Sprite.scale *= 1.5
	$MoveParticles.scale = $Sprite.scale
	baseScale = $Sprite.scale
	updateInfo()
	
	
func updateInfo():
	$AttackRect/AttackLabel.text = str(attack)
	$HealthIndicator/HpLabel.text = str(hp)
	
	
	$HealthIndicator.setHp(hp, maxHp)
	


func setEnemy():
	scale.x *=-1
	$MoveParticles.scale.x =1
	$HealthIndicator.set_scale(Vector2($HealthIndicator.get_scale().x*-1, 1))
	#$AttackRect.set_scale(Vector2($AttackRect.get_scale().x*-1,1))
	
func waitAnd(time, afterMethod, args = []):
	
	waitTime = time
	battleState = battleStates.waiting
	afterWaitMethod = afterMethod
	afterWaitArgs = args
	
	
func randomTarget(enemyArray):
	var rand = Global.rng.randi_range(0,enemyArray.size()-1)
	
	return enemyArray[rand]
	
func attack(enemyArray):
	print(unitName, ' attacking enemy')
	curTarget = randomTarget(enemyArray)
	$MoveParticles.emitting = true
	battleState = battleStates.preAttackMove
	
func attackAction():
	$MoveParticles.emitting = false
	curTarget.takeDamage(attack)
	
	pass

func turnDone():
	
	if battle.waitingOnUnit:
		print(id, ' turn done, next action!!!')
		battle.nextAction()
	else: 
		print(id, ' tried to call next action battle is not waiting!!!')


	
	
func takeDamage(amount):
	hp-= amount
	if hp <= 0:
		die()
	updateInfo()
		
func die():
	
	emit_signal("death")
	
	if player!= null:
		
		player.unitDie(self)
	else:
		queue_free()
	
func onAttack():
	
	pass
	
func roundEnd():
	if statuses.has('poison'):
		actionQueue.append('poison')
		
		
	executeRoundEndActionQueue()
	
func executeRoundEndActionQueue():
	if actionQueue.size() == 0:
		print(id+' no actions in queue')
		turnDone()
	else:
		print(str(id,' executing action queue: ',actionQueue))
		var actionWait = 0.5
		if actionQueue[0] == 'poison':
			takeDamage(statuses['poison'])
			statuses['poison'] -= 1
			if statuses['poison'] <= 0:
				statuses.erase('poison')
			updatePoisonParticles()
		actionQueue.remove(0)
		
		waitAnd(actionWait, 'executeRoundEndActionQueue')
	pass
	
func applyEffect(effectName, amount, target):
	target.recieveEffect(effectName, amount)
	pass

func recieveEffect(effectName, amount):
	if statuses.has(effectName):
		statuses[effectName] += amount
	else:
		statuses[effectName] = amount
	if effectName == 'poison':
		updatePoisonParticles()
		
	pass
	
func updatePoisonParticles():
	if statuses.has('poison'):
		var poisonProp = float(statuses['poison']) / maxHp
		$PersistantPoisonParticles.amount = CustomFormulas.proportion(1, 5, poisonProp)
		$PoisonParticles.amount = CustomFormulas.proportion(10, 40, poisonProp)
		$PersistantPoisonParticles.emitting = true
		$PoisonParticles.emitting = true
	else:
		$PersistantPoisonParticles.emitting = false
