extends CharacterBody2D

@export var SPEED = 100.0
@export var HEALTH = 5

@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var sightArea = $MarkerSight

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var random = RandomNumberGenerator.new()
var random_result = 0
var direction = 0

# Internal boolean
var is_hiding: bool = false
var is_vulnerable: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	animationTree.active = true
	random_result = random.randi_range(-1, 1)
	timer.start()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor():
		direction = random_result
	else:
		direction = 0
	
	if direction and not is_hiding:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_animation()
	update_facing_sprite()

func update_animation():
	animationTree.set("parameters/Move/blend_position", direction)

func update_facing_sprite():
	if velocity.x < 0:
		sprite.flip_h = false
		sightArea.rotation_degrees = 0
	elif velocity.x > 0:
		sprite.flip_h = true
		sightArea.rotation_degrees = 180

func _on_timer_timeout():
	random_result = random.randi_range(-1, 1)
	timer.start()

func _on_sight_area_body_entered(body):
	playback.travel("Hide")
	is_hiding = true
	is_vulnerable = false

func _on_sight_area_body_exited(body):
	playback.travel("GetOut")

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "GetOut":
		is_hiding = false
		is_vulnerable = true
