extends CharacterBody3D


var SPEED = 5.0
const JUMP_VELOCITY = 4.5
var walk_spped = 5.0
var run_speed = 7.5


@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Camera3D
@onready var player: Node3D = $Head/Player
@onready var anime_tree: AnimationTree = $Head/Player/AnimationTree
@onready var skele: Skeleton3D = $Head/Player/Armature/Skeleton3D
@export var body: Node3D 



enum {IDLE,JUMP,WALK,RUN}
var current_anime = IDLE

var sens:float = 0.001
@export var x_value:float

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.current = is_multiplayer_authority()
	
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_released("esc"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sens)
		cam.rotate_x(-event.relative.y * sens)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-80) , deg_to_rad(90))
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	hiding_other_bodies()
	looking_animation_handler.rpc()
	animation_handler()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			current_anime = WALK
			SPEED = walk_spped
			if Input.is_action_pressed("Run"):
				SPEED = run_speed
				current_anime = RUN
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			current_anime = IDLE
	else:
		current_anime = JUMP
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 2.0)

	move_and_slide()

	
@rpc("any_peer","call_local")
func looking_animation_handler():
	x_value = -0.020851 + -cam.rotation.x
	x_value = clampf(x_value,-0.780025,0.639975)
	skele.set_bone_pose_rotation(1,Quaternion(x_value ,-0.012075, -0.017899, 0.999549))
	 


func animation_handler():
	match current_anime:
		IDLE: 
			anime_tree.set("parameters/Movement/transition_request","Idle")
		RUN:
			anime_tree.set("parameters/Movement/transition_request","Run")
		WALK:
			anime_tree.set("parameters/Movement/transition_request","Walk")
		JUMP:
			anime_tree.set("parameters/Movement/transition_request","Jump")
			
func hiding_other_bodies() -> void:
	if is_multiplayer_authority():
		body.hide()
	else:
		body.show()
	 
		
