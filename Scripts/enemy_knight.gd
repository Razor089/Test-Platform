extends CharacterBody2D

@export_category("Movement")
@export var SPEED = 80
@export var FRICTION = 50
@export_category("Character Settings")
@export var HEALTH = 10
@export var DAMAGE = 5

# References
@onready var sprite = $Sprite2D
@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")

# State machine
enum {IDLE, FOLLOW, HIT, ATTACK, DEATH}
var state = IDLE

# Internal variables
var gravity = ProjectSettings.get("physics/2d/default_gravity")
var knockback = Vector2.ZERO
var direction = Vector2.ZERO
var target

# Internal booleans
var player_in_sight: bool = false

func _ready():
	animationTree.active = true

func _physics_process(_delta):
	match state:
		IDLE:
			idle_state()
		HIT:
			hit_state()
			knockback_move(_delta)
		FOLLOW:
			follow_state(_delta)
		DEATH:
			velocity.x = 0
	move_and_slide()


func _process(_delta):
	if player_in_sight and not state == HIT and not state == DEATH:
		state = FOLLOW
	update_direction()
	update_animation()

func idle_state():
	velocity.x = 0

func hit_state():
	velocity.x = 0

func follow_state(delta):
	#var direction = position.direction_to(target.position) # must try (reference_player.global_position - global_position).normalized()
	direction = (target.global_position - global_position).normalized()
	#if direction.x > 0:
	#	velocity.x = 1 * SPEED
	#elif direction.x < 0:
	#	velocity.x = -1 * SPEED
	velocity.x = direction.x * SPEED
	velocity.y += gravity * delta

func update_animation():
	animationTree.set("parameters/Idle/blend_position", velocity.x)
	match state:
		IDLE:
			playback.travel("Idle")
		FOLLOW:
			playback.travel("Idle")
		HIT:
			playback.travel("Hurt")
		DEATH:
			playback.travel("Death")

func update_direction():
	if state == HIT:
		if knockback.x < 0:
			sprite.flip_h = false
		elif knockback.x > 0:
			sprite.flip_h = true
	else:
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true

func knockback_move(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity += knockback

func damage(value):
	HEALTH -= value
	state = HIT
	if HEALTH <= 0:
		state = DEATH

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "Death":
		queue_free()
	elif anim_name == "Hurt" and not state == DEATH:
		state = IDLE

func _on_enemy_sight_body_entered(body):
	if body.name == "PlayerKnight":
		player_in_sight = true
		target = body
