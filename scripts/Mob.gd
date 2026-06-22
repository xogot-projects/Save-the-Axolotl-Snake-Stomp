extends CharacterBody3D

# Emitted when the player jumped on the mob. Passes the body that entered.
signal squashed(by: Node3D)

## Minimum speed of the mob in meters per second.
@export var min_speed = 10
## Maximum speed of the mob in meters per second.
@export var max_speed = 18

## Set min and max animation speeds so that it feels more natural and realistic
var min_anim_speed = 0.5
var max_anim_speed = 1.5

# Preload the animation players for the snake
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton_animation_player: AnimationPlayer = $Pivot/enemy_snake/AnimationPlayer

func _physics_process(_delta):
	move_and_slide()


func initialize(start_position, player_position):
	# Ignore the player's height, so that the mob's orientation is not slightly
	# shifted if the mob spawns while the player is jumping.
	var target = Vector3(player_position.x, 0, player_position.z)
	look_at_from_position(start_position, target, Vector3.UP)

	# Rotate this mob randomly within range of -45 and +45 degrees,
	# so that it doesn't move directly towards the player.
	rotate_y(randf_range(-PI / 4, PI / 4))

	var random_speed = randf_range(min_speed, max_speed)
	# We calculate a forward velocity first, which represents the speed.
	velocity = Vector3.FORWARD * random_speed
	# We then rotate the vector based on the mob's Y rotation to move in the direction it's looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)

	_sync_animation_speed(random_speed)

func _sync_animation_speed(speed: float) -> void:
	# Sync the animation speeds between the two players so that the scale increases at random
	var value = inverse_lerp(min_speed, max_speed, speed)
	var animation_speed = lerp(min_anim_speed, max_anim_speed, value)
	animation_player.speed_scale = animation_speed
	skeleton_animation_player.speed_scale = animation_speed


func squash(by: Node3D = null) -> void:
	squashed.emit(by)
	queue_free()


func _on_hit_box_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.velocity.y < 0:
		squash(body)


func _on_hurt_box_body_entered(body: Node3D) -> void:
	if not body.has_method("die"):
		return
	if body is CharacterBody3D and not body.is_on_floor():
		return
	body.die()


func _on_visible_on_screen_notifier_screen_exited():
	queue_free()
