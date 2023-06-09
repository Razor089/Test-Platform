extends CharacterBody2D

@export_category("Movement")
@export var SPEED = 80
@export var FRICTION = 50
@export_category("Character Settings")
@export var HEALTH = 10
@export var DAMAGE = 5
@export var KNOCKBACK_VALUE = 20
@export var IS_INVULNERABLE: bool = false
@export_category("Debug")
@export var debug = false

# References
@onready var sprite = $Sprite2D
@onready var label = $DebugLabel
@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var swordPoint = $SwordAreaPoint
@onready var swordArea = $SwordAreaPoint/SwordArea

# State machine
enum {IDLE, FOLLOW, HIT, ATTACK, DEATH}
var state = IDLE

# Internal variables
var gravity = ProjectSettings.get("physics/2d/default_gravity")
var knockback = Vector2.ZERO
var direction = Vector2.ZERO
var target = null

# Internal booleans
var player_in_sight: bool = false
var is_player_at_range: bool = false

func _ready():
	animationTree.active = true

func _physics_process(_delta):
	if not is_on_floor():
		velocity.y += gravity * _delta
	match state:
		IDLE:
			idle_state()
		HIT:
			hit_state()
			knockback_move(_delta)
		FOLLOW:
			follow_state()
		DEATH:
			velocity.x = 0
		ATTACK:
			attack_state()
	move_and_slide()

func _process(_delta):
	update_debug_labels()
	check_if_player_is_in_sight()
	update_direction()
	update_animation()

func check_if_player_is_in_sight():
	if player_in_sight and state == IDLE and not is_player_at_range:
		state = FOLLOW

func idle_state():
	velocity.x = 0
	if is_player_at_range:
		state = ATTACK

func hit_state():
	velocity.x = 0

func attack_state():
	velocity.x = 0

func follow_state():
	#var direction = position.direction_to(target.position) # must try (reference_player.global_position - global_position).normalized()
	if not player_in_sight:
		state = IDLE
		
	direction = (target.global_position - global_position).normalized()
	velocity.x = direction.x * SPEED

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
		ATTACK:
			playback.travel("Attack")

func update_direction():
	if state == HIT:
		if knockback.x < 0:
			sprite.flip_h = false
			swordPoint.rotation_degrees = 0
		elif knockback.x > 0:
			sprite.flip_h = true
			swordPoint.rotation_degrees = 180
	else:
		if velocity.x > 0:
			sprite.flip_h = false
			swordPoint.rotation_degrees = 0
			swordArea.knockback_vector = Vector2.RIGHT
		elif velocity.x < 0:
			sprite.flip_h = true
			swordPoint.rotation_degrees = 180
			swordArea.knockback_vector = Vector2.LEFT

func knockback_move(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity += knockback

func damage(value):
	if not IS_INVULNERABLE:
		HEALTH -= value
		state = HIT
	if HEALTH <= 0:
		state = DEATH

func update_debug_labels():
	if debug:
		label.show()
	else:
		label.hide()
		
	match state:
		IDLE:
			label.text = "State: IDLE"
		ATTACK:
			label.text = "State: ATTACK"
		HIT:
			label.text = "State: HIT"
		FOLLOW:
			label.text = "State: FOLLOW"
		DEATH:
			label.text = "State: DEATH"

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "Death":
		queue_free()
	elif anim_name == "Hurt" and not state == DEATH:
		state = IDLE
	elif anim_name == "Attack":
		state = IDLE
		playback.travel("Idle")

func _on_enemy_sight_body_entered(body):
	if body.name == "PlayerKnight" and not state == DEATH:
		player_in_sight = true
		target = body

func _on_hit_area_body_entered(body):
	if body.name == "PlayerKnight" and not state == DEATH:
		is_player_at_range = true
		state = ATTACK

func _on_hit_area_body_exited(body):
	if body.name == "PlayerKnight":
		is_player_at_range = false

func _on_sword_area_area_entered(area):
	if area.name == "HitArea":
		area.damage(ATTACK)
		area.knockback = swordArea.knockback_vector * KNOCKBACK_VALUE

func _on_enemy_sight_body_exited(body):
	if body.name == "PlayerKnight":
		player_in_sight = false
