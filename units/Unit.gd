extends Node2D
class_name Unit

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var battleStatusLabelScene = preload('res://UI/BattleStatusLabel.tscn')
onready var statusLabels = $StatusLabels/StatusLabels
signal death
signal unitActionDone

var held = false
var player
var state = 'store'
var isAlly = true


var id
var desc
var level = 1
var tier = 0
var curStats = {}
var baseStats = {'armor':0, 'regeneration':0, 'maxHp':1}

var types = []
var hasAttacked = false
var hasDoneRoundEnd = false
var battle
var curTarget = null
var attackFromPos = null

onready var tween = $Tween
#onready var hpLabel = $HealthRect/HpLabel
#onready var attackLabel = $AttackRect/AttackLabel

var actionQueue = []

var scalingUp = true
var baseScale
var animSpeedRand
 
enum battleStates {idle, preAction, preAttackMove, preAttackStop, attack, postAttack, waiting, roundEnd}
var battleState = battleStates.idle

var preAttackStopTimer = 0

var hasOnAttack = false
var nextState = null
var nextAction = ''


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
			
	
	var attackFromDisFromTarget = 150
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
			if global_position.distance_to(curTarget.global_position) < attackFromDisFromTarget/3:
				attackAction()
				battleState = battleStates.postAttack
				curTarget = null
		if battleState == battleStates.postAttack:
			global_position = global_position.move_toward(get_parent().global_position, delta*moveSpeed*2)
			if global_position == get_parent().global_position:
				battleState = battleStates.idle
				
				actionDone()
		
	update()
	pass
	
func changeBattleState(newState):
	battleState = newState
	
func setBattleMode(value):
	if value == true:
		get_parent().unhighlight()
		$Type1.hide()
		$Type2.hide()
		$AttackIndicator.position = $BattlePowerPos.position
	else:
		$Type1.show()
		$Type2.show()
		$AttackIndicator.position = $NormalPowerPos.position
		statuses = {}
		resetCurStats()
		updateInfo()
		

	
func render(_id, _level = 1):
	id = _id
	var data = Global.unitLibrary[_id]
	
	for stat in data.baseStats:
		#print(str(id,' setting ', stat, ' to ', data.baseStats[stat]))
		baseStats[stat] = data.baseStats[stat]
		
	curStats['hp'] = baseStats['maxHp']
	types = data.types
	tier = data.tier
	
	desc = data.desc
	
	
	$Sprite.texture = load(str('res://units/sprites/',id, '.png'))
	
	$MoveParticles.texture = $Sprite.texture
	#$MoveParticles.scale = $Sprite.scale
	
	z_as_relative = false
	z_index +=1
	
	$Type1.texture = load(str('res://types/sprites/', types[0],'.png'))
	$Type2.texture = load(str('res://types/sprites/', types[1],'.png'))
	while (_level > 1):
		levelUp(false)
		_level -= 1
	resetCurStats()
	updateInfo()
	
func resetCurStats():
	for stat in baseStats:
		if baseStats.has(stat):
			curStats[stat] = baseStats[stat]
		else:
			curStats[stat] = 0
	
func _draw():
	if curTarget != null:
		var mult
		if !isAlly:
			mult = -1
		
	pass
	
func levelUp(emitParticles = false, hpMissing = 0):
	level+=1
	for stat in baseStats:
		baseStats[stat] = baseStats[stat]*2
	
	resetCurStats()
	
	$CombineParticles.emitting = true
	$Sprite.scale *= 1.5
	$MoveParticles.scale = $Sprite.scale
	baseScale = $Sprite.scale
	curStats.hp = baseStats.maxHp
	updateInfo()
	
	
func updateInfo(hpAnimation = 'none'):
	
	#print(id + ' cur power: '+str(curStats['power']))
	
	$HealthIndicator.setPower(curStats['power'])
	var hbUpdate = {'hp':curStats['hp'], 'armor':curStats.armor}
	if statuses.has('poison'):
		hbUpdate['poison'] = statuses['poison']
	else:
		hbUpdate['poison'] = 0
	
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp)
	
	for status in statuses:
		var labelNode
		if !is_instance_valid(statusLabels.get_node(status)):
			var newLabel = battleStatusLabelScene.instance()
			statusLabels.add_child(newLabel)
			newLabel.name = status
			if Global.keywords[status].has('color'):
				newLabel.modulate = Global.keywords[status].color
			elif Global.elementLibrary[status].has('color'):
				newLabel.modulate = Global.elementLibrary[status].color
			labelNode = newLabel
		else:
			labelNode = statusLabels.get_node(status)
		if curStats.has(status):
			labelNode.text = str(status, ' +', statuses[status])
		else:
			labelNode.text = str(status, ' ', statuses[status])
		if statuses[status] == 0:
			labelNode.hide()
	
		


