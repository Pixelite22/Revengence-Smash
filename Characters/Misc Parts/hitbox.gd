extends Area2D

var parent = get_parent()
@export var width = 300 #Width of hitbox
@export var height = 400 #height of the hitbox
@export var damage = 50 #Damage to character caught in hitbox
@export var angle = 90 #angle the character hit is launched
@export var base_kb = 100 #minimum knockback deliverable
@export var kb_scaling = 2 #Controls how much knockback increases as damage increases
@export var duration = 1500 #How long (in frames) the hitbox lasts
@export var hitlag_mod = 1 #How long the player and opponent freeze when impact lands
@export var type = 'normal' #Hit Effects like Fire and Ice can go here
@export var angle_flipper = 0 #How does hitbox interact with opponent.  Examples of this include fliipping opponents (ala mario's cape), launching opponents inwards (like ness' lightning) or always launching in a single direction (like jigglypuff's rest)
@onready var hitbox = get_node("Hitbox Shape")
@onready var parent_state = get_parent().self_state

#Frame Variables
var kb_value
var frames = 0.0
var player_list = [] ##list of things the hitbox can't hit!  Like the player themselves


func set_params(wid, hgt, dmg, ang, bkb, kbs, dur, typ, pos, af, hlm, parent = get_parent()):
	self.position = Vector2(0, 0)
	player_list.append(parent) #Set player to the player list
	player_list.append(self) #as well as the hitbox itself incase there are multiple hitboxes that collide with themselves
	#Correctly match variables
	width = wid
	height = hgt
	damage = dmg
	angle = ang
	base_kb = bkb
	kb_scaling = kbs
	duration = dur
	type = typ
	self.position = pos
	hitlag_mod = hlm
	angle_flipper = af
	update_extents()
	connect("area_entered", hitbox_collide)
	set_physics_process(true)

func update_extents():
	hitbox.shape.extents = Vector2(width, height)

func _ready() -> void:
	hitbox.shape = RectangleShape2D.new() #This is a double check to ensure hit box is right shape
	set_physics_process(false) #makes sure hitbox does nothing before set to true
	pass

func _physics_process(delta: float) -> void:
	if frames < duration: #If the hitbox hasn't lasted as long as it should have yet
		frames += 1 #increment the frame counter
	elif frames >= duration: #If the hitbox has lasted as long or longer then it should have
		Engine.time_scale = 1 #set engine time scale to 1, incase it was set differently for something like hitfreeze
		queue_free() #and delete itself
		return
	if get_parent().self_state != parent_state: #if we are no longer attacking
		#repeat hitbox removal code above
		Engine.time_scale = 1
		queue_free()
		return

#Most complicated function and will do at a later point
func hitbox_collide():
	pass
