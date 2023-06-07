extends Area2D

var player
var knockback = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent()

func damage(value):
	player.damage(value)
	player.knockback = knockback