func setEnemy():
	
	scale.x *=-1
	$MoveParticles.scale.x =1
	$HealthIndicator.set_scale(Vector2($HealthIndicator.get_scale().x*-1, 1))
	$HealthIndicator.flipped = true
	$StatusLabels.scale.x*=-1
	$StatusLabels.global_position.x += 40* abs(scale.x)
	$AttackIndicator.setFlipped()
	isAlly = false
	#$StatusLabels.position.x 
	#$AttackRect.set_scale(Vector2($AttackRect.get_scale().x*-1,1))
	
func waitAnd(time, afterMethod, args = []):
	#print(id+ ' wait and')
	waitTime = time
	battleState = battleStates.waiting
	afterWaitMethod = afterMethod
	afterWaitArgs = args
	
	
func randomTarget():
	var enemyArray = getEnemies()
	var rand = Global.rng.randi_range(0,enemyArray.size()-1)
	
	return enemyArray[rand]
	
func getEnemies():
	if isAlly:
		return battle.enemies
	else:
		return battle.allies
	
func preAction(actionType):
	
	print('	'+id+ ' PRE prepping action: '+actionType)
	
	
	match actionType:
		'attack':
			curTarget = randomTarget()
			get_parent().highlight()
			get_parent().targetHighlight(curTarget.get_parent())
			
			
		'poison':
			if !statuses.has('poison'):
				
				return
			if statuses['poison'] <= 0:
				
				return
			get_parent().highlight(Color(Global.keywords.poison.color))
		_:
			return
			
	nextAction = actionType
	battleState = battleStates.preAction
	print('	'+id+ ' prepping action: '+actionType)
	battle.addActionTaker(self)
		
	
func startAction():
	print('	'+id +' starting nextAction '+ nextAction)
	if nextAction == 'attack':
		
		if isAlly:
			$MoveParticles.emitting = true
		battleState = battleStates.preAttackMove
	if nextAction == 'poison':
		takeDamage(statuses['poison'], 'poison')
		statuses['poison'] -= 1
			
		updatePoisonParticles()
		waitAnd(1, 'actionDone')
	nextAction = ''
		
func actionDone():
	
	get_parent().unhighlight()
	if curTarget != null:
		curTarget.get_parent().unhighlight()
	curTarget = null
	
	emit_signal('unitActionDone')
	print('	'+id+' actionDone')
	
	
func attackAction():
	var prop = float(curStats['power']) / float(Global.avgStats.power)
	$HitAudio.volume_db = min(-10 + 9*prop, 25)
	
	$HitAudio.play()
	$MoveParticles.emitting = false
	curTarget.takeDamage(curStats['power'])
	
	pass


	


	
	
func takeDamage(amount, animation = 'chunk'):
	if curStats['armor'] > 0:
		Global.playAudio('armor', -5, 0.06)
		amount -= curStats['armor']
	curStats['hp']-= amount
	if curStats['hp'] <= 0:
		die()
	updateInfo(animation)
	



func die():
	
	emit_signal("death")
	
	if player!= null:
		
		player.unitDie(self)
	else:
		hide()
	
func onAttack():
	
	pass
	



	
func applyEffect(effectName, amount, target):
	target.recieveEffect(effectName, amount)
	pass

func recieveEffect(effectName, amount):
	#print(id + 'recieving ' + effectName)
	
		
	if curStats.has(effectName):
		curStats[effectName]+=amount
	
	if statuses.has(effectName):
		statuses[effectName] += amount
	else:
		statuses[effectName] = amount
	if effectName == 'poison':
		updatePoisonParticles()
	
	updateInfo()
	pass
	
func recieveModifier():
	pass
	
func updatePoisonParticles(alwaysShowMain = false):
	var poisonProp = 0
	if !statuses.has('poison'):
		poisonProp = 0
	else:
		poisonProp = float(statuses['poison']) / baseStats['maxHp']
	$PoisonParticles.amount = CustomFormulas.proportion(10, 40, poisonProp)
	$PoisonParticles.emitting = true
	if statuses.has('poison'):
		
		$PersistantPoisonParticles.amount = CustomFormulas.proportion(1, 5, poisonProp)
		
		$PersistantPoisonParticles.emitting = true
		
	else:
		$PersistantPoisonParticles.emitting = false
		

