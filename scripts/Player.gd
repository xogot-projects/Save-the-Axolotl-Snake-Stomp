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

@onready var skeleton_animation_player := $Pivot/Player_Axolotl/AnimationPlayer
@onready var animation_player := $AnimationPlayer 

var target_velocity = Vector3.ZERO

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
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		jump()
	
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
