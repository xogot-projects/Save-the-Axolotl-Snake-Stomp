extends CharacterBody3D

signal hit

## How fast the player moves in meters per second.
@export var speed = 14
## Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
## Vertical impulse applied to the character upon bouncing over a mob in meters per second.
@export var bounce_impulse = 16
## The downward acceleration when in the air, in meters per second.
@export var fall_acceleration = 75
## Grace period (in seconds) after leaving the ground during which the player
## can still jump. This is "coyote time": for a brief moment after walking off
## a ledge, the game pretends the player is still on the floor, so a
## slightly-late jump press still works. Especially helpful on a touch screen,
## where input latency eats a few frames.
@export var coyote_time := 0.1
## How long (in seconds) to remember a jump press that happened while the
## player was still in the air. This is "jump buffering": if the player presses
## jump a hair too early while falling toward the ground, the press is buffered
## and fires the instant they land, instead of being swallowed.
@export var jump_buffer := 0.1

@onready var skeleton_animation_player := $Pivot/Player_Axolotl/AnimationPlayer
@onready var animation_player := $AnimationPlayer

var target_velocity = Vector3.ZERO
# Counts down from coyote_time while the player is in the air. Reset to
# coyote_time every frame they are on the floor.
var _coyote_timer := 0.0
# Counts down from jump_buffer after a jump press. Reset to jump_buffer on
# every fresh press of the jump action.
var _jump_buffer_timer := 0.0

func _physics_process(delta):
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		# In the lines below, we turn the character when moving and make the animation play faster.
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		basis = Basis.looking_at(direction)
		
	if direction != Vector3.ZERO && is_on_floor():
		skeleton_animation_player.current_animation = "Run"
		skeleton_animation_player.speed_scale = 4
	else:
		skeleton_animation_player.current_animation = "Idle"
		skeleton_animation_player.speed_scale = 1

	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	# --- Coyote time ---
	# Keep the coyote window open while on the ground; tick it down once the
	# player is in the air. While it is above zero, the player may still jump
	# as if they were on the floor.
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(0.0, _coyote_timer - delta)

	# --- Jump buffering ---
	# On a fresh jump press, fill the buffer. Otherwise tick it down so a
	# stale press eventually expires. We use is_action_just_pressed so holding
	# the button does not keep refilling the buffer forever.
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer
	else:
		_jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)

	# --- Jump ---
	# Fire when there is both a buffered press AND a valid coyote window.
	# Using both timers (instead of is_on_floor() alone) is what gives us the
	# forgiving feel: a press a few frames early or a press a few frames
	# after leaving a ledge both still jump. Clearing both timers on a
	# successful jump prevents double-jumping off the coyote window.
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		jump()
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	velocity = target_velocity
	move_and_slide()

	# This makes the character follow a nice arc when jumping
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse


func jump() -> void:
	# Define the target velocity for the jump
	target_velocity.y = jump_impulse
	# Switch the player to idle animation
	skeleton_animation_player.current_animation = "Idle"
	animation_player.play("jump")
	# Ensure the idle plays at normal speeds during the jump
	skeleton_animation_player.speed_scale = 1


func bounce() -> void:
	target_velocity.y = bounce_impulse
	animation_player.play("jump")


func die():
	hit.emit()
	queue_free()
