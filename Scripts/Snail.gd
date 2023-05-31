extends CharacterBody2D

@export var SPEED = 100.0
@export var HEALTH = 5

@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var sightArea = $MarkerSight
@onready var rayCastFloor = $RayCastFloor

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
	
	checkFloor()
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update_animation()
	update_facing_sprite()

func checkFloor():
	if not rayCastFloor.is_colliding():
		random_result *= -1

func update_animation():
	animationTree.set("parameters/Move/blend_position", direction)

func update_facing_sprite():
	if random_result < 0:
		sprite.flip_h = false
		sightArea.rotation_degrees = 0
		rayCastFloor.position.x = -13
	elif random_result > 0:
		sprite.flip_h = true
		sightArea.rotation_degrees = 180
		rayCastFloor.position.x = 13

func _on_timer_timeout():
	random_result = random.randi_range(-1, 1)
	timer.start()

func _on_sight_area_body_entered(_body):
	playback.travel("Hide")
	is_hiding = true
	is_vulnerable = false

func _on_sight_area_body_exited(_body):
	playback.travel("GetOut")

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "GetOut":
		is_hiding = false
		is_vulnerable = true

func death():
	pass

func damage(value):
	if is_vulnerable:
		playback.travel("Hit")
		HEALTH -= value
	if HEALTH <= 0:
		queue_free()
