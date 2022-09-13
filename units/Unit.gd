extends Node2D
class_name Unit

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var battleStatusLabelScene = preload('res://UI/BattleStatusLabel.tscn')

signal death
signal unitActionDone

onready var statChangeLabels = get_node('%StatChangeLabels')
onready var statLabels = get_node('%StatLabels')

var held = false

var state = 'store'
var isAlly = true


var id
var desc
var level = 1
var tier = 0
var curStats = {}
var lastCurStats = {}
var abilities = {}

var baseStats = {'armor':0, 'regeneration':0, 'maxHp':1}
var needsLabel = ['armor', 'poison', 'regeneration']
var types = []
var hasAttacked = false

var battle
var attackTarget = null
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

var preppedActionType = ''
var preppedActionData


var waitTime = 0
var afterWaitMethod = ''
var afterWaitArgs = []


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
	if is_instance_valid(attackTarget):
		attackFromPos = Vector2(move_toward(attackTarget.global_position.x,battle.centerPos.x, 80), attackTarget.global_position.y)
		
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
			bonusSpeed = global_position.distance_to(attackTarget.global_position)*0.6
			global_position = global_position.move_toward(attackFromPos, delta*(moveSpeed+bonusSpeed))
			if global_position == attackFromPos:
				battleState = battleStates.waiting
				preAttackStopTimer = 0
				
				battle.addToActionStack('attack', [self])
				actionDone()
		if battleState == battleStates.preAttackStop:
			
			pass
					
			#battleState = battleStates.attack
		if battleState == battleStates.attack:
			global_position = global_position.move_toward(attackTarget.global_position, delta*moveSpeed)
			if global_position.distance_to(attackTarget.global_position) < attackFromDisFromTarget/3:
				attackAction()
				battleState = battleStates.postAttack
				attackTarget = null
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
		mergeNewStats()
		$StatLabels.show()
	else:
		$StatLabels.hide()
		$Type1.show()
		$Type2.show()
		$AttackIndicator.position = $NormalPowerPos.position
	
		resetCurStats()
		updateInfo()
		mergeNewStats()
		

	
func render(_id, _level = 1):
	id = _id
	var data = Global.unitLibrary[_id]
	for abilityTrigger in data.abilities:
		abilities[abilityTrigger] = []
		for x in data.abilities[abilityTrigger]:
			abilities[abilityTrigger].append(x)
	for stat in data.baseStats:
		#print(str(id,' setting ', stat, ' to ', data.baseStats[stat]))
		baseStats[stat] = data.baseStats[stat]
	for stat in Global.possibleStats:
		if !baseStats.has(stat):
			baseStats[stat] = 0
	baseStats['hp'] = baseStats['maxHp']
	curStats['hp'] = baseStats['maxHp']
	types = data.types
	tier = data.tier
	
	desc = data.desc
	
	
	$Sprite.texture = load(str('res://units/sprites/',id, '.png'))
	
	$MoveParticles.texture = $Sprite.texture
	#$MoveParticles.scale = $Sprite.scale
	
	#z_as_relative = false
	#z_index +=1
	
	$Type1.texture = load(str('res://types/sprites/', types[0],'.png'))
	$Type2.texture = load(str('res://types/sprites/', types[1],'.png'))
	while (_level > 1):
		levelUp(false)
		_level -= 1
	resetCurStats()
	
	var hbUpdate = {'hp':curStats['hp'], 'armor':curStats.armor, 'poison':curStats.poison}
	hbUpdate['poison'] = curStats['poison']
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp, 'cur')
	
	updateInfo()
	setBattleMode(false)
	
func resetCurStats():
	#for label in get_node('%StatChangeLabels').get_children():
		#label.queue_free()
	
	for stat in baseStats:
		
		if stat != 'hp':
			if baseStats.has(stat):
				curStats[stat] = baseStats[stat]
			else:
				curStats[stat] = 0
		lastCurStats[stat] = curStats[stat]
		if needsLabel.has(stat) && curStats[stat] != 0:
			
			addLabel(stat, false)
		
	
	
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
	
func fullRestore():
	curStats['hp'] = baseStats['maxHp']
	
	
	
func updateInfo(hpAnimation = 'none'):
	
	#print(id + ' cur power: '+str(curStats['power']))
	
	$HealthIndicator.setPower(curStats['power'])
	var hbUpdate = {'hp':curStats['hp'], 'armor':curStats.armor, 'poison':curStats.poison}
	
	hbUpdate['poison'] = curStats['poison']
	
	
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp, 'target')
	
	for stat in curStats:
		
		if curStats[stat] == lastCurStats[stat]:
			
			continue
		else:
			addLabel(stat, true)
		

