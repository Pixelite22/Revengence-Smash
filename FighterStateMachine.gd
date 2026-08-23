extends Node
class_name StateMachine

var state = null: set = set_state
var prev_state = null
var states = {}

@onready var parent = get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if state != null: #if there is a state currently
		state_logic(delta) #run the state logic
		var transition = get_transition(delta) #create a transition variable to run get transition
		if transition != null: #if there is a transition value
			set_state(transition) #set the state with the transition value

func state_logic(delta):
	pass

func get_transition(delta): ##this function is overwritten by the individual character ones and if this one is reached it will return null
	return null

func enter_state(new_state, old_state):
	pass

func exit_state(old_state, new_state):
	pass

func set_state(new_state):
	prev_state = state #set the current state to the previous state
	state = new_state #and the new state being entered to the current state
	
	if prev_state != null: #if there is a previous state
		exit_state(prev_state, new_state) #run the exit state logic
	if new_state != null: #if there is a new state
		enter_state(new_state, prev_state) #run enter state logic

func add_state(state_name): #function adds states to the state machine array
	states[state_name] = states.size()
