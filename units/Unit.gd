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
var level = 0
var tier = 0
var curStats = {}
var lastCurStats = {}
var abilities = {}

var baseStats = {'armor':0, 'regeneration':0, 'maxHp':1}
var needsLabel = ['armor', 'poison', 'regeneration', 'power']
var types = []
var hasAttacked = false

var battle
var attackTarget = null
var abilityTargets = []
var attackFromPos = null

onready var tween = $Tween
#onready var hpLabel = $HealthRect/HpLabel
#onready var attackLabel = $AttackRect/AttackLabel

var actionQueue = []

var scalingUp = true
var baseScale
var animSpeedRand
 
enum battleStates {idle, dieing,reviving, preAction, preAttackMove, preAttackStop, attack, postAttack, waiting, roundEnd}
var battleState = battleStates.idle

var deadPercent = 0
var stopAnimating = false

var preAttackStopTimer = 0

var hasOnAttack = false
var nextState = null

var preppedActionType = ''
var abilityData
var abilityTriggersLeft = 0

var waitTime = 0
var afterWaitMethod = ''
var afterWaitArgs = []


var moveAnim = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	$MoveParticles.emitting = false
	baseScale = $Sprite.scale
	animSpeedRand = Global.rng.randf_range(0.9,1.1)
	$StatLabels.rect_position = $Above.position
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
		if !stopAnimating:
			$Sprite.scale.x *= 1 + delta*(xRate* animSpeedRand)
			$Sprite.scale.y *= 1 - delta*(yRate* animSpeedRand)
			if $Sprite.scale.y <= baseScale.y*(1-maxDiff):
				if deadPercent==0:
					scalingUp = true
				else:
					stopAnimating = true
		
			
	
	var attackFromDisFromTarget = 150
	var moveSpeed = 250
	var bonusSpeed
	if is_instance_valid(attackTarget):
		attackFromPos = Vector2(move_toward(attackTarget.global_position.x,battle.centerPos.x, 80), attackTarget.global_position.y)
		 
	else:
		attackFromPos = null
	animateMovement(delta)
	if waitTime > 0:
		moveAnim = 0
		waitTime -= delta
		if waitTime <= 0: 
			battleState = nextState
			waitTime = 0
			
			if afterWaitMethod!= '':
				#print(id+' calling afterWaitMethod: '+afterWaitMethod + str(afterWaitArgs))
				var methodToCall = afterWaitMethod
				afterWaitMethod = ''
				callv(methodToCall, afterWaitArgs)
				
				afterWaitArgs = []
	

	else:
		if battleState == battleStates.dieing:
			if deadPercent < 1:
				deadPercent+= delta*0.2
			if deadPercent > 1:
				deadPercent = 1
		elif battleState == battleStates.reviving:
			if deadPercent > 0:
				deadPercent-= delta*0.2
			if deadPercent < 0:
				deadPercent = 0
		if battleState == battleStates.dieing || battleState == battleStates.reviving:
			var prop = float(deadPercent)/1
			$Sprite/Ghost.global_position.y = CustomFormulas.proportion($Sprite.global_position.y,$Sprite.global_position.y -200, prop)
			$Sprite/Ghost.modulate.a = CustomFormulas.proportion(0.8, 0, prop)
			$HealthIndicator.modulate.a = $Sprite/Ghost.modulate.a
			$StatLabels.modulate.a = $Sprite/Ghost.modulate.a
			$Type1.modulate.a = $Sprite/Ghost.modulate.a
			$Type2.modulate.a = $Sprite/Ghost.modulate.a
			prop = min(1, prop*2)
			$Sprite.self_modulate = Color(1,1,1).darkened(CustomFormulas.proportion(0, 0.65, prop))
			#$Sprite.scale.y = CustomFormulas.proportion(0, 0.6, prop)
		if battleState == battleStates.preAttackMove:
			if moveAnim == 0:
				moveAnim = 1
			bonusSpeed = global_position.distance_to(attackTarget.global_position)*0.6
			global_position = global_position.move_toward(attackFromPos, delta*(moveSpeed+bonusSpeed))
			if global_position == attackFromPos:
				battleState = battleStates.waiting
				preAttackStopTimer = 0
				
				battle.addToActionStack('attack', [self])
				actionDone()
		if battleState == battleStates.preAttackStop:
			moveAnim = 0
			pass
					
			#battleState = battleStates.attack
		if battleState == battleStates.attack:
			global_position = global_position.move_toward(attackTarget.global_position, delta*moveSpeed)
			if global_position.distance_to(attackTarget.global_position) < attackFromDisFromTarget/3:
				attackAction()
				battleState = battleStates.postAttack
				attackTarget = null
		if battleState == battleStates.postAttack:
			if moveAnim == 0:
				moveAnim = 1
			global_position = global_position.move_toward(get_parent().global_position, delta*moveSpeed*2)
			if global_position == get_parent().global_position:
				battleState = battleStates.idle
				moveAnim = 0
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
		#mergeNewStats()
		$StatLabels.rect_position = $Left.position
		print(getName()+' set battle mode armor: '+str(curStats['armor']))
		hasAttacked = false
	else:
		$StatLabels.rect_position = $Above.position
		#$StatLabels.hide()
		$Type1.show()
		$Type2.show()
		$AttackIndicator.position = $NormalPowerPos.position
	
		resetCurStats()
		updateInfo()
		#mergeNewStats()
		

	
