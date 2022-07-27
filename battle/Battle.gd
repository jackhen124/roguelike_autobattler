extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var allies = []
var enemies = []
var allyTurn = true
var attackIndex = 0
onready var tween = $Tween
var alliesDone
var enemiesDone
var roundNum = 1
var player
var allySpots
var battleOver = false
var averageHp = 5
var centerPos = Vector2(0,0)
onready var enemiesStartPos = $EnemySpots.global_position

var victoryAnima
enum states {idle, attack, roundEnd}
var state = states.idle

var waitingOnUnit = false

var playerVictory = false
# Called when the node enters the scene tree for the first time.
func _ready():
	victoryAnima = Anima.begin($VictoryScreen)
	victoryAnima.then({animation = 'bouncing_in_down', duration = 2, easing = Anima.EASING.EASE_IN_OUT})
	#victoryAnima.then({animation = 'zoom_in_down', duration = 2, sing = Anima.EASING.EASE_OUT_BOUNCE})
	#victoryAnima.then({from = -700, to = -400, property = 'y', duration = 2, sing = Anima.EASING.EASE_OUT_BOUNCE})
	victoryAnima.set_visibility_strategy(Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT)
	if Global.game.debug:
		victoryAnima.play()
		$VictoryScreen.show()
	
	#$VictoryScreen.hide()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass
	
func debug():
	$TestAllySpots.percentVertical = 1
	$TestAllySpots.global_position = $AlliesPos.global_position
	$EnemySpots.percentVertical = 1
	$EnemySpots.updatePositions()
	$TestAllySpots.global_position = $EnemiesPos.global_position
	$TestAllySpots.updatePositions()
	start()

func render(allyUnitArray, difficulty):
	allies = allyUnitArray
	
	generateEnemies(difficulty)
	
		
	print('allies: ', allies, ' enemies: ',enemies)
	var allUnits = [allies,enemies]
	Global.updateAverageStats(allUnits)
	#start()
	pass
	
func start():
	
	for ally in allies:
		ally.battle = self
		ally.connect('death', self, 'removeAlly', [ally])
		ally.player = player
		ally.updateInfo()
		#ally.allies = allies
		#ally.enemies = allies
		pass
	for enemy in enemies:
		enemy.battle = self
		enemy.updateInfo()
		#enemy.allies = enemies
		#enemy.enemies = allies
		pass
	
	var diff = $AlliesPos.global_position - $EnemiesPos.global_position
	print($EnemiesPos.name)
	print($AlliesPos.name)
	centerPos = $EnemiesPos.global_position.move_toward($AlliesPos.global_position, float($EnemiesPos.global_position.distance_to($AlliesPos.global_position))/2.0)
	print('battle centerPos ', centerPos)
	state = states.attack
	
	if Global.game.debug:
		end()
		return
	nextAction()
	


	#tween.connect("tween_all_completed", self , 'nextAttack', [], CONNECT_ONESHOT)
	
func nextAction():
	#print('	next action! allyTurn: '+str(allyTurn))
	if !battleOver:
		waitingOnUnit = false
		var nextAttacker
		if alliesDone && enemiesDone:
			print('all units done - action phase done with '+ states.keys()[state])
			actionPhaseDone()
			return
		elif alliesDone:
			allyTurn = false
		elif enemiesDone:
			allyTurn = true
		if allyTurn:
			
			nextAttacker = getNextActionTaker(allies)
			#print('	next attacker: ',nextAttacker)
			if nextAttacker != null:
				#print('	calling for ally action')
				takeAction(nextAttacker)
				allyTurn = false
				return
			else:
				#print('	all allies are done...')
				alliesDone = true
				allyTurn = false
				nextAction()
				return
		else:
			
			nextAttacker = getNextActionTaker(enemies)
			if nextAttacker != null:
				#print('	calling for enemy action')
				takeAction(nextAttacker)
				allyTurn = true
				return
			else:
				#print('	all enemies are done...')
				allyTurn = true
				enemiesDone = true
				nextAction()
				return
	else:
		print('battle over')
		#actionPhaseDone()
		end()
		
func takeAction(actionTaker):
	waitingOnUnit = true
	if state == states.attack:
		#print(actionTaker.id + ' taking next action: attack')
		actionTaker.hasAttacked = true

		var target
		if allyTurn:
			target = enemies
		else:
			target = allies
		actionTaker.attack(target)
	elif state == states.roundEnd:
		#print(actionTaker.id + ' taking next action: roundEnd')
		actionTaker.hasDoneRoundEnd = true


		actionTaker.roundEnd()

func actionPhaseDone():
	if state == states.attack:
		#print('attack phase over')
		state = states.roundEnd
		alliesDone = false
		enemiesDone = false
		
		nextAction()
		
	elif state == states.roundEnd:
		#print('roundEnd phase over')
		roundNum +=1
		print('round: ', roundNum)
		alliesDone = false
		enemiesDone = false
		allyTurn = true
		for unit in allies:
			unit.hasAttacked = false
			unit.hasDoneRoundEnd = false
		for unit in enemies:
			unit.hasAttacked = false
			unit.hasDoneRoundEnd = false
		state = states.attack
		nextAction()
	pass

func getNextActionTaker(unitArray):
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
	
func end():
	battleOver = true
	victoryAnima.play()
	$VictoryScreen.show()
	#player.afterBattle()
	print('battle over')
	pass
	
func addAlly(unitId, unitLevel = 1):
	var newAlly = addUnit($TestAllySpots, unitId, unitLevel)
	newAlly.connect('death', self, 'removeAlly', [newAlly])
	
func addEnemy(unitId, unitLevel = 1):
	var newEnemy = addUnit($EnemySpots, unitId, unitLevel)
	newEnemy.connect('death', self, 'removeEnemy', [newEnemy])
	newEnemy.setEnemy()
	
func removeAlly(unit):
	
	allies.remove(allies.find(unit))
	if allies.size() <= 0:
		battleOver = true
		print('battle over allies dead')
	print('removing ally from allies, allies: ', allies.size())
	
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
			addEnemy('elephant')
		else:
			addEnemy(randUnitIndex)
	$EnemySpots.update()
