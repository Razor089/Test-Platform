extends CharacterBody2D

@export_category("Movements")
@export var SPEED = 200.0
@export var JUMP_SPEED = -300
@export var ROLL_SPEED = 280.0
@export var FALL_SPEED = 300
@export var SLIDE_SPEED = 100
@export var FRICTION = 50
@export_category("Stats")
@export var HEALTH = 200
@export_category("Timers")
@export var JUMP_BUFFER_TIME = 15
@export var COYOTE_BUFFER_TIME = 15
@export var ATTACK_BUFFER_TIME = 15
@export var CHAIN_ATTACK_BUFFER = 15
@export_category("Attack")
@export var SWORD_ATTACK_VALUE = 2
@export var KNOCKBACK_VALUE = 15

# References
@onready var sprite = $Sprite2D
@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var swordBox = $SwordArea/SwordBox
@onready var swordArea = $SwordArea
@onready var slideCastLeft = $SlideCastLeft
@onready var slideCastRight = $SlideCastRight

# Getting gravity value from settings
var gravity = ProjectSettings.get("physics/2d/default_gravity")

# Internal variables
var direction = 0
var knockback = Vector2.ZERO
var jump_counter = 0
var coyote_counter = 0
var attack_counter = 0
var chain_counter = 0
var state = IDLE

# State machine
enum {IDLE, ATTACK, ROLL, SLIDE, DEATH, HIT}

func _ready():
	animationTree.active = true
	swordBox.disabled = true

func _physics_process(delta):
	if jump_counter > 0:
		jump_counter -= 1
	
	if attack_counter > 0:
		attack_counter -= 1
	
	if chain_counter > 0:
		chain_counter -= 1
	
	match state:
		IDLE:
			add_gravity(delta, FALL_SPEED)
			handle_input()
			move()
		ATTACK:
			handle_input()
			attack()
		ROLL:
			add_gravity(delta, FALL_SPEED)
			handle_input()
			roll()
		SLIDE:
			add_gravity(delta, SLIDE_SPEED)
			handle_input()
			slide()
		HIT:
			add_gravity(delta, FALL_SPEED)
			#hit_state()
			knockback_move(delta)
	
	move_and_slide()

func add_gravity(delta, limit):
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > limit:
			velocity.y = limit
		if coyote_counter > 0:
			coyote_counter -= 1
	else:
		coyote_counter = COYOTE_BUFFER_TIME

func _process(_delta):
	facing_direction()
	update_animation()

func hit_state():
	velocity.x = 0

func knockback_move(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity = knockback

func handle_input():
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		direction = Input.get_axis("ui_left", "ui_right")
	else:
		joypad_controller()
	
	if Input.is_action_just_pressed("rolling"):
		state = ROLL
	
	if Input.is_action_just_pressed("jump"):
		jump_counter = JUMP_BUFFER_TIME
		
	if is_on_floor() and Input.is_action_just_pressed("attack"):
		state = ATTACK
		chain_counter = CHAIN_ATTACK_BUFFER

func joypad_controller():
	if Input.is_action_pressed("left"):
		direction = -1
	elif Input.is_action_pressed("right"):
		direction = 1
	else:
		direction = 0

func move():
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if jump_counter > 0 and  coyote_counter > 0:
		velocity.y = JUMP_SPEED
		jump_counter = 0
	
	if not is_on_floor() and velocity.y > 0:
		if slideCastLeft.is_colliding() or slideCastRight.is_colliding():
			state = SLIDE

func roll():
	if sprite.flip_h:
		velocity.x = -ROLL_SPEED
	else:
		velocity.x = ROLL_SPEED

func attack():
	velocity.x = 0

func slide():
	if is_on_floor():
		state = IDLE
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if not slideCastLeft.is_colliding() and not slideCastRight.is_colliding():
		state = IDLE
	
	if jump_counter > 0:
		velocity.y = JUMP_SPEED
		state = IDLE
		if slideCastLeft.is_colliding():
			velocity.x = 600
		elif slideCastRight.is_colliding():
			velocity.x = -600
		jump_counter = 0

func update_animation():
	animationTree.set("parameters/Move/blend_position", direction)
	match state:
		IDLE:
			if velocity.y < 0:
				playback.travel("Jump_start")
			elif velocity.y > 0:
				playback.travel("Jump_end")
			else:
				playback.travel("Move")
		ATTACK:
			if attack_counter > 0:
				playback.travel("Attack2")
			else:
				playback.travel("Attack1")
		ROLL:
			playback.travel("Roll")
		SLIDE:
			if slideCastLeft.is_colliding() and slideCastLeft.get_collider():
				playback.travel("WallSlideLeft")
			elif slideCastRight.is_colliding() and slideCastRight.get_collider():
				playback.travel("WallSlideRight")
		HIT:
			playback.travel("Hit")

func facing_direction():
	if state == HIT:
		if knockback.x > 0:
			sprite.flip_h = true
			sprite.position.x = -4
		elif knockback.x < 0:
			sprite.flip_h = false
			sprite.position.x = 4
	else:
		if direction > 0:
			if not state == SLIDE:
				sprite.flip_h = false
			sprite.position.x = 4
			swordArea.rotation_degrees = 0
			swordArea.knockback_vector = Vector2.RIGHT
		elif direction < 0:
			if not state == SLIDE:
				sprite.flip_h = true
			sprite.position.x = -4
			swordArea.rotation_degrees = 180
			swordArea.knockback_vector = Vector2.LEFT


func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "Roll":
		state = IDLE
	elif anim_name == "Attack1":
		state = IDLE
		playback.travel("Move") # Ho bisogno di mettere qui il travel altrimenti si genera una sequenza aggiuntiva di animazione 
		attack_counter = ATTACK_BUFFER_TIME
	elif anim_name == "Attack2":
		if chain_counter > 0:
			state = ATTACK
			attack_counter = 0
		else:
			state = IDLE
		playback.travel("Move") # Ho bisongo di mettere qui il travel altrimenti si generea una sequenza aggiuntiva di animazione
	elif anim_name == "Hit":
		state = IDLE

func damage(value):
	HEALTH -= value
	state = HIT
	if HEALTH <= 0:
		state = DEATH

func _on_sword_area_body_entered(body):
	if body.name == "Snail" or "Enemy_Knight":
		body.damage(SWORD_ATTACK_VALUE)
		if body.name == "Enemy_Knight":
			body.knockback = swordArea.knockback_vector * KNOCKBACK_VALUE

