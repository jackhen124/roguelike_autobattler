extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var rng = RandomNumberGenerator.new()
var spotScene = preload("res://Spot.tscn")
var unitScene = preload("res://units/Unit.tscn")
var player
var unitCost = 1

const keywords = {
	'heal':{
		'type': 'buff',
		'desc':"increase HP. any healing above max HP will still increase HP at half effectiveness, and return to max after the battle."
	},
	'poison':{
		'type': 'debuff',
		'desc':"ROUND-END: take damage equal to poison stacks remove 1 stack."
	},
	'triumph':{
		'type': 'trigger',
		'desc':"Triggers an effect when an enemy is killed"
	},
	'defense':{
		'type':'buff',
		'desc': "Take less damage from all sources equal to defense"
	},
	'stun':{
		'type':'debuff',
		'desc': "ON-ATTACK: instead of attacking, remove all stacks of stun and take 2 damage for each stack after the first"
	}
	
}
const unitLibrary = [
		{
		'name':'skunk',
		'tier':1,
		'attack':3,
		'hp': 7,
		'types':['floral','earthen'],
		'desc':'ON-ATTACK: apply poison+1 to target. ON-GUARD apply poison+1 to attacker'
		
		},
		{
		'name':'skorpion',
		'tier':1,
		'attack':2,
		'hp': 8,
		'types':['earthen','solar'],
		'desc':"ON-GUARD: apply poison+(attacker's power / 3) rounded up to attacker "
		
		},
		{
		'name':'eagle',
		'tier':2,
		'attack':9,
		'hp': 4,
		'types':['solar','lunar'],
		'desc':''
		},
		{
		'name':'octopus',
		'tier':2,
		'attack':2,
		'hp': 7,
		'types':['aquatic', 'lunar'],
		'desc':'ROUND-END: deal damage equal to my power to [1/2/4] random enemies'
		},
		{
		'name':'crocodile',
		'tier':3,
		'attack':4,
		'hp': 10,
		'types':['aquatic','solar'],
		'desc':"TRIUMPH: gain +[1,2,3] power and heal equal to (target's max HP * [0.5, 1, 1.5]' "
		},
		
		{#3
		'name':'elephant',
		'tier': 4,
		'attack':5,
		'hp': 12,
		'types':['earthen','solar'],
		'desc':''
		},
		
	]

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	pass # Replace with function body.


func addSpot(parentNode):
	var newSpot = spotScene.instance()
	parentNode.add_child(newSpot)
	


