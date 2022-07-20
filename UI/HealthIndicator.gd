extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set(hp, maxHp, showMax = false):
	var hpPercent = float(hp-1)/float(maxHp-1)
	var r = 0
	var g 
	var b = 0.5
	r = min(-2.25*hpPercent +2.25, 1)
	g = min(2*hpPercent-0.35,1)
	b = max(hpPercent-0.5,0)
	#print('Hp percent: ',hpPercent)
	
	$HpLabel.add_color_override('font_color',Color(r,g,b,1).lightened(0.6) )
	var darkness = 0.2
	#print('r ', darkness*r)
	#print('g ', darkness*g)
	#print('b ', darkness*b)
	var bgColor = Color(r,g,b,1)
	#bgColor = CustomFormulas.changeSaturation(bgColor, -0.5)
	#$HealthRect.set_frame_color(bgColor)
	self_modulate = bgColor
	
	$HpLabel.text = str(hp)
	if showMax:
		$HpLabel.text = str(hp, '/',maxHp)
		
	if is_instance_valid($HealthBar):
		$HealthBar.modulate = Color(r,g,b)
		
		setupHealthBar(maxHp)
		$HealthBar.value = hp
		
func setupHealthBar(maxHp):
	var hb = $HealthBar
	var stdHp = 5
	if is_instance_valid(Global.player.battle):
		stdHp = Global.player.battle.averageHp
	$HealthBar.max_value = maxHp
	$HealthBar.value = maxHp
	var hpScale = float(maxHp)/float(stdHp)
	#if maxHp <= stdHp:
		
		#hb.rect_scale.x = hpScale
	#else:
	hb.rect_scale.y = hpScale