func render(_id, _level = 0):
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
	#baseStats['hp'] = baseStats['maxHp']
	curStats['hp'] = baseStats['maxHp']
	types = data.types
	tier = data.tier
	if data.has('desc'):
		desc = data.desc
	
	
	$Sprite.texture = load(str('res://units/sprites/',id, '.png'))
	$Sprite/Ghost.texture = $Sprite.texture
	$MoveParticles.texture = $Sprite.texture
	#$MoveParticles.scale = $Sprite.scale
	
	#z_as_relative = false
	#z_index +=1
	
	$Type1.texture = load(str('res://types/sprites/', types[0],'.png'))
	$Type2.texture = load(str('res://types/sprites/', types[1],'.png'))
	while (_level > 0):
		levelUp(false)
		_level -= 1
	resetCurStats()
	
	var hbUpdate = {'hp':curStats['hp'], 'armor':curStats.armor, 'poison':curStats.poison}
	hbUpdate['poison'] = curStats['poison']
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp, 'cur')
	for stat in needsLabel:
		var newLabel = load('res://UI/StatLabel.tscn').instance()
		get_node('%StatLabels').add_child(newLabel)
		
		newLabel.name = stat
		newLabel.setAmount(curStats[stat])
	updateInfo()
	setBattleMode(false)
	
func resetCurStats():
	

	for stat in baseStats:
		
	
		curStats[stat] = baseStats[stat]
			
				
		
		
	
func levelUp(emitParticles = false, hpPercent = 0):
	level+=1
	var preHp = curStats.hp
	for stat in baseStats:
		
		baseStats[stat] = baseStats[stat]*2
		
	resetCurStats()
	
	$CombineParticles.emitting = true
	$Sprite.scale *= 1.4
	$MoveParticles.scale = $Sprite.scale
	baseScale = $Sprite.scale
	var hbUpdate = {'hp': preHp}
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp, 'cur')
	heal(floor(float(baseStats['maxHp'] / 2.0)))
	
	updateInfo()
	#curStats['hp'] = baseStats['maxHp']
	
	
	
func fullRestore():
	curStats['hp'] = baseStats['maxHp']
	
	
	
