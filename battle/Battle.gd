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
var battleOver = false
var averageHp = 5

onready var enemiesStartPos = $EnemySpots.global_position
# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass
	
func debug():
	addAlly(0)
	#addAlly(0)
	#addEnemy(0)
	addEnemy(0)
	start()

func render(allyUnitArray, difficulty):
	allies = allyUnitArray
	
	generateEnemies(difficulty)
	
		
	print('allies: ', allies, ' enemies: ',enemies)
	#start()
	pass
	
func start():
	
	for ally in allies:
		ally.battle = self
		ally.connect('death', self, 'removeAlly', [ally])
		ally.player = player
		#ally.allies = allies
		#ally.enemies = allies
		pass
	for enemy in enemies:
		enemy.battle = self
		
		#enemy.allies = enemies
		#enemy.enemies = allies
		pass
	nextAttack()
	


	#tween.connect("tween_all_completed", self , 'nextAttack', [], CONNECT_ONESHOT)
	
func nextAttack():
	print('next attack!')
	if !battleOver:
		var nextAttacker
		if alliesDone && enemiesDone:
			roundDone()
			#return
		elif alliesDone:
			allyTurn = false
		elif enemiesDone:
			allyTurn = true
		if allyTurn:
			print('	ally turn')
			allyTurn = false
			nextAttacker = getNextAttacker(allies)
			print('	next attacker: ',nextAttacker)
			if nextAttacker != null:
				
				nextAttacker.hasAttacked = true
				print('allies attacking enemyArray: ',enemies)
				nextAttacker.attack(enemies)
				
			else:
				alliesDone = true
				nextAttack()
		else:
			allyTurn = true
			nextAttacker = getNextAttacker(enemies)
			if nextAttacker != null:
				nextAttacker.hasAttacked = true
				nextAttacker.attack(allies)
			else:
				enemiesDone = true
				nextAttack()
	else:
		roundDone()
		end()

func roundDone():
	roundNum +=1
	print('round: ', roundNum)
	alliesDone = false
	enemiesDone = false
	for unit in allies:
		unit.hasAttacked = false
	for unit in enemies:
		unit.hasAttacked = false
	pass

func getNextAttacker(unitArray):
	#print('getting next attacker from ',unitArray)
	for unit in unitArray:
		if is_instance_valid(unit):
			
			if !unit.hasAttacked:
				return unit
	return null
	
func addUnit(group, unitId, unitLevel = 1):
	var newSpot = Global.spotScene.instance()
	group.add_child(newSpot)
	newSpot.render('battle')
	var newUnit = Global.unitScene.instance()
	
	newUnit.render(unitId, unitLevel)
	newUnit.battle = self
	newSpot.fill(newUnit)
	if group.name == 'Allies':
		allies.append(newUnit)
	else:
		enemies.append(newUnit)
	return newUnit
	
func end():
	battleOver = true
	
	player.afterBattle()
	print('battle over')
	pass
	
func addAlly(unitId, unitLevel = 1):
	var newAlly = addUnit($Allies, unitId, unitLevel)
	newAlly.connect('death', self, 'removeAlly', [newAlly])
	
func addEnemy(unitId, unitLevel = 1):
	var newEnemy = addUnit($EnemySpots, unitId, unitLevel)
	newEnemy.connect('death', self, 'removeEnemy', [newEnemy])
	newEnemy.setEnemy()
	
func removeAlly(unit):
	
	allies.remove(allies.find(unit))
	if allies.size() <= 0:
		battleOver = true
	print('removing ally from allies, allies: ', allies.size())
	
func removeEnemy(unit):
	enemies.remove(enemies.find(unit))
	#print('enemies: ', enemies)
	if enemies.size() <= 0:
		battleOver = true

func generateEnemies(difficulty):
	
	var levelMin = 0 + float(difficulty)/9
	var levelMax = 1.8 + float(difficulty)/4
	var numberOfEnemies = min(difficulty+1, 7)
	print('generating (',numberOfEnemies,') enemies with difficulty: ', difficulty)
	print('level range from ',levelMin, ' to ', levelMax)
	for i in range(numberOfEnemies):
		#var randUnitIndex = Global.rng.randi_range(0, Global.unitLibrary.size()-1)
		var randUnitIndex = 3
		
		var levelRand = Global.rng.randf_range(levelMin, levelMax)
		var level
		if levelRand > 3:
			level = 3
		elif levelRand > 2:
			level = 2
		else: 
			level = 1
		addEnemy(randUnitIndex)
	$EnemySpots.update()
