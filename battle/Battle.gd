extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var debugEnemy = 'skunk'
export var debugEnemyCount = 1
signal doPreppedAction

signal mergeStatuses

var allies = []
var enemies = []
var allyModifiers = {}
var enemyModifiers = {}
var allyTurn = true
var attackIndex = 0
onready var tween = $Tween
var alliesDone
var enemiesDone
var roundNum = 1

var allySpots
var battleOver = false
var averageHp = 5
var centerPos = Vector2(0,0)
onready var enemiesStartPos = $EnemySpots.global_position
onready var victoryScreen = $CanvasLayer/VictoryScreen
onready var collectButtons = $CanvasLayer/VictoryScreen/VBoxContainer
var victoryAnima
enum states {intro, battleStart, movingTogether, attack, roundEnd}
var state = states.intro
var lastState

var guardingUnit = null
var waitingForActionClick = false
var autoActionClick = false

var waitTime = 0
var afterWaitMethod = ''
var afterWaitArgs = []

var waitingFor = []
var bodies = []

var playerVictory = false

var lootItems = []
var lootCollected = 0

var actionStack = []

const roundEndOrder = ['lunar', 'regeneration','unitRoundEndAbilities', 'poison']
var roundEndIndex = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	addLoot('coins', 5)
	$CanvasLayer.hide()
	$CanvasLayer/PrebattleChoice.hide()
	$CanvasLayer/VictoryScreen.hide()
	$CanvasLayer/Intro.hide()
	$CanvasLayer/RoundLabel.hide()
	victoryAnima = Anima.begin(victoryScreen)
	victoryAnima.then({animation = 'bouncing_in_down', duration = 2, easing = Anima.EASING.EASE_IN_OUT})
	#victoryAnima.then({animation = 'zoom_in_down', duration = 2, sing = Anima.EASING.EASE_OUT_BOUNCE})
	#victoryAnima.then({from = -700, to = -400, property = 'y', duration = 2, sing = Anima.EASING.EASE_OUT_BOUNCE})
	victoryAnima.set_visibility_strategy(Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT)
	
	
	if Global.player.autoplay:
		$CanvasLayer/Autoplay.pressed = true
	else:
		$CanvasLayer/Autoplay.pressed = false
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if waitTime > 0:
		waitTime -= delta
		if waitTime <= 0: 
			
			waitTime = 0
			if afterWaitMethod!= '':
				#print(id+' calling afterWaitMethod: '+afterWaitMethod + str(afterWaitArgs))
				callv(afterWaitMethod, afterWaitArgs)
				afterWaitMethod = ''
				afterWaitArgs = []
	if state == states.movingTogether:
		$EnemySpots.global_position = $EnemySpots.global_position.move_toward(allySpots.global_position, delta*500)
		allySpots.global_position = allySpots.global_position.move_toward($EnemySpots.global_position, delta*500)
		if allySpots.global_position.distance_to($EnemySpots.global_position) < 275:
			nextState()
	pass
	
func debug():
	$TestAllySpots.percentVertical = 1
	$TestAllySpots.global_position = $AlliesPos.global_position
	$EnemySpots.percentVertical = 1
	$EnemySpots.updatePositions()
	$TestAllySpots.global_position = $EnemiesPos.global_position
	$TestAllySpots.updatePositions()
	

func render(stageNum):
	
	
	generateEnemies(stageNum)
	var biomeIndex = (float(stageNum-1) / float(Global.stagesPerBiome))
	print('biomeIndex: '+str(biomeIndex))
	biomeIndex = floor(biomeIndex)
	var curBiome = Global.biomeOrder[biomeIndex]
	if Global.elementLibrary.has(curBiome):
		$ColorRect.show()
		$ColorRect.modulate = Color(Global.elementLibrary[curBiome].color)
	else:
		$ColorRect.hide()
	pass
	
func start(allyUnitArray):
	$CanvasLayer.show()
	allies = allyUnitArray
	for ally in allies:
		ally.battle = self
		ally.connect('death', self, 'removeAlly', [ally])
		ally.connect('unitActionDone', self, 'unitActionDone', [ally])
		
		connect('mergeStatuses', ally, 'mergeNewStats')
		
		ally.setBattleMode(true)
		
		ally.updateInfo()
		
		
		pass
	for enemy in enemies:
		enemy.battle = self
		enemy.setBattleMode(true)
		enemy.connect('death', self, 'removeEnemy', [enemy])
		enemy.connect('unitActionDone', self, 'unitActionDone', [enemy])
		connect('mergeStatuses', enemy, 'mergeNewStats')
		
		enemy.updateInfo()
		
		pass
	
	var diff = $AlliesPos.global_position - $EnemiesPos.global_position
	
	centerPos = $EnemiesPos.global_position.move_toward($AlliesPos.global_position, float($EnemiesPos.global_position.distance_to($AlliesPos.global_position))/2.0)

	var allUnits = [allies,enemies]
	Global.updateAverageStats(allUnits)
	intro()
	
	#nextAction()
