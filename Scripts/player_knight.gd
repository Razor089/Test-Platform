extends CharacterBody2D


@export var SPEED = 200.0
@export var ROLLING_SPEED = 250.0
@export var JUMP_VELOCITY = -300.0
@export var SECOND_JUMP_VELOCITY = -200.0
@export var FALL_VELOCITY = 300.0
@export var JUMP_BUFFER_TIME = 15
@export var COYOTE_TIME = 15

@onready var animatedSprite = $AnimatedSprite2D
@onready var sprite = $Sprite2D
@onready var animationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var animationPlayer = $AnimationPlayer
@onready var timer = $AttackTimer
@onready var slideCastRight = $SlideCastRight
@onready var slideCastLeft = $SlideCastLeft

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = Vector2.ZERO
var jump_buffer_counter = 0
var coyote_counter = 0

# internal booleans
var has_double_jump: bool = false
var animationLocked: bool = false
var can_attack: bool = true
var is_attacking: bool = false
var is_sliding:bool = false
var is_rolling: bool = false

func _ready():
	animationTree.active = true


func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		if coyote_counter > 0:
			coyote_counter -= 1
			
		velocity.y += gravity * delta
		
		if slideCastRight.is_colliding():
			if slideCastRight.get_collider().name == "Floor":
				FALL_VELOCITY = 100
		elif slideCastLeft.is_colliding():
			if slideCastLeft.get_collider().name == "Floor":
				FALL_VELOCITY = 100
		else:
			FALL_VELOCITY = 300
		
		if velocity.y > FALL_VELOCITY:
			velocity.y = FALL_VELOCITY
	else:
		coyote_counter = COYOTE_TIME
		has_double_jump = false
		can_attack = true
		is_sliding = false

	if Input.is_action_just_pressed("rolling") and is_on_floor():
		rolling()

# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if direction and not is_attacking and not is_rolling:
		velocity.x = direction * SPEED
	elif not is_rolling:
		velocity.x = move_toward(velocity.x, 0, SPEED)


	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept"):
		can_attack = false
		jump_buffer_counter = JUMP_BUFFER_TIME
		
		if jump_buffer_counter > 0:
			jump_buffer_counter -= 1
		
		if jump_buffer_counter > 0 and coyote_counter > 0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_counter = 0
			coyote_counter = 0
		elif not has_double_jump:
			velocity.y = SECOND_JUMP_VELOCITY
			has_double_jump = true

	# Handle attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		timer.start()
		playback.travel("Attack1")
	elif Input.is_action_just_pressed("attack") and is_attacking:
		timer.stop()
		is_attacking = true
		playback.travel("Attack2")

	move_and_slide()

func _process(_delta):
	animation_direction()
	update_animation()

func update_animation():
	animationTree.set("parameters/Move/blend_position", velocity.x)
	animationTree.set("parameters/conditions/landed", is_on_floor() and not is_attacking) # auto-travel to Move if player is on the floor
	
	if is_rolling:
		playback.travel("Roll")
	
	if velocity.y < 0:
		is_sliding = false
		playback.travel("Jump_start")
	elif velocity.y > 0:
		if slideCastRight.is_colliding() and slideCastRight.get_collider().name == "Floor":
			playback.travel("WallSlideRight")
			is_sliding = true
			has_double_jump = false
		elif slideCastLeft.is_colliding() and slideCastLeft.get_collider().name == "Floor":
			playback.travel("WallSlideLeft")
			is_sliding = true
			has_double_jump = false
		else:
			playback.travel("Jump_end")
	elif velocity.y == 0 and is_on_floor() and not is_rolling:
		playback.travel("Move")
		is_sliding = false

func animation_direction():
	if direction < 0:
		if not is_sliding:
			sprite.flip_h = true
		sprite.offset.x = -8
	elif direction > 0:
		if not is_sliding:
			sprite.flip_h = false
		sprite.offset.x = 0

func rolling():
	is_rolling = true
	if sprite.flip_h:
		velocity.x = -ROLLING_SPEED
	else:
		velocity.x = ROLLING_SPEED

func _on_attack_timer_timeout():
	is_attacking = false

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "Attack2":
		is_attacking = false
	elif anim_name == "Roll":
		is_rolling = false
		playback.travel("Move")

