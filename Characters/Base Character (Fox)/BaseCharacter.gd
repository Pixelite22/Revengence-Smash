extends CharacterBody2D

#Nodes
@onready var GroundL: RayCast2D = $"Raycasts/Ground Left"
@onready var GroundR: RayCast2D = $"Raycasts/Ground Right"
@onready var LedgeF: RayCast2D = $"Raycasts/Ledge Grab Forward"
@onready var LedgeB: RayCast2D = $"Raycasts/Ledge Grab Back"
@onready var sprite: AnimatedSprite2D = $Sprite

#Hitbox Variables
@export_group("Hitboxes")
@export var hitbox : PackedScene
var self_state

#Ground Variables
@export_group("Ground")
var dash_dur = 10

#Landing based Variables
@export_group("Landing")
var landing_frames = 0
var lag_frames = 0
var perfect_wavedash_mod = .8

#Jump variables
@export_group("Jumping")
var jump_squat_dur = 3
var fastfall : bool = false
var air_jump = 0
@export var max_air_jump = 1

#Ledge Variables
@export_group("Ledge")
var last_ledge = false
var regrab = 30
var catch = false

#Attributes ripped from smash bros
@export_group("Important Attributes")
@export var RUNSPEED = 340
@export var DASHSPEED = 390
@export var WALKSPEED = 200
@export var GRAVITY = 1800
@export var JUMPFORCE = 500
@export var MAXJUMPFORCE = 800
@export var DOUBLEJUMPFORCE = 1000
@export var MAXAIRSPEED = 300
@export var AIRACCEL = 25
@export var FALLSPEED = 60
@export var FALLINGSPEED = 900
@export var MAXFALLSPEED = 900
@export var TRACTION = 40
@export var ROLLDISTANCE = 350
@export var AIRDODGESPEED = 500
@export var UPSPECIALLAUNCHSPEED = 700


@onready var state: Label = $State

#frame counter
var frame = 0

func update_frames(delta):
	frame += 1 #updates frame every delta

func turn(direction): #Flips character sprite based on direction faced
	var dir = 0 #start with none
	if direction: #if direction passed is true
		dir = -1 #face to the left
	else: #otherwise
		dir = 1 #face the right
	$Sprite.set_flip_h(direction) #Send the direction in to actually do the flip
	LedgeF.target_position = Vector2(dir * abs(LedgeF.target_position.x), LedgeF.target_position.y)
	LedgeF.position.x = dir * abs(LedgeF.position.x)
	LedgeB.target_position = Vector2(-dir * abs(LedgeF.target_position.x), LedgeF.target_position.y)
	LedgeB.position.x = dir * abs(LedgeB.position.x)

func direction():
	if LedgeF.target_position.x > 0:
		return 1
	else:
		return -1

func frame_reset(): #Called when we need to reset frame count
	frame = 0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	$Frames.text = str(frame) #Display frame count for debugging purposes
	self_state = state.text

func play_animation(anim : String):
	sprite.play(anim)

func reset_ledge():
	last_ledge = false

func reset_jumps():
	air_jump = max_air_jump

func create_hitbox(wid, hgt, dmg, ang, bkb, kbs, dur, typ, points, af, hitlag = 0):
	var hitbox_instance = hitbox.instantiate() #instantiate the scene
	self.add_child(hitbox_instance) #add it to the tree
	#Rotate the points as needed, depending on direction faced
	if direction() == 1: #if facing right, pass almost one to one
		hitbox_instance.set_params(wid, hgt, dmg, ang, bkb, kbs, dur, typ, points, af, hitlag)
	else: #if facing left, pass it all again, but flip the angle and points
		var flip_x_points = Vector2(-points.x, points.y)
		hitbox_instance.set_params(wid, hgt, dmg, -ang + 180, bkb, kbs, dur, typ, flip_x_points, af, hitlag)
	return hitbox_instance

##ATTACK FUNCTIONS
#Tilt Attacks
func down_tilt():
	if sprite.animation == "Tilt Down":
		if sprite.frame == 1: #need to change this for each character
			create_hitbox(50, 25, 8, 90, 3, 120, 3, 'normal', Vector2(41, 22), 0, 1)
		if sprite.frame == 2:
			return true

func forward_tilt():
	if sprite.animation == "Tilt Forward":
		if sprite.frame == 1:
			create_hitbox(46, 16, 8, 45, 3, 120, 3, 'normal', Vector2(31, 6), 0, 1)
		if sprite.frame == 2:
			return true

func up_tilt():
	if sprite.animation == "Tilt Up":
		if sprite.frame == 1:
			create_hitbox(69, 62, 8, 90, 3, 120, 3, 'normal', Vector2(1.5, 1.0), 0, 1)
		if sprite.frame == 2:
			return true
