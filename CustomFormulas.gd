extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func diff(v1, v2):
	return abs(max(v2,v1) - min(v2,v1))


func convertRadiansToVector(radians):
	var x = cos(radians)
	var y = sin(radians)
	return Vector2(x,y)

func moveThrough(start, end, dis):
	var dirVector = start.direction_to(end)
	return start + dirVector*dis


func proportion(v0, v1, ratio):
	#v0 is the return value if ratio == 0/1
	#v2 is the return value if ratio == 1/1

	if ratio < 0:
	#print('proportion not expecting negative ratio: ', ratio)
		ratio = abs(ratio)

	var diff = abs(max(v0,v1) - min(v0,v1))
	var result

	if v1<v0: # goes down as ratio goes up
		result = v0 - diff*ratio
	else:
		result = v0 + diff*ratio

	#print('proprtion returning ', result, ', V1: ',v0,', V2: ', v1, ', Ratio: ', ratio)

	return result

func changeSaturation(color, satValue):
	var result
	if satValue < 0:
		var prop = abs(satValue)/1
		var gray = color.gray()
		var r = proportion(color.r, gray, prop)
		var g = proportion(color.g, gray, prop)
		var b = proportion(color.b, gray, prop)
		result = Color(r,g,b,color.a)
	else:
		result = color
		print('increase saturation not implemented! use negative saturation value')
	return result


func redToGreen(value):
# value should be from 0 to 1
	var r = min(-2.25*value +2.25, 1)

	var g = min(2*value-0.2,1)
	#var g = min(2*correctness-0.5,1)
	var b = max(value-0.5,0)

	#print( 'green to red ratio: ', value, 'Color( R: ', r, ', G: ', g , ', B: ', b)

	return Color(r,g,b)
