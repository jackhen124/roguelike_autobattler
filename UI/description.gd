extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var elementName = null
# Called when the node enters the scene tree for the first time.
func _ready():
	#generateDesc('keyword: do something, on-attack: do something else')
	pass # Replace with function body.


func generateDesc(string):
	
	text = ''
	var curWord = ''
	var curText = ''
	
	for i in string.length():
		if string[i] == ' ' || i == string.length()-1 || string[i] == ':':
			#print(curWord)
			var skipCurLetter = false
			if i == string.length()-1:
				curWord += string[i]
				skipCurLetter = true
			if Global.keywords.has(curWord) || Global.elementLibrary.has(curWord):
				if string[i] == ':':
					skipCurLetter = true
					curText += generateKeywordText(curWord, string[i])
				else:
					curText += generateKeywordText(curWord)
			
				
			elif curWord == 'unitsNeeded' || curWord == 'effectPerStack':
				curText += generateKeywordText(curWord)
				pass
			else:
				curText += curWord
			if !skipCurLetter:
				curText += string[i]
			#print(curWord)
			curWord = ''
			
		else:
			curWord += string[i]
		i+=1
	append_bbcode(curText)
	pass
	
 
func generateKeywordText(keyword, suffix = ''):
	print('generating keyword text ', keyword)
	var before = []
	var after = []
	#before.append('color=red')
	#after.append('color')
	
	if keyword == 'unitsNeeded' || keyword == 'effectPerStack':
		#keyword = str(Global.elementLibrary[elementName]['unitsNeeded'])
		keyword = elementString(keyword)
		if Global.elementLibrary[elementName].has('color'):
			if Global.elementLibrary[elementName]['color'] != '':
				before.append(str('color=',Global.elementLibrary[elementName]['color']))
				after.append('color')
	if Global.elementLibrary.has(keyword):
		if Global.elementLibrary[keyword].has('color'):
			if Global.elementLibrary[keyword]['color'] != '':
				before.append(str('color=',Global.elementLibrary[elementName]['color']))
				after.append('color')
	elif Global.keywords.has(keyword):
		
		if Global.keywords[keyword].has('color'):
			if Global.keywords[keyword]['color'] != '':
				before.append(str('color=',Global.keywords[keyword]['color']))
				after.append('color')
	#[fade start=4 length=14][/fade]
	keyword = keyword.to_upper()+ suffix
	
	var result = ''
	for i in before.size():
		result += str('[',before[i],']')
	result += keyword
	for i in after.size():
		
		result += str('[/',after[after.size()-1-i],']')
	
	print(result)
	
	return result
	#return str('[',modifier,']',keyword, '[/',modifier,']')

func elementString(string):
	var result = ''
	var unitsNeeded = Global.elementLibrary[elementName]['unitsNeeded']
		
	for i in unitsNeeded.size():
		result += str(unitsNeeded[i])
		if i+1 < unitsNeeded.size():
			result += '/'
		
	return result
