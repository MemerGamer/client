extends RichTextLabel
class_name MatchTimer

var map_node: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	map_node = get_node("../../..")
	pass  # Replace with function body.


func _process(_delta: float):
	set_time(map_node.time_elapsed)


func set_time(t: int):
	var sec: int = t % 60
	var _min := int((t - sec) / 60.0)
	var hour := int(_min / 60.0)
	_min = _min % 60

	text = ""
	if hour > 0:
		if hour < 10:
			text = "0"

		text += str(hour) + ":"

	if _min < 10:
		text = "0"

	text += str(_min) + ":"

	if sec < 10:
		text += "0"

	text += str(sec)