func updateInfo(hpAnimation = 'none'):
	
	#print(id + ' cur hp: '+str(curStats['hp']))
	
	$HealthIndicator.setPower(curStats['power'])
	var hbUpdate = {'hp':curStats['hp'], 'armor':curStats.armor, 'poison':curStats.poison}
	
	hbUpdate['poison'] = curStats['poison']
	
	
	$HealthIndicator.setValues(hbUpdate, curStats.maxHp, 'target')
	
	for stat in curStats:
		if get_node('%StatLabels').has_node(stat):
			get_node('%StatLabels').get_node(stat).setAmount(curStats[stat])
		
			
		
		
		

func addLabel(stat, isChange):
	return
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
	
	#print(getName() +' merging new stats')
	for label in get_node('%StatChangeLabels').get_children():
		
		label.queue_free()
	if is_instance_valid(get_parent()):
		get_parent().unhighlight()
	poisonParticles(0)
	#for stat in curStats:
		
		#lastCurStats[stat] = curStats[stat]
		#if needsLabel.has(stat):
			#addLabel(stat, false)



func setEnemy():
	
	scale.x *=-1
	$MoveParticles.scale.x =1
	$HealthIndicator.set_scale(Vector2($HealthIndicator.get_scale().x*-1, 1))
	$HealthIndicator.flipped = true
	#statChangeLabels.rect_scale.x*=-1
	#statChangeLabels.rect_position.x+=65
	statLabels.rect_scale.x *= -1
	$Left.position.x -= 70
	#statLabels.rect_position.x = 210
	$AttackIndicator.setFlipped()
	isAlly = false
	for label in get_node('%StatLabels').get_children():
		label.flip()
	#$StatusLabels.position.x 
	#$AttackRect.set_scale(Vector2($AttackRect.get_scale().x*-1,1))
	
func waitAnd(time, afterMethod, args = []):
	#print(id+ ' wait and')
	if id == 'skunk':
		pass
	waitTime = time
	#battleState = battleStates.waiting
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
	print('	'+getName()+' prepping '+actionType+' - '+str(data))
	var baseActionWait = 0.9
	match actionType:

		'startattack':
			hasAttacked = true
			attackTarget = randomTarget()
			battle.guardingUnit = attackTarget
			
			get_parent().targetHighlight(attackTarget.get_parent())
			if isAlly:
				$MoveParticles.emitting = true
			battleState = battleStates.preAttackMove
			battle.waitingForActionClick = false
			moveAnim = 1
		'attack':
			
			get_parent().targetHighlight(attackTarget.get_parent())
			battleState = battleStates.attack
		'poison':
			takeDamage(curStats['poison'])
			poisonParticles(curStats['poison'])
			changeStat('poison',-1)
			
			get_parent().highlight(Color(Global.keywords['poison'].color))
			waitAnd(baseActionWait, 'actionDone')
		'regeneration':
			heal(curStats['regeneration'])
			get_parent().highlight(Color(Global.keywords['regeneration'].color))
			waitAnd(baseActionWait, 'actionDone')
		'lunar':
			get_parent().highlight(Color(Global.elementLibrary['lunar'].color))
			var effectLevel = get_parent().get_parent().allyEffects['lunar']
		
			changeStat('power', effectLevel)
			waitAnd(baseActionWait, 'actionDone')
		'ability':
			
			
			abilityTriggersLeft = data.triggers[level]
				
			preppedActionType = actionType
			abilityData = data
			abilityTrigger()
		_:
			print('This action prep isnt working: ' + actionType)
			return
	battle.addWaitingFor(self)
	preppedActionType = actionType
	#preppedActionData = data
	#doAction()
	

