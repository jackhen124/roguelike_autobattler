extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal collected
var type = ''
var amount = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func render(lootData):
	type = lootData['type']
	amount = lootData['amount']
	if type == 'coins':
		$Loot/CoinLabel.show()
		
		$Loot/CoinLabel.setCoins(amount)
		
		


func _on_CollectButton_pressed():
	$Loot.modulate.a = 0
	disabled = true
	
	if $Loot.visible:
		emit_signal("collected", self)
		$Loot.hide()
	pass # Replace with function body.
