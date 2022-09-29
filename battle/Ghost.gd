extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var deading = true
onready var ghost = $Ghost
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func render(sprite):
	$Body.texture = sprite.texture
	$Ghost.texture = sprite.texture
	global_position = sprite.global_position + Vector2(0,30)
	scale = sprite.scale
func _process(delta):
	if deading:
		$Body.scale.y -= delta*0.25
		$Body.scale.x += delta*0.1
		
		
		if $Body.scale.y <=0.75:
			deading = false
	if $Body.modulate.r > 0.5:
		var cSpeed = 0.4
		$Body.modulate.r -= delta*cSpeed
		$Body.modulate.g -= delta*cSpeed
		$Body.modulate.b -= delta*cSpeed
		
	if is_instance_valid(ghost):
		$Ghost.global_position.y -= delta*20
		$Ghost.modulate.a -= 0.2*delta
		if $Ghost.modulate.a <= 0:
			$Ghost.queue_free()
	pass
