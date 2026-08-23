extends CharacterBody2D

#Nodes
@onready var GroundL: RayCast2D = $"Raycasts/Ground Left"
@onready var GroundR: RayCast2D = $"Raycasts/Ground Right"
@onready var LedgeF: RayCast2D = $"Raycasts/Ledge Grab Forward"
@onready var LedgeB: RayCast2D = $"Raycasts/Ledge Grab Back"
@onready var sprite: AnimatedSprite2D = $Sprite


#Ground Variables
var dash_dur = 10

#Landing based Variables
var landing_frames = 0
var lag_frames = 0
var perfect_wavedash_mod = .8

#Jump variables
var jump_squat_dur = 3
var fastfall : bool = false
var air_jump = 0
@export var max_air_jump = 1

#Ledge Variables
var last_ledge = false
var regrab = 30
var catch = false

#Attributes ripped from smash bros
var RUNSPEED = 340
var DASHSPEED = 390
var WALKSPEED = 200
var GRAVITY = 1800
var JUMPFORCE = 500
var MAXJUMPFORCE = 800
var DOUBLEJUMPFORCE = 1000
var MAXAIRSPEED = 300
var AIRACCEL = 25
var FALLSPEED = 60
var FALLINGSPEED = 900
var MAXFALLSPEED = 900
var TRACTION = 40
var ROLLDISTANCE = 350
var AIRDODGESPEED = 500
var UPSPECIALLAUNCHSPEED = 700


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

func play_animation(anim : String):
	sprite.play(anim)

func reset_ledge():
	last_ledge = false

func reset_jumps():
	air_jump = max_air_jump
