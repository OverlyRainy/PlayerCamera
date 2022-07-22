extends Camera2D
class_name PlayerCamera

#Follow Variables
var targets = [] #Array of targets being tracked by the cam
export(float, 0.01, 1, 0.01) var smooth_follow_factor: float = 0.5 #0.01 = slow, 0.1 = fast, 0.5 = very fast, 1 = instant
var time_scale: float = 1.0 #Used to adjust camera follow rate with changes in time scale

#Shake Settings
export(bool) var screen_shake = true #Allow screen shake
export(float, 0, 1, 0.1) var shake_magnitude = 1 #How strong the shake should be, 0 = no shake
export(int, 2, 3, 1) var directional_trauma_exponent = 2 #Squared or cubed trauma exponent
export(int, 2, 3, 1) var noise_trauma_exponent = 2 #Squared or cubed trauma exponent
export(float, 0, 1, 0.1) var directional_trauma_decay_rate = 0.8 #How quickly trauma will decay
export(float, 0, 1, 0.1) var noise_trauma_decay_rate = 0.8 #How quickly trauma will decay
#Shake Limits
var min_trauma_magnitude: float = 0.0 #min limit for trauma magnitude
var max_trauma_magnitude: float = 1.0 #max limit for trauma magnitude
export var max_shake_offset = Vector2(100, 75) #Max position offset during shake
export var max_shake_roll = 0.1 #Max radians to rotate during shake
#Directional Shake
var trauma_direction: Vector2 = Vector2.ZERO
#Noise Shake
onready var noise = OpenSimplexNoise.new()
var noise_y = 0
var noise_direction: Vector2 = Vector2.ZERO
#Current Shake 
var current_directional_trauma = 0.0 #Current level of directional shake
var current_noise_trauma = 0.0 #Current level of noise shake

#Pixel Perfect Variables
export(bool) var pixel_perfect = true #Will round camera position to whole numbers

#Follow
func add_target(target):
	if not target in targets:
		targets.append(target)

func remove_target(target):
	if target in targets:
		targets.erase(target)

func follow_targets():
	var target_position = Vector2.ZERO
	for target in targets:
		target_position += target.global_position
	target_position /= targets.size()
	global_position.x += (target_position.x - global_position.x) * smooth_follow_factor * time_scale
	global_position.y += (target_position.y - global_position.y) * smooth_follow_factor * time_scale

#Shake
func add_directional_trauma(trauma: float, direction: Vector2):
	current_directional_trauma = min(current_directional_trauma + trauma, max_trauma_magnitude)
	
	trauma_direction.x = direction.normalized().x
	trauma_direction.y = direction.normalized().y

func add_noise_trauma(trauma: float):
	current_noise_trauma = min(current_noise_trauma + trauma, max_trauma_magnitude)

func generate_noise():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func shake_screen():
	var direction_amount = pow(current_directional_trauma, directional_trauma_exponent)
	var noise_amount = pow(current_noise_trauma, noise_trauma_exponent)
	noise_y += 1 #scroll noise texture
	
	rotation = max_shake_roll * (noise_amount * noise.get_noise_2d(noise.seed, noise_y))
	offset.x = max_shake_offset.x * ((noise_amount * noise.get_noise_2d(noise.seed * 2, noise_y)) + (direction_amount * trauma_direction.x)) * shake_magnitude
	offset.y = max_shake_offset.y * ((noise_amount * noise.get_noise_2d(noise.seed * 3, noise_y)) + (direction_amount * trauma_direction.y)) * shake_magnitude

#Pixel Perfect Camera Position Update
func pixel_perfect_pos():
	#round cam position
	global_position.x = round(global_position.x)
	global_position.y = round(global_position.y)
	#round offset value
	offset.x = round(offset.x)
	offset.y = round(offset.y)

#Start
func _ready():
	generate_noise()

#Fixed Update
func _physics_process(delta):
	if targets:
		follow_targets()
	else:
		print("Cam: no targets found.")
	
	#Apply shake_screen() if there is trauma and screen shake is enabled
	if screen_shake:
		if current_directional_trauma or current_noise_trauma:
			#decay and clamp current trauma values
			current_directional_trauma = max(current_directional_trauma - directional_trauma_decay_rate * delta, min_trauma_magnitude)
			current_noise_trauma = max(current_noise_trauma - noise_trauma_decay_rate * delta, min_trauma_magnitude)
			shake_screen()
	
	#Round camera positions to pixel perfect values
	if pixel_perfect:
		pixel_perfect_pos()
