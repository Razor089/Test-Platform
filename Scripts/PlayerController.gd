extends CharacterBody2D

@export_category("Movements")
@export var SPEED = 200.0
@export var JUMP_SPEED = -300
@export var ROLL_SPEED = 280.0
@export var FALL_SPEED = 300
@export var SLIDE_SPEED = 100
@export_category("Timers")
@export var JUMP_BUFFER_TIME = 15
@export var COYOTE_BUFFER_TIME = 15
@export var ATTACK_BUFFER_TIME = 15
@export_category("Attack")
@export var SWORD_ATTACK_VALUE = 2

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
var jump_counter = 0
var coyote_counter = 0
var attack_counter = 0
var state = IDLE

# State machine
enum {IDLE, ATTACK, ROLL, SLIDE}

func _ready():
	animationTree.active = true
	swordBox.disabled = true

func _physics_process(delta):
	if jump_counter > 0:
		jump_counter -= 1
	
	if attack_counter > 0:
		attack_counter -= 1
	
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

func handle_input():
	direction = Input.get_axis("ui_left", "ui_right")
	
	if Input.is_action_just_pressed("rolling"):
		state = ROLL
	
	if Input.is_action_just_pressed("jump"):
		jump_counter = JUMP_BUFFER_TIME
		
	if is_on_floor() and Input.is_action_just_pressed("attack"):
		state = ATTACK
		print(swordArea.knockback_vector)

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

func facing_direction():
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
		state = IDLE
		playback.travel("Move") # Ho bisongo di mettere qui il travel altrimenti si generea una sequenza aggiuntiva di animazione


func _on_sword_area_body_entered(body):
	if body.name == "Snail" or "Enemy_Knight":
		body.damage(SWORD_ATTACK_VALUE)
		if body.name == "Enemy_Knight":
			body.knockback = swordArea.knockback_vector * 10
