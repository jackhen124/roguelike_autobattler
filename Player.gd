extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal needUpdate
var holding = null
var isUser = false
var hp = 20
var coins = 2
var game
onready var cam = $Camera2D
onready var tween = $Tween
var battleScene = preload('res://battle/Battle.tscn')
var battling = false
var battle
onready var store = $GUI/Store
onready var benchSpots = $LeaveScreen/BenchSpots
onready var lineupSpots = $LineupSpots
onready var infoPanel = $GUI/InfoPanel
var coinLabel
var offscreenDis = 700

var rerollCost = 0
var stageNum = 1
var lineupVertical = false
onready var lineupStartPos = $LineupSpots.global_position


# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.game.debug:
		coins = 100
		addUnit('skunk')
	coinLabel = $LeaveScreen/CoinLabel
	call_deferred('afterReady')
	
	for spot in lineupSpots.get_children():
		spot.player = self
		spot.render('lineup')
		
	for spot in benchSpots.get_children():
		spot.player = self
		spot.render('bench')
		
		
	updateInfo()
	pass # Replace with function body.

func afterReady():
	store.refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if holding!= null:
		holding.global_position = get_viewport().get_mouse_position()
	if lineupVertical:
		if $LineupSpots.percentVertical < 1:
			
			$LineupSpots.percentVertical = min($LineupSpots.percentVertical + delta*0.55, 100)
			
			$LineupSpots.updatePositions()
			if is_instance_valid(battle):
				battle.get_node('EnemySpots').percentVertical = $LineupSpots.percentVertical
				
				$LineupSpots.global_position.y = CustomFormulas.proportion(lineupStartPos.y, battle.get_node('AlliesPos').global_position.y, $LineupSpots.percentVertical)
				$LineupSpots.global_position.x = CustomFormulas.proportion(lineupStartPos.x, battle.get_node('AlliesPos').global_position.x, $LineupSpots.percentVertical)
				battle.get_node('EnemySpots').global_position.y = CustomFormulas.proportion(battle.enemiesStartPos.y, battle.get_node('EnemiesPos').global_position.y, $LineupSpots.percentVertical)
				battle.get_node('EnemySpots').global_position.x = CustomFormulas.proportion(battle.enemiesStartPos.x, battle.get_node('EnemiesPos').global_position.x, $LineupSpots.percentVertical)
			battle.get_node('EnemySpots').updatePositions()
			
			
			
	else:
		if $LineupSpots.percentVertical > 0:
			battle.modulate.a = $LineupSpots.percentVertical
			$LineupSpots.percentVertical = max($LineupSpots.percentVertical - delta*0.7, 0)
			$LineupSpots.updatePositions()
			$LineupSpots.global_position.y = CustomFormulas.proportion(lineupStartPos.y, battle.get_node('AlliesPos').global_position.y, $LineupSpots.percentVertical)
			$LineupSpots.global_position.x = CustomFormulas.proportion(lineupStartPos.x, battle.get_node('AlliesPos').global_position.x, $LineupSpots.percentVertical)
			#battle.get_node('Enemyspots').percentVertical = $LineupSpots.percentVertical
			if $LineupSpots.percentVertical ==0:
				if battling:
					battle.queue_free()
					battling = false
	pass
	
func afterBattle():
	stageNum +=1
	lineupVertical = false
	var anima = Anima.begin($LeaveScreen)
	anima.then({property = 'y',to = -offscreenDis, duration = 3, relative = true})
	for spot in lineupSpots.get_children():
		spot.render('lineup')
	anima.play()
	anima = Anima.begin($GUI)
	anima.then({property = 'y', to = offscreenDis, duration = 3, relative = true})
	anima.play()
	
	$GUI/ReadyButton.show()
	store.refresh()
	coins+=1+stageNum
	
	
func nextBattle():
	
	battling = true
	$GUI/ReadyButton.hide()
	battle = battleScene.instance()
	$BattleParent.add_child(battle)
	battle.player = self
	#battle.render(getLineupUnits(), otherPlayer.getLineupUnits())
	for spot in lineupSpots.get_children():
		spot.render('battle')
	battle.render(getLineupUnits(), stageNum)
	#animaLeft($Bench)
	var anima = Anima.begin($LeaveScreen)
	anima.then({property = 'y',to = offscreenDis, duration = 3, relative = true})
	anima.play()
	anima = Anima.begin($GUI)
	anima.then({property = 'y', to = -offscreenDis, duration = 3, relative = true, on_completed  = [funcref(battle, 'start'), []] })
	anima.play()
	
	lineupVertical = true
	
func unitDie(unit):
	var newSpot = addSpot($Graveyard, 'graveyard')
	newSpot.fill(unit)
	
	
func animaLeft(node):
	var anima = Anima.begin(self)
	anima.then({property = 'x',to = -700, duration = 3, node = node})
	anima.play()
	
func animaRight(node):
	var anima = Anima.begin(self)
	anima.then({property = 'x', to = 700, duration = 3, node = node})
	anima.play()

func addSpot(group, type):
	var newSpot = Global.spotScene.instance()
	group.add_child(newSpot)
	newSpot.render(type)
	
	return newSpot
	

func updateInfo():
	emit_signal('needUpdate')
	$GUI/RerollButton/CoinLabel.setCoins(rerollCost)
	if rerollCost == 0:
		$GUI/RerollButton/CoinLabel.setCoins('Free')
	print(coins)
	coinLabel.setCoins(coins)
	
func canMerge(checkUnit):
	var numOthers = 0
	for otherUnit in getOwnedUnits():
		if otherUnit.level == checkUnit.level && otherUnit.id == checkUnit.id:
			numOthers +=1
			if numOthers >= 2:
				return true
	return false
	
func merge(checkUnit):
	
	for otherUnit in getOwnedUnits():
		if otherUnit.level == checkUnit.level && otherUnit.id == checkUnit.id:
			otherUnit.get_parent().empty(true)
			
	checkUnit.levelUp()
	
func getLineupUnits():
	var lineup = []
	for spot in lineupSpots.get_children():
		if spot.unit != null:
			lineup.append(spot.unit)
	print('lineup ', lineup)
	return lineup
	
func getOwnedUnits():
	var units = []
	for spot in lineupSpots.get_children():
		if spot.unit!= null:
			units.append(spot.unit)
	for spot in benchSpots.get_children():
		
		if spot.unit!= null:
			units.append(spot.unit)
	return units
	
func buyUnit(unit):
	if Global.unitLibrary[unit.id].tier <= coins:
		Global.playAudio('coin')
		print_debug('buying unit')
		coins-= Global.unitLibrary[unit.id].tier
		unit.player = self
		if canMerge(unit):
			merge(unit)
		getFirstEmptySpot().fill(unit)
		
		if rerollCost == 0:
			rerollCost +=1
		updateInfo()

func addUnit(unitName):
	var unit = Global.instanceUnit(unitName)
	if canMerge(unit):
		merge(unit)
	getFirstEmptySpot().fill(unit)

func getFirstEmptySpot():
	for spot in lineupSpots.get_children():
		if spot.unit == null:
			return spot
				
	for spot in benchSpots.get_children():
		if spot.unit == null:
			return spot
	return null
				
	
func spotHover(spot):
	infoPanel.spotHover(spot)
	
func _on_ReadyButton_pressed():
	nextBattle()
	pass # Replace with function body.


func _on_RerollButton_pressed():
	if coins > rerollCost:
		store.refresh()
		coins -= rerollCost
		if rerollCost < 2:
			rerollCost+=1
		updateInfo()
	pass # Replace with function body.
