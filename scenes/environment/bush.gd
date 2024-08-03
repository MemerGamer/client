extends Area3D


func _on_body_entered(body):
	body.hide()


func _on_body_exited(body):
	body.show()