func abilityTrigger():
	print('	'+getName()+' triggering ability: '+preppedActionType+', '+str(abilityData))
	var baseActionWait = 0.8
	match preppedActionType:
		
		'ability':
			var abilityTarget
			if abilityData.target == 'guarding':
				abilityTarget = battle.guardingUnit
			elif abilityData.target == 'self':
				abilityTarget = self
			else:
				abilityTarget = randomTarget()
			if abilityData.has('stat'):
				
				
				abilityTarget.changeStat(abilityData.stat, abilityData.amount)
				if abilityData.stat == 'poison':
				
					abilityTarget.poisonParticles(abilityData.amount, true)
			abilityTriggersLeft -= 1
			if abilityTriggersLeft > 0:
				waitAnd(baseActionWait, 'abilityTrigger')
				print('	triggers left: ' +str(abilityTriggersLeft))
			else:
				
				waitAnd(baseActionWait, 'actionDone')
		_:
			print('This do action isnt working: ' + preppedActionType)
			return
	
	

func actionDone():
	
	#get_parent().unhighlight()
	#if attackTarget != null:
		#attackTarget.get_parent().unhighlight()
	#attackTarget = null
	#updateInfo()
	print('	'+getName()+' action done')
	abilityData = null
	preppedActionType = ''
	emit_signal('unitActionDone')
	print('	'+getName()+' actionDone')
	
	
func attackAction():
	var prop = float(curStats['power']) / float(Global.avgStats.power)
	$HitAudio.volume_db = min(-10 + 9*prop, 25)
	
	$HitAudio.play()
	$MoveParticles.emitting = false
	var dmgTaken = attackTarget.takeDamage(curStats['power'])
	var text = getName() + ' attacked '+attackTarget.getName()+' for '+str(curStats['power'])
	text += ' damage'
	if dmgTaken < curStats['power']:
		text += ' (reduced to '+str(dmgTaken)+')'
	
	battle.battleText(text)
	pass

func takeDamage(amount, animation = 'chunk'):
	var damageTaken = amount
	if curStats['armor'] > 0:
		Global.playAudio('armor', -5, 0.06)
		damageTaken -= curStats['armor']
	if damageTaken > 0:
		curStats['hp']-= damageTaken
		if curStats['hp'] <= 0:
			actionDone()
			die()
	updateInfo(animation)
	return damageTaken
	
func heal(amount):
	curStats.hp += amount
	if curStats.hp > curStats.maxHp:
		curStats.hp = curStats.maxHp
	updateInfo()


func die():
	
	battleState = battleStates.dieing
	
	$Sprite/Ghost.show()
	
	deadPercent = 0
	if is_instance_valid(battle):
		if isAlly:
			
			battle.battleText(getName() + ' knocked out!')
			Global.player.unitDie(self)
		else:
			battle.battleText(getName() + ' defeated!')
			hide()
	emit_signal("death")
	



func applyEffect(effectName, amount, target):
	target.changeStat(effectName, amount)
	pass

func changeStat(statName, amount):
	print(id + ' changing ' + statName + ' ' + str(amount))
	
	
	if curStats.has(statName):
		curStats[statName] += amount
	else:
		curStats[statName] = amount
	
	updateInfo()
	pass
	
func recieveModifier():
	pass
	

func animateMovement(delta):
	var animSpeed = 150
	if moveAnim > 0:
		if moveAnim == 1:
			$Sprite.rotation_degrees += delta*animSpeed
			if $Sprite.rotation_degrees >= 4:
				moveAnim = 2
		elif moveAnim == 2:
			$Sprite.rotation_degrees -= delta*animSpeed
			if $Sprite.rotation_degrees <= -4:
				moveAnim = 1
	elif $Sprite.rotation_degrees != 0:
		$Sprite.rotation_degrees = move_toward($Sprite.rotation_degrees, 0, delta*animSpeed)
	
	
		
func poisonParticles(amount, persistant = true):
	
	if amount == 0:
		$PoisonParticles.emitting = false
		return
	var poisonProp = float(amount) / baseStats['maxHp']

	$PoisonParticles.amount = CustomFormulas.proportion(20, 150, poisonProp)
	$PoisonParticles.emitting = true
		
func getName():
	var result = ''
	if isAlly:
		result += 'ally '
	else:
		result += 'enemy '
	result += id 
	
	return result