func intro():
	var introAnima = Anima.begin($CanvasLayer/Intro)
	introAnima.then({property = 'opacity', duration = 0.5, to = 1, easing = Anima.EASING.EASE_IN_OUT})
	introAnima.then({property = 'opacity', duration = 0.5, to = 0,from=1, easing = Anima.EASING.EASE_IN_OUT,on_completed = [funcref(self, 'onIntroCompleted')]})
	#introAnima.then({animation = 'fade_out', duration = 1.5, easing = Anima.EASING.EASE_IN_OUT})
	
	introAnima.set_visibility_strategy(Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT)
	introAnima.play()
	

func onIntroCompleted():
	$EnemySpots.show()
	$CanvasLayer/PrebattleChoice.generateChoice(Global.player.stageNum)
	$CanvasLayer/PrebattleChoice.show()
	Global.player.lineupVertical = true
	
func battleText(text):
	var sep = 24
	var newDesc = load('res://UI/description.tscn').instance()
	newDesc.generateDesc(text)
	get_node('%BattleLog').add_child(newDesc)
	newDesc.modulate.a = 0
	newDesc.rect_position.y -= sep
	for child in get_node('%BattleLog').get_children():
		var tweenTime = 0.8
		var tween = child.get_node('Tween')
		tween.interpolate_property(child, "rect_position:y",
		child.rect_position.y, child.rect_position.y+sep, tweenTime,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		if child == newDesc:
			tween.interpolate_property(child, "modulate:a",
			0, 1, tweenTime,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		else:
			
			tween.interpolate_property(child, "modulate:a",
			child.modulate.a, child.modulate.a - 0.17, tweenTime,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			if child.modulate.a <= 0:
				child.queue_free()
		tween.start()
			
	

func addToActionStack(type, actionTakers=null,  data = null):
	if type == 'lunar':
		var lunarTeams = []
		if allySpots.allyEffects.has('lunar'):
			lunarTeams += allies
		if $EnemySpots.allyEffects.has('lunar'):
			lunarTeams += enemies
		if lunarTeams.size() > 0:
			actionTakers = lunarTeams
		else:
			return
			
	if type == 'attack':
		if actionTakers[0].abilities.has('on-attack'):
			for ability in actionTakers[0].abilities['on-attack']:
				addToActionStack('ability',[actionTakers[0]], ability)
	
				
	actionStack.append({'actionTakers':actionTakers, 'type':type, 'data':data})

func nextAction(): 
	#prep actionStack[0] if there is one, 
	#otherwise add one and recurse
	
	if !battleOver:
		if actionStack.size() > 0:
			var noAction = false
			print('executing actionStack: '+str(actionStack))
			if actionStack[0].type == 'moveTurnIndicator':
				var activeInd
				var inactiveInd
				if actionStack[0].actionTakers[0].isAlly: #it actually is ally turn but we changed it already
					activeInd = $AllyTurnIndicator
					inactiveInd = $EnemyTurnIndicator
				else:
					activeInd = $EnemyTurnIndicator
					inactiveInd = $AllyTurnIndicator
					
				activeInd.modulate.a = 1
				if state == states.roundEnd:
					inactiveInd.modulate.a = 0
				else:
					inactiveInd.modulate.a = 0.25
				activeInd.move(actionStack[0].actionTakers[0])
				activeInd.connect("moveComplete", self, 'nextAction', [], CONNECT_ONESHOT)
			else:
				
				
				#if action takers is null it is a battle mechanic like regen or poison
				if actionStack[0].actionTakers == null: 
					actionStack[0].actionTakers = []
					for unit in allies + enemies:
						if unit.curStats[actionStack[0].type] > 0:
							actionStack[0].actionTakers.append(unit)
				#actionTakers should be set by this point. 
				#if not, there is no units that need to do the action
				for unit in actionStack[0].actionTakers:
					
					unit.preAction(actionStack[0].type, actionStack[0].data)
				
				if actionStack[0].actionTakers.size() == 0:
					noAction = true
			if !noAction:
				if Global.keywords.has(actionStack[0].type):
					
					battleText(Global.keywords[actionStack[0].type].desc)
				elif actionStack[0].data!= null:
					battleText(actionStack[0].actionTakers[0].id+ ' '+ actionStack[0].type + ' '+ actionStack[0].data.desc)
			actionStack.remove(0)
			if noAction:
				nextAction()
			return
		elif state == states.attack: # add next attacker to actionStack and recurse
			var nextAttacker
			if alliesDone && enemiesDone:
				#print('all units done - action phase done with '+ states.keys()[state])
				nextState()
				return
			elif alliesDone:
				allyTurn = false
			elif enemiesDone:
				allyTurn = true
			if allyTurn:
				
				nextAttacker = getNextAttacker(allies)
				#print('	next attacker: ',nextAttacker)
				if nextAttacker != null:
					addToActionStack('moveTurnIndicator', [nextAttacker])
					addToActionStack('startattack',[nextAttacker])
					
					allyTurn = false
					nextAction()
					return
				else:
					#print('	all allies are done...')
					alliesDone = true
					allyTurn = false
					nextAction()
					return
			else:
				
				nextAttacker = getNextAttacker(enemies)
				if nextAttacker != null:
					#print('	calling for enemy action')
					addToActionStack('moveTurnIndicator', [nextAttacker])
					addToActionStack('startattack', [nextAttacker])
					allyTurn = true
					nextAction()
					return
				else:
					#print('	all enemies are done...')
					allyTurn = true
					enemiesDone = true
					nextAction()
					return
		elif state == states.roundEnd:
			
			nextState()
			return
	else:
		endBattle()
		


func addWaitingFor(unit):
	#this is called by unit in preAction, only if the action actually needs to be done
	if waitingFor.find(unit)== -1:
		waitingFor.append(unit)
	#connect('doPreppedAction', unit, 'doAction', [], CONNECT_ONESHOT)
	#print('adding action taker: '+unit.id)
		
func unitActionDone(unit):
	waitingFor.erase(unit)
	print(unit.getName()+' done with action! waitingFor left: '+str(waitingFor))
	if waitingFor.size() <= 0:
		#nextAction()
		if Global.player.autoplay:
			nextAction()
		elif actionStack.size() > 0:
			if actionStack[0].type == 'attack':
				$EnemyTurnIndicator.modulate.a = 0.5
				$AllyTurnIndicator.modulate.a = 0.5
				nextAction()
			else:
				waitingForActionClick = true
		else:
			waitingForActionClick = true

func nextState():
	print(str('ending battleState: ',states.keys()[state]))
	lastState = state
	if state == states.intro:
		state = states.battleStart
		$CanvasLayer/PrebattleChoice.hide()
		nextState()
	elif state == states.battleStart:
		state = states.movingTogether
		pass
	elif state == states.movingTogether:
		state = states.attack
		$CanvasLayer/RoundLabel.show()
		$CanvasLayer/RoundLabel.text = str('Round ', roundNum)
		nextAction()
	
	elif state == states.attack:
		#print('attack phase over')
		state = states.roundEnd
		alliesDone = false
		enemiesDone = false
		for actionType in roundEndOrder:
			if actionType == 'unitRoundEndAbilities':
				for unit in allies + enemies:
					if unit.abilities.has('round-end'):
						for ability in unit.abilities['round-end']:
							addToActionStack('moveTurnIndicator', [unit])
							addToActionStack('ability', [unit], ability)
			else:
				addToActionStack(actionType)
			
		nextAction()
		
	elif state == states.roundEnd:
		#print('roundEnd phase over')
		roundNum +=1
		$CanvasLayer/RoundLabel.text = str('Round ', roundNum)
		print('round: ', roundNum)
		alliesDone = false
		enemiesDone = false
		allyTurn = true
		for unit in allies:
			unit.hasAttacked = false
		for unit in enemies:
			unit.hasAttacked = false
		state = states.attack
		nextAction()
	
		
	pass

func getNextAttacker(unitArray):
	#print('getting next attacker from ',unitArray)
	var result = null
	for unit in unitArray:
		if is_instance_valid(unit):
			if state == states.attack:
			
				if !unit.hasAttacked:
					return unit
			if state == states.roundEnd:
			
				if !unit.hasDoneRoundEnd:
					return unit
	
	return result
	
func waitAnd(time, afterMethod, args = []):
	
	waitTime = time
	
	afterWaitMethod = afterMethod
	afterWaitArgs = args
	
func addUnit(group, unitId, unitLevel = 1):
	var newSpot = Global.spotScene.instance()
	group.add_child(newSpot)
	newSpot.render('battle')
	var newUnit = Global.instanceUnit(unitId)
	
	#newUnit.render(unitId, unitLevel)
	newUnit.battle = self
	newSpot.fill(newUnit)
	if group.name == 'EnemySpots':
		enemies.append(newUnit)
	else:
		allies.append(newUnit)
	return newUnit
	
func endBattle():
	battleOver = true
	if enemies.size() > 0:
		$CanvasLayer/VictoryScreen/Label.text = 'defeat'
		get_node('%ContinueButton').show()
		lootItems = []
	showVictoryScreen()
	$CanvasLayer/RoundLabel.hide()
	#player.afterBattle()
	print('battle over')
	pass
	

	
func addAlly(unitId, unitLevel = 1):
	var newAlly = addUnit($TestAllySpots, unitId, unitLevel)
	#newAlly.connect('death', self, 'removeAlly', [newAlly])
	
func addEnemy(unitId, unitLevel = 1):
	var newEnemy = addUnit($EnemySpots, unitId, unitLevel)
	#newEnemy.connect('death', self, 'removeEnemy', [newEnemy])
	newEnemy.setEnemy()
	
func removeAlly(unit):
	
	allies.remove(allies.find(unit))
	if allies.size() <= 0:
		battleOver = true
		print('battle over allies dead')
	#print('removing ally from allies, allies: ', allies.size())
	
func removeEnemy(unit):
	enemies.remove(enemies.find(unit))
	#print('enemies: ', enemies)
	if enemies.size() <= 0:
		playerVictory = true
		battleOver = true
		print('battle over enemies dead')
		
func generateEnemies(difficulty):
	
	var levelMin = 0 + float(difficulty)/9
	var levelMax = 1.8 + float(difficulty)/4
	var numberOfEnemies = min(difficulty, 7)
	print('generating (',numberOfEnemies,') enemies with difficulty: ', difficulty)
	print('level range from ',levelMin, ' to ', levelMax)
	for i in range(numberOfEnemies):
		var randUnitIndex = Global.randomUnitBasedOn(difficulty)
		#var randUnitIndex = 3
		
		var levelRand = Global.rng.randf_range(levelMin, levelMax)
		var level
		if levelRand > 3:
			level = 3
		elif levelRand > 2:
			level = 2
		else: 
			level = 1
		
		if Global.game.debug:
			for v in debugEnemyCount:
				addEnemy(debugEnemy)
		else:
			addEnemy(randUnitIndex)
	$EnemySpots.updatePositions()
	$EnemySpots.updateSynergies()
	
func applyTeamModifiers(team):
	var targetTeam
	var mods
	if team == 'allies':
		targetTeam = allies
		mods = allyModifiers
	else:
		targetTeam = enemies
		mods = enemyModifiers
	print('mods.size() ',str(mods.size()))
	for mod in mods:
		print('applying mod: ',mod)
		for unit in targetTeam:
			unit.changeStat(mod, mods[mod])
	mods = {}



func addTeamModifier(isAllied, modifierName, amount = 1):
	var dict = enemyModifiers
	if isAllied:
		dict = enemyModifiers
		
	if dict.has(modifierName):
		dict[modifierName] += amount
	else:
		dict[modifierName] = amount


func _on_PrebattleChoice_choiceMade(choiceInfo):
	if choiceInfo!= null:
		addLoot('coins', 2)
		addTeamModifier(false, 'power', 1)
		#addTeamModifier(false, 'armor', 1)
		applyTeamModifiers('enemies')
		
	nextState()
	
	pass # Replace with function body.
	
func showVictoryScreen():
	Global.player.coinLabel.modulate.a = 1
	var maxLootItems = 4.0
	
	for i in range(maxLootItems):
		if i > lootItems.size()-1:
			collectButtons.get_node(str('CollectButton',i+1)).hide()
		else:
			var curButton = collectButtons.get_node(str('CollectButton',i+1))
			var sizeDiff = 42
			curButton.show()
			print('increasing rect size from: '+str(victoryScreen.rect_size.y))
			victoryScreen.rect_size.y += sizeDiff
			victoryScreen.rect_global_position.y -= sizeDiff/2
			curButton.render(lootItems[i])
			curButton.connect('collected', Global.player, 'collectLoot')
			curButton.connect('collected', self, 'collectLoot')
	get_node('%BattleLog').hide()
	Global.player.coinLabel.show()
	victoryAnima.play()
	$CanvasLayer/VictoryScreen.show()
	
func collectLoot(loot):
	lootCollected +=1
	if lootCollected >= lootItems.size():
		get_node('%ContinueButton').show()

func addLoot(lootName, amount):
	lootItems.append({'type':lootName, 'amount':amount})

func _on_ContinueButton_pressed():
	$CanvasLayer/VictoryScreen.hide()
	if enemies.size() > 0:
		get_tree().reload_current_scene()
	Global.player.afterBattle()
	clearBodies()
	pass # Replace with function body.
	
func clearBodies():
	for body in bodies:
		body.queue_free()

func _input(event):
	if event.is_action_pressed("left_click") || event.is_action_pressed("ui_select"):
		if waitingForActionClick:
			print('action click received')
			emit_signal('mergeStatuses')
			nextAction()
			#emit_signal('doPreppedAction')
			
			waitingForActionClick = false
			
			
	#if even


func _on_Autoplay_toggled(button_pressed):
	if button_pressed:
		Global.player.autoplay = true
	else:
		Global.player.autoplay = false
	pass # Replace with function body.
