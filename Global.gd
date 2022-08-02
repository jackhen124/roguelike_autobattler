extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal avgStatsChanged
var rng = RandomNumberGenerator.new()
var spotScene = preload("res://Spot.tscn")
var unitScene = preload("res://units/Unit.tscn")
var player
var game

var timer = Timer.new()

var tieredLibrary = []
var maxTier = 4

var avgStats = {'power':1, 'hp': 1}
var onScreenUnits = []
const keywords = {
	'hp':{
		'type': 'buff',
		'desc':"HP represents how much damage a unit can withstand before fainting",
		'color':'#32e691'
	},
	'power':{
		'type': 'buff',
		'desc':"Power represents damage done when attacking",
		'color':'#ae4b4f'
	},
	'heal':{
		'type': 'buff',
		'desc':"increase HP. any healing above max HP will still increase HP at half effectiveness, and return to max after the battle",
		'color':'#96ffae'
	},
	'poison':{
		'type': 'debuff',
		'desc':"ROUND-END: take damage equal to poison stacks remove 1 stack",
		'color':'#ab00ff'
	},
	'triumph':{
		'type': 'trigger',
		'desc':"Triggers an effect when an enemy is killed",
		'color':'#e85e47'
	},
	'armor':{
		'type':'buff',
		'desc': "Reduce all damage taken by 1 per armor",
		#'color':'#a2a568' # snail colored
		'color':'#c3d5dd'
	},
	'regeneration':{
		'type':'buff',
		'desc': "round-end: heal 1 per regenration",
		'color':'#27e496'
	},
	'slow':{
		'type':'debuff',
		'desc': "If a unit recieves enough stacks of slow, they are stunned. The amount of stacks needed to stun an enemy increases every time they are stunned",
		'color':'#c2f2ff'
	},
	'stun':{
		'type':'debuff',
		'desc': "Stunned units miss their next attack. Getting stunned again will take an extra stack of slow",
		'color':'#29d0ff'
	},
	'on-attack':{
		
		'desc': "Triggers an effect when this unit attacks",
		'color':''
	},
	'on-guard':{
		
		'desc': "Triggers an effect when this is attacked",
		'color':''
	},
	'round-end':{
		
		'desc': "Triggers an effect each time all units have attacked",
		'color':''
	},
	
	
}
const elementLibrary = {
	'aquatic':{
		'desc':'if you have unitsNeeded unique aquatic units, reduce all enemies attack by effectPerStack',
		'unitsNeeded': [2,4,6],
		'effectPerStack':[1,2,3],
		'color':'#638bff'
	},
	'earthen':{
		'desc':'if you have unitsNeeded unique earthen units, grant all allies + effectPerStack armor',
		'unitsNeeded': [2,4,6],
		'effectPerStack':[1,2,3],
		'color':'#c09b7b'
	},
	'floral':{
		'desc':'if you have unitsNeeded unique floral units, grant all allies + effectPerStack regeneration',
		'unitsNeeded': [2,4,6],
		'effectPerStack':[1,2,3],
		'color':'#5dfd82'
	},
	'glacial':{
		'desc':'if you have unitsNeeded unique glacial units, chill a random enemy effectPerStack times at the start of battle',
		'unitsNeeded': [2,4,6],
		'effectPerStack':[2,5,9],
		'color':'#c2f2ff'
	},
	'toxic':{
		'desc':'if you have unitsNeeded unique toxic units, whenever an enemy recieves damage they also gain effectPerStack stacks of poison',
		'unitsNeeded': [3,6],
		'effectPerStack':[1,2],
		'color':'#cf6eff'
	},
	'lunar':{
		'desc':'if you have unitsNeeded unique lunar units, all allies gain effectPerStack power at the end of each round',
		'unitsNeeded': [2,4,6],
		'effectPerStack':[2,4,6],
		'color':'#000000'
	},
	'solar':{
		'desc':'if you have unitsNeeded unique solar units, your first effectPerStack units attack before the battle starts',
		'unitsNeeded': [2,4,7],
		'effectPerStack':[1,2,4],
		'color':'#ffe552'
	},
	
}
const unitLibrary = {
	##################### Tier 1 ###########################
		'skunk':{
		
		'tier':1,
		'power':3,
		'hp': 7,
		'types':['toxic','floral'],
		'desc':'on-attack: apply 1 poison to target. on-guard apply 1 poison to attacker'
		
		},
		'skorpion':{
		
		'tier':1,
		'power':2,
		'hp': 8,
		'types':['toxic', 'earthen'],
		'desc':"on-guard: apply poison equal to 1 third of attacker's power"
		
		},
		
		'snail':{
		
		'tier':1,
		'power':2,
		'hp': 8,
		'armor':1,
		'types':['earthen', 'aquatic'],
		'desc':"armor:1"
		
		},
	##################### Tier 2 ###########################
		'eagle':{
		
		'tier':2,
		'power':5,
		'hp': 9,
		'types':['solar','lunar'],
		'desc':'round-end: lose [1,2,4] power. if my attack would be less than 1, lose health instead'
		},
		'octopus':{
		
		'tier':2,
		'power':2,
		'hp': 7,
		'types':['aquatic', 'lunar'],
		'desc':'round-end: deal damage equal to my power to [1/2/4] random enemies'
		},
		'snake':{
		
		'tier':2,
		'power':3,
		'hp': 8,
		'types':['solar', 'toxic'],
		'desc':''
		},
	##################### Tier 3 ###########################
		'crocodile':{
		'tier':3,
		'power':4,
		'hp': 11,
		'types':['aquatic','solar'],
		'desc':"triumph: gain +[1,2,3] power and heal equal to (target's max HP * [0.5, 1, 1.5]' "
		},
		'tiger':{
		'tier':3,
		'power':5,
		'hp': 14,
		'types':['floral','lunar'],
		'desc':""
		},
	##################### Tier 4 ###########################
		'elephant':{
		
		'tier': 4,
		'power':5,
		'hp': 12,
		'types':['earthen','solar'],
		'desc':''
		},
		'polarbear':{
		
		'tier': 4,
		'power':5,
		'hp': 12,
		'types':['glacial','solar'],
		'desc':''
		}
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	
	add_child(timer)
	timer.one_shot = true
	rng.randomize()
	randomize()
	
	for i in range(maxTier):
		var curTierArray = []
		for unitName in unitLibrary:
			if unitLibrary[unitName]['tier']== i+1:
				curTierArray.append(unitName)
		tieredLibrary.append(curTierArray)
		
	
		
	for i in range(16):
		pass
		#var pu = getPossibleUnitsBasedOnStage(i+1)
		#print(pu.size(), ' possible units at stage ',i+1,':',pu)
	pass # Replace with function body.


	

func addSpot(parentNode):
	var newSpot = spotScene.instance()
	parentNode.add_child(newSpot)
	
	
func randomUnitBasedOn(stage):
	var possibleUnits = getPossibleUnitsBasedOnStage(stage)
	var rand = rng.randi_range(0,possibleUnits.size()-1)
	
	return possibleUnits[rand]
	
func instanceUnit(unitName):
	var unit = load('res://units/Unit.tscn').instance()
	var file2Check = File.new()
	var scriptName = str('res://units/scripts/', unitName, '.gd')
	var doesScriptExist = file2Check.file_exists(scriptName)
	if doesScriptExist:
		unit.set_script( load(scriptName ))
	unit.render(unitName)
	connect('avgStatsChanged', unit, 'updateInfo')
	return unit
	
func updateAverageStats(array2d):
	var powerSum = 0
	var hpSum = 0
	var divisor = 0
	for unitArray in array2d:
		print(unitArray)
		for unit in unitArray:
			print('	'+unit.id)
			powerSum += unit.power
			hpSum += unit.hp
			divisor+=1
	if divisor > 0:
		avgStats['power'] = float(powerSum) / float(divisor)
		avgStats['hp'] = float(hpSum) / float(divisor)
	print('AVG stats: '+ str(avgStats))
	emit_signal("avgStatsChanged")
	
	
func getPossibleUnitsBasedOnStage(stage):
	#print('GETTING UNIT BASED ON STAGE: ',stage)
	var allUnitsUsedStage = 6
	
	var minPercentUsed = float(tieredLibrary[0].size()) / float(unitLibrary.size())
	var prop = min(float(stage-1) / float(allUnitsUsedStage-1),1)#subtract 1 because we want prop at 0 when stage is 1
	
	var percentOfTotalLibToUse = CustomFormulas.proportion(minPercentUsed, 1, prop)
	#print('percentOfTotalLibToUse = ', percentOfTotalLibToUse)
	var libsFullyUsed = 0
	
	var percentOfPartialTier
	for i in range(4):
		var curTier = i+1
		#print('	curTier: ',i+1)
		#print('	percentIsAtLeastTier: ',percentIsAtLeastTier(curTier),' vs ',percentOfTotalLibToUse)
		if percentIsAtLeastTier(curTier) <= percentOfTotalLibToUse:
			#print('	using all of tier ',curTier)
			
			libsFullyUsed+=1
			
		else:
			#print('	percent of tier ',curTier)
			var percentOfTotalLibraryMissingFromPartialLib = percentOfTotalLibToUse - percentIsAtLeastTier(curTier)
			#print('	percent of total lib missing from partial lib: ', percentOfTotalLibraryMissingFromPartialLib)
			var numberFromPartialLib = unitLibrary.size() * percentOfTotalLibraryMissingFromPartialLib
			percentOfPartialTier = 1+float(numberFromPartialLib)/ float(tieredLibrary[i].size())
			
			#print('	using ',percentOfPartialTier*100,'% of tier ',curTier)
			break
		
	var possibleUnits = []
	for i in range(libsFullyUsed):
		possibleUnits.append_array(tieredLibrary[i])
	if libsFullyUsed == 4 || percentOfPartialTier == 0:
		#print('	stage ',stage,' using ',possibleUnits.size(),' / ', unitLibrary.size())
		return possibleUnits
	var partialLib = shuffleArray(tieredLibrary[libsFullyUsed])
	var percentCovered = 0
	
	for barelyUnlockedUnit in partialLib:
		if percentCovered <= percentOfPartialTier:
			possibleUnits.append(barelyUnlockedUnit)
		percentCovered += 1.0 / float(partialLib.size())
	#print('	stage ',stage,' using ',possibleUnits.size(),' / ', unitLibrary.size())
	return possibleUnits
	
func shuffleArray(array):
	var shuffled = [] 
	var indexList = range(array.size())
	for i in range(array.size()):
		rng.randomize()
		var x = rng.randi_range(0,indexList.size()-1)
		shuffled.append(array[indexList[x]])
		indexList.remove(x)
	return shuffled

func percentIsAtLeastTier(tier):
	var percentSum = 0
	var totalSum = 0
	var i = 0
	while i < 4:
		totalSum += tieredLibrary[i].size()
		if i < tier:
			percentSum += tieredLibrary[i].size()
		i+=1
	return float(percentSum) / float(totalSum)

func playAudio(filepath, volume = 0, delay = 0):
	if delay > 0:
		
		
		timer.connect("timeout", self, 'playAudio', [filepath, volume])
		timer.start(delay)
		return
		
	var aud = AudioStreamPlayer.new()
	add_child(aud)
	if !ResourceLoader.exists(filepath):
		filepath = 'res://resources/audio/'+filepath+'.ogg'

	aud.stream = load(filepath)
	
	aud.play()
	

