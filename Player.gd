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
var oldBattle
onready var store = get_node('%Store')

onready var lineupSpots = $LineupSpots
onready var infoPanel = $Front/GUI/InfoPanel
onready var coinLabel = $CoinLabel
onready var graveyard = get_node('%Graveyard')
onready var gui = get_node('%GUI')
onready var benchSpots = get_node('%BenchSpots')
var offscreenDis = 700

var rerollCost = 0
var stageNum = 1
var lineupVertical = false
onready var lineupStartPos = $LineupSpots.global_position

onready var unitInfoPanel = $Front/UnitInfoPanel

var autoplay = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.game.debug:
		coins = 100
		var newUnit = addUnit('skunk')
		newUnit.levelUp()
		addUnit('skorpion', graveyard)
	
	call_deferred('afterReady')
	graveyard.hide()
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
	initializeBattle()
	Global.updateAverageStats([store.get_node('Selection').getUnits()])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if holding!= null:
		holding.global_position = get_viewport().get_mouse_position()
	if lineupVertical:
		if $LineupSpots.percentVertical < 1:
			
			$LineupSpots.percentVertical = min($LineupSpots.percentVertical + delta*2, 100)
			
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
			#battle.modulate.a = $LineupSpots.percentVertical
			$LineupSpots.percentVertical = max($LineupSpots.percentVertical - delta*2, 0)
			$LineupSpots.updatePositions()
			$LineupSpots.global_position.y = CustomFormulas.proportion(lineupStartPos.y, battle.get_node('AlliesPos').global_position.y, $LineupSpots.percentVertical)
			$LineupSpots.global_position.x = CustomFormulas.proportion(lineupStartPos.x, battle.get_node('AlliesPos').global_position.x, $LineupSpots.percentVertical)
			#battle.get_node('Enemyspots').percentVertical = $LineupSpots.percentVertical
			if $LineupSpots.percentVertical ==0:
				if battling:
					
					battling = false
	
	pass
	
func afterBattle():
	if stageNum % Global.stagesPerBiome == 0:
		showGraveyard()
	else:
		initializeBattle()
		gui.show()
	stageNum +=1
	
	lineupVertical = false
	
	for spot in lineupSpots.get_children():
		spot.render('lineup')
	#anima.play()
	lineupSpots.updateSynergies()
	#var anima = Anima.begin($Front/GUI)
	#anima.then({property = 'y', to = offscreenDis, duration = 1.5, relative = true})
	#anima.play()
	$Front.show()
	coinLabel.show()
	benchSpots.show()
	get_node('%SellSpot').show()
	$Front/EndPreviewButton.hide()
	store.refresh()
	$LeaveScreen.modulate.a = 1
	
	#call_deferred('initializeBattle')
	
	
func initializeBattle():
	#print('INITIALIZING BATTLE')
	
	oldBattle = battle
	battle = battleScene.instance()
	
	
	call_deferred("freeOldBattle")
	$BattleParent.add_child(battle)
	
	battle.render(stageNum)
	
	
	
func freeOldBattle():
	#print('FREEING OLD BATTLE')
	if is_instance_valid(oldBattle):
		print('freeing old battle')
		oldBattle.queue_free()
		print('battles: '+str($BattleParent.get_children().size()))
		#hide()
	
func showGraveyard():
	get_node('%Store').hide()
	get_node('%Graveyard').show()
	get_node('%GraveyardSpots').updatePositions()
	
func clearGraveyard():
	for spot in get_node('%GraveyardSpots'):
		spot.queue_free()
	
func nextBattle():
	$Front/EndPreviewButton.hide()
	get_node('%SellSpot').hide()
	get_node('%CoinLabel').hide()
	battling = true
	gui.hide()
	benchSpots.hide()
	
	#battle.render(getLineupUnits(), otherPlayer.getLineupUnits())
	for spot in lineupSpots.get_children():
		spot.render('battle')
	
	battle.allySpots = $LineupSpots
	#animaLeft($Bench)
	#var anima = Anima.begin($LeaveScreen)
	#anima.then({property = 'y',to = offscreenDis, duration = 1, relative = true})
	#anima.then({property = 'opacity',to = 0, duration = 1})
	#anima.with({node = $CoinLabel, property = 'opacity', to = 0, duration = 1})
	#anima.play()
	#anima = Anima.begin($Front/GUI)
	#anima.then({property = 'y', to = -offscreenDis, duration = 1, relative = true, on_completed  = [funcref(battle, 'start'), []] })
	#anima.play()
	gui.modulate.a = 1
	coinLabel.modulate.a = 1
	battle.start(getLineupUnits())
	

func unitSold(unit):
	coins+= unit.tier + unit.level-1
	Global.playAudio('coins')
	updateInfo()
	
func unitDie(unit):
	var newSpot = addSpot(get_node('%GraveyardSpots'), 'graveyard')
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
	$Front/GUI/RerollButton/CoinLabel.setCoins(rerollCost)
	if rerollCost == 0:
		$Front/GUI/RerollButton/CoinLabel.setCoins('Free')

	coinLabel.setCoins(coins)

func checkMerge(mergeUnit):
	var count = 0
	var maxHpPercent = 0
	var unitsToMerge = []
	var keepUnit = mergeUnit
	for unit in getOwnedUnits():
		if unit.id == mergeUnit.id && unit.level == mergeUnit.level:
			count += 1
			unitsToMerge.append(unit)
			var hpPercent = unit.curStats.hp
			if hpPercent > maxHpPercent:
				keepUnit = unit

	if count >= 3:
		for un in unitsToMerge:
			if un != keepUnit:
				un.get_parent().empty(true)
		getFirstEmptySpot().fill(keepUnit)
		keepUnit.levelUp()
		
	


	
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
		
		coins-= Global.unitLibrary[unit.id].tier
		
		
		getFirstEmptySpot().fill(unit)
		checkMerge(unit)
		if rerollCost == 0:
			rerollCost +=1
		updateInfo()
		

func addUnit(unitName, group = null):
	var unit = Global.instanceUnit(unitName)
	checkMerge(unit)
	if group == graveyard:
		unitDie(unit)
		pass
	else:
		getFirstEmptySpot().fill(unit)
	return unit

func getFirstEmptySpot():
	for spot in lineupSpots.get_children():
		if spot.unit == null:
			return spot
				
	for spot in benchSpots.get_children():
		if spot.unit == null:
			return spot
	return null
				
	

	
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
	
func collectLoot(button):
	
	if button.type == 'coins':
		coins+=button.amount
		Global.playAudio('coin')
		
	updateInfo()


func _on_PreviewButton_pressed():
	$Front/GUI.hide()
	$Front/EndPreviewButton.show()
	pass # Replace with function body.


func _on_EndPreviewButton_pressed():
	$Front/GUI.show()
	pass # Replace with function body.


func _on_GraveyardButton_pressed():
	graveyard.hide()
	gui.show()
	store.show()
	initializeBattle()
	pass # Replace with function body.
