extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal choiceMade

var choiceInfo
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func generateChoice(stage):
	var positiveId = 'coins'
	var negativeDesc = 'All enemies gain +1 power'
	var positiveDesc = 'Gain 2 extra coins if you win'
	
	$ChoiceLabel.append_bbcode(positiveDesc)
	$ChoiceLabel.newline()
	$ChoiceLabel.append_bbcode('BUT')
	$ChoiceLabel.newline()
	$ChoiceLabel.append_bbcode(negativeDesc)
	choiceInfo = {'loot':'coins2'} 


func _on_Accept_pressed():
	emit_signal("choiceMade", choiceInfo)
	pass # Replace with function body.


func _on_Decline_pressed():
	emit_signal("choiceMade", null)
	pass # Replace with function body.
