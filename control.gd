@tool
extends Control
 
@export var speed:Vector3 
var off:Vector3 = Vector3.ZERO
 
func _process(delta):
	off += speed*delta
	$"TextureRect".texture.noise.offset = off
#   ^
#   |
#   Change the node path accordingly