func addLabel(stat, isChange):
	#print(id + ' ' +stat+ ' label')
	var parentNode
	var labelNode
	
	if isChange:
		parentNode = get_node('%StatChangeLabels')
	else:
		parentNode = get_node('%StatLabels')
	
	if !parentNode.has_node(stat):
		if !isChange && curStats[stat] == 0:
			return
		
		var newLabel = battleStatusLabelScene.instance()
		parentNode.add_child(newLabel)
		parentNode.move_child(newLabel, 0)
		newLabel.name = stat
		
		labelNode = newLabel
	else:
		labelNode = parentNode.get_node(stat)
		if isChange:
			if curStats[stat] == labelNode.curAmount:
				return
		
		if !isChange && curStats[stat] == 0:
			labelNode.hide()
			return
	var amount = curStats[stat] - lastCurStats[stat] 
	if !isChange:
		amount = curStats[stat]
	
	labelNode.render(stat, amount, isChange)
		
func mergeNewStats():
	
	for label in get_node('%StatChangeLabels').get_children():
		
		label.hide()
		
	for stat in curStats:
		
		lastCurStats[stat] = curStats[stat]
		if needsLabel.has(stat):
			addLabel(stat, false)



func setEnemy():
	
	scale.x *=-1
	$MoveParticles.scale.x =1
	$HealthIndicator.set_scale(Vector2($HealthIndicator.get_scale().x*-1, 1))
	$HealthIndicator.flipped = true
	statChangeLabels.rect_scale.x*=-1
	statChangeLabels.rect_position.x+=65
	statLabels.rect_scale.x *= -1
	statLabels.rect_position.x = -210
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
		
func preAction(actionType, data = null):
	match actionType:
		'startattack':
			attackTarget = randomTarget()
			get_parent().highlight()
			get_parent().targetHighlight(attackTarget.get_parent())
			if isAlly:
				$MoveParticles.emitting = true
			battleState = battleStates.preAttackMove
		'attack':
			get_parent().highlight()
			get_parent().targetHighlight(attackTarget.get_parent())
			
		_:
			print('This action prep isnt working: ' + actionType)
			return
	battle.addWaitingFor(self)
	preppedActionType = actionType
	preppedActionData = data
	
	
func doAction():
	match preppedActionType:
		'attack':
			battleState = battleStates.attack
		'poison':
			takeDamage(curStats['poison'], 'poison')
			curStats['poison'] -= 1
				
			updatePoisonParticles()
			waitAnd(1, 'actionDone')
		'regeneration':
			heal(curStats['regeneration'])
			waitAnd(1, 'actionDone')
	
		_:
			print('This do action isnt working: ' + preppedActionType)
			return
	preppedActionData = null
	preppedActionType = ''
	#battle.addWaitingFor(self)
		

	
		
	



func actionDone():
	
	get_parent().unhighlight()
	#if attackTarget != null:
		#attackTarget.get_parent().unhighlight()
	#attackTarget = null
	#updateInfo()
	emit_signal('unitActionDone')
	print('	'+id+' actionDone')
	
	
func attackAction():
	var prop = float(curStats['power']) / float(Global.avgStats.power)
	$HitAudio.volume_db = min(-10 + 9*prop, 25)
	
	$HitAudio.play()
	$MoveParticles.emitting = false
	attackTarget.takeDamage(curStats['power'])
	
	pass

func takeDamage(amount, animation = 'chunk'):
	if curStats['armor'] > 0:
		Global.playAudio('armor', -5, 0.06)
		amount -= curStats['armor']
	curStats['hp']-= amount
	if curStats['hp'] <= 0:
		die()
	updateInfo(animation)
	
func heal(amount):
	curStats.hp += amount
	if curStats.hp > curStats.maxHp:
		curStats.hp = curStats.maxHp
	updateInfo()


func die():
	
	emit_signal("death")
	
	if isAlly:
		
		Global.player.unitDie(self)
	else:
		hide()
	
func onAttack():
	#for onAttack in abilities['on-attack']:
		
	pass
	



func applyEffect(effectName, amount, target):
	target.changeStat(effectName, amount)
	pass

func changeStat(statName, amount):
	print(id + ' changing ' + statName + ' ' + str(amount))
	
	
	if curStats.has(statName):
		curStats[statName] += amount
	else:
		curStats[statName] = amount
	if statName == 'poison':
		updatePoisonParticles()
	
	updateInfo()
	pass
	
func recieveModifier():
	pass
	
func updatePoisonParticles(alwaysShowMain = false):
	var poisonProp = 0
	if !curStats.poison <= 0:
		poisonProp = 0
	else:
		poisonProp = float(curStats['poison']) / baseStats['maxHp']
	$PoisonParticles.amount = CustomFormulas.proportion(10, 40, poisonProp)
	$PoisonParticles.emitting = true
	if curStats.poison <= 0:
		
		$PersistantPoisonParticles.amount = CustomFormulas.proportion(1, 5, poisonProp)
		
		$PersistantPoisonParticles.emitting = true
		
	else:
		$PersistantPoisonParticles.emitting = false
		
func getName():
	var result = ''
	if isAlly:
		result += 'ally '
	else:
		result += 'enemy '
	result += id + '-'
	result += str(get_parent().get_position_in_parent())
	return result
