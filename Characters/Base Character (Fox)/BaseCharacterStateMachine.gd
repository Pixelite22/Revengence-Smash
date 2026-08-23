extends StateMachine
@export var id = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Adds states into the character when first loaded
	add_state('STAND') #0
	add_state('JUMP_SQUAT') #1
	add_state('SHORT_HOP') #2
	add_state('FULL_HOP') #3
	add_state('DASH') #4
	add_state('RUN') #5
	add_state('WALK') #6
	add_state('MOONWALK') #7
	add_state('CROUCH') #8
	add_state('AIR') #9
	add_state('LAND') #10
	add_state('TURN') #11
	add_state('LEDGE_CATCH') #12
	add_state('LEDGE_HOLD') #13
	add_state('LEDGE_CLIMB') #14
	add_state('LEDGE_JUMP') #15
	add_state('LEDGE_HOP') #16
	add_state('LEDGE_ROLL') #17
	#When ready, call the set_state function and set the state to STAND
	call_deferred("set_state", states.STAND)


func state_logic(delta):
	parent.update_frames(delta) #updates frame count on character each frame
	parent._physics_process(delta) #pass the delta from here to the one on the physics process of the character
	if parent.regrab > 0:
		parent.regrab -= 1

##This function is the meat of this script, handling the transitions between states
func get_transition(delta):  
	#Set the parent with move and slide as needed.
	#parent.velocity *= 2
	parent.up_direction = Vector2.UP
	parent.move_and_slide() ##May need to update this later as the tutorial was in godot 3.0 and had some extra stuff on it
	parent.state.text = str(state) #For debugging, display the current state as text
	
	if landing(): #If a character is landing as determined by the called function
		parent.frame_reset() #reset frames to 0
		return states.LAND #return the landing state
	
	if falling(): #If a character is falling as determined by the called function
		parent.frame_reset() #reset frames to 0
		return states.AIR #return the in air state
	
	if ledge(): #If a character is grabbing a ledge as determined by the called function
		parent.frame_reset() #reset frames to 0
		return states.LEDGE_CATCH #return the ledge catched state
	else: #But if they aren't grabbing the ledge
		parent.reset_ledge() #Reset the ledge variables through the parent function
	
	##From here we match the state the character currently has, 
	##and then check for the conditions needed to change to a new state 
	match state:
		#Below this shows an example structure of how a state transfer works
		#states.STATENAME
			#if CASE IN WHICH THE STATE WOULD SWITCH TO ANOTHER ONE:
				#LOGIC FOR NEW STATE
				#parent.frame_reset()
				#return states.NEWSTATE
		
		#Stand state logic
		states.STAND:
			#Reset jumps when entering the state
			parent.reset_jumps()
			
			#Transfer to Jump State logic
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			#Transfer to Crouch State logic
			if Input.is_action_just_pressed("down_%s" % id):
				parent.frame_reset()
				return states.CROUCH
			
			#Transfer to Dash State logic
			if Input.get_action_strength("right_%s" % id) == 1: #if right button is pressed
				parent.velocity.x = parent.RUNSPEED #set velocity to run speed
				parent.frame_reset() #reset frames
				parent.turn(false) #set turn to false (right)
				return states.DASH #Set the new state to the dashing state
			if Input.get_action_strength("left_%s" % id) == 1:
				parent.velocity.x = parent.RUNSPEED
				parent.frame_reset()
				parent.turn(true) #set turn to true (left)
				return states.DASH
			
			#Handles how left over movement works in this state
			if parent.velocity.x > 0 and state == states.STAND: #if there is positive movement and we are meant to stand
				parent.velocity.x += -parent.TRACTION * 1 #subtract from the velocity by the traction
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x) #clamp the possible value so the subtraction doesn't happen when we hit zero
			elif parent.velocity.x < 0 and state == states.STAND: #same as above but in reverse for negative movement removal
				parent.velocity.x += parent.TRACTION * 1
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
		
		#Jump Squat Logic
		states.JUMP_SQUAT:
			if parent.frame == parent.jump_squat_dur: #if the frame the player is on is the same as the value of the var that represents the duration a jump squat should last
				if Input.is_action_pressed('shield_%s' % id) and (Input.is_action_pressed('left_%s' % id) or Input.is_action_pressed("right_%s" % id)):
					if Input.is_action_pressed('right_%s' % id):
						parent.velocity.x = parent.AIRDODGESPEED / parent.perfect_wavedash_mod
					if Input.is_action_pressed('left_%s' % id):
						parent.velocity.x = -parent.AIRDODGESPEED / parent.perfect_wavedash_mod
					parent.lag_frames = 6
					parent.frame_reset()
					return states.LAND
				if not Input.is_action_pressed('jump_%s' % id): #if the player is no longer pressing jump by then
					parent.velocity.x = lerp(parent.velocity.x, 0.0, 0.88) #makes sure momentum doesn't halt when jumping
					parent.frame_reset() #reset the frame count
					return states.SHORT_HOP #and transfer to the Short Hop State
				else: #But if the player is still holding jump by then
					parent.velocity.x = lerp(parent.velocity.x, 0.0, 0.88) #same as lerp explainer from before
					parent.frame_reset() #Reset the frame count
					return states.FULL_HOP #and transfer to the Full Hop
		
		states.SHORT_HOP:
			parent.velocity.y = -parent.JUMPFORCE #Perform the actual hop by setting the vertical velocity to the player's jumpforce
			parent.frame_reset() #reset the frames
			return states.AIR #Transfer to the air state
		
		states.FULL_HOP:
			parent.velocity.y = -parent.MAXJUMPFORCE #Perform the actual hop by setting the vertical velocity to the player's maximum jumpforce
			parent.frame_reset()
			return states.AIR
		
		states.DASH:
			#Jump Squat Logic
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			##Logic for Dash Dancing, Moonwalking, and Run (Left)
			if Input.is_action_pressed('left_%s' % id): #if pressing left
				if parent.velocity.x > 0: #and face/moving right
					parent.frame_reset() #reset frame
				parent.velocity.x = -parent.DASHSPEED #flip velocity
				if parent.frame <= parent.dash_dur - 1: #if dash to left but moving right
					if Input.is_action_just_pressed("down_%s" % id): #And you press down button
						parent.frame_reset() #reset frames
						return states.MOONWALK #and enter moonwalk state
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent.frame_reset()
					return states.RUN
			
			##Allows for Dash Dancing, Moonwalking, and Run (Right)
			elif Input.is_action_pressed('right_%s' % id): #same as above for other direction
				if parent.velocity.x < 0:
					parent.frame_reset()
				parent.velocity.x = parent.DASHSPEED
				if parent.frame <= parent.dash_dur - 1:
					if Input.is_action_just_pressed("down_%s" % id):
						parent.frame_reset()
						return states.MOONWALK
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
					parent.frame_reset()
					return states.RUN
			
			else: ##Transfers back to Stand if the previous options aren't be performed
				if parent.frame >= parent.dash_dur - 1: #and the frame exceeds the length of the dash
					return states.STAND #transfer to standing state
		
		states.RUN:
			#Jump Squat transfer Logic
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			#Crouch transfer Logic
			if Input.is_action_just_pressed("down_%s" % id):
				parent.frame_reset()
				return states.CROUCH
			
			#Actual Run Logic, allowing for transfer to Stand state if no longer running
			if Input.get_action_strength("left_%s" % id):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.RUNSPEED
					parent.turn(true)
				else:
					parent.frame_reset()
					return states.TURN
			elif Input.get_action_strength("right_%s" % id):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(false)
				else:
					parent.frame_reset()
					return states.TURN
			else:
				parent.frame_reset()
				return states.STAND
		
		
		states.TURN:
			#Jump Squat Transfer Logic
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			##Note: Clamp Wasn't working for me so I did it the old fashioned if less then 0, make 0 way before the clamp
			if parent.velocity.x > 0: #If the player is moving right
				parent.turn(true)
				parent.velocity.x += -parent.TRACTION * 2 #Slow the player down constantly
				if parent.velocity.x < 0: #if the velocity becomes lower then 0
					parent.velocity.x = 0 #set it to 0
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x) #meant to clamp the variable to 0 but doesn't seem to work without the manual setting of velocity
			elif parent.velocity.x < 0: #If the player is moving left, all will be the same but reversed
				parent.turn(false)
				parent.velocity.x += parent.TRACTION * 2
				if parent.velocity.x > 0:
					parent.velocity.x = 0
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			else: #Otherwise (if the player isn't moving either left or right)
				parent.frame_reset()
				if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id): #If the player isn't trying to move in either direction
					return states.STAND #Transfer to Stand
				else: #otherwise (the player is trying to move)
					return states.RUN #Transfer to Run
		
		states.MOONWALK:
			#Jump transfer logic
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			#Honestly a tad bit confused about this one so might have to comment them out later
			elif Input.is_action_pressed("left_%s" % id) and parent.direction() == 1: #If moving left and facing right
				if parent.velocity.x > 0: #If the player is moving right
					parent.frame_reset()
				parent.velocity.x += -parent.AIRACCEL * Input.get_action_strength("left_%s" % id)
				parent.velocity.x = clamp(parent.velocity.x, -parent.DASHSPEED * 1.4, parent.velocity.x)
				if parent.frame <= parent.dash_dur * 2:
					parent.turn(false)
					return states.MOONWALK
				else:
					parent.turn(true)
					parent.frame_reset()
					return states.STAND
			
			elif Input.is_action_pressed("right_%s" % id) and parent.direction() == -1:
				if parent.velocity.x < 0:
					parent.frame_reset()
				parent.velocity.x += parent.AIRACCEL * Input.get_action_strength("right_%s" % id)
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, parent.DASHSPEED * 1.4)
				if parent.frame <= parent.dash_dur * 2:
					parent.turn(true)
					return states.MOONWALK
				else:
					parent.turn(false)
					parent.frame_reset()
					return states.STAND
			
			else:
				if parent.frame >= parent.dash_dur - 1:
					for state in states:
						if state != "JUMP_SQUAT":
							return states.STAND
		
		states.WALK:
			#Jump Squat Trasfer check
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			
			#Crouch Transfer Check
			if Input.is_action_just_pressed("down_%s" % id):
				parent.frame_reset()
				return states.CROUCH
			
			#Actual walk logic, similar to run logic
			if Input.get_action_strength("left_%s" % id):
				parent.velocity.x = -parent.WALKSPEED * Input.get_action_strength("left_%s" % id)
				parent.turn(true)
			elif Input.get_action_strength("right_%s" % id):
				parent.velocity.x = parent.WALKSPEED * Input.get_action_strength("right_%s" % id)
				parent.turn(false)
			else:
				parent.frame_reset()
				return states.STAND
		
		states.CROUCH:
			#Jump Squat Transfer check
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame_reset()
				return states.JUMP_SQUAT
			#Crouch Transfer check
			if Input.is_action_just_released("down_%s" % id):
				parent.frame_reset()
				return states.STAND
			
			elif parent.velocity.x > 0: #If moving right
				if parent.velocity.x > parent.RUNSPEED: #If moving faster then the players runspeed
					parent.velocity.x += -(parent.TRACTION * 4) #Slow them down based on the player's traction, multiplied by 4
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x) #and clamp it so it won't go past 0
				else: #but if they are moving slower then the run speed
					parent.velocity.x += -(parent.TRACTION / 2) #still slow them down, but just at a slower rate
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0: #If moving left, essentially the same as above but for the other direction
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION * 4)
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				else:
					parent.velocity.x += (parent.TRACTION / 2)
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
		
		states.AIR:
			air_movement() #Call the function that handles this as it is a lot
			##Following is for Double Jump Mechanics
			if Input.is_action_just_pressed("jump_%s" % id) and parent.air_jump > 0: #If trying to jump in air and there are jumps available
				parent.fastfall = false #Reset fastfall
				parent.velocity.x = 0 #Set the horizontal movement to 0
				parent.velocity.y = -parent.DOUBLEJUMPFORCE #and perform the jump
				parent.air_jump -= 1 #then decrement the jump variable
				if Input.is_action_pressed("left_%s" % id): #Then if they are trying to move left
					parent.velocity.x = -parent.MAXAIRSPEED #Reset the speed as it should be
				elif Input.is_action_pressed("right_%s" % id): #then if they are trying to move right
					parent.velocity.x = parent.MAXAIRSPEED #Reset the speed as it should be
		
		states.LAND:
			if parent.frame <= parent.landing_frames + parent.lag_frames: #Check if frame parent is on is less then or equal to landing frames + lag frames (checks if still landing essentially)
				#if still landing 
				if parent.frame == 1: #and on the first frame
					pass #then nothing happens
				if parent.velocity.x > 0: #If velocity of character is greater then 0
					parent.velocity.x = parent.velocity.x - parent.TRACTION / 2 #Slow them down
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x) #clamp them between 0 and the current velocity as to not give negative velocity
				elif parent.velocity.x < 0: #if the velocity of character is less then 0
					parent.velocity.x = parent.velocity.x + parent.TRACTION / 2 #speed them up 
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0) #and clamp them between the current velocity and 0 as to not push the velocity into the positives
				#Jump Squat transfer logic
				if Input.is_action_just_pressed("jump_%s" % id):
					parent.frame_reset()
					return states.JUMP_SQUAT
			else: #if we aren't still landing
				#Crouch and Stand Tranfer logic
				if Input.is_action_pressed("down_%s" % id): #if down is pressed
					parent.lag_frames = 0
					parent.frame_reset()
					parent.reset_jumps()
					return states.CROUCH #return the crouch state
				else: #If anything else is pressed (or nothing is pressed?)
					parent.frame_reset()
					parent.lag_frames = 0
					parent.reset_jumps()
					return states.STAND #go into the standing state
				parent.lag_frames = 0
		
		states.LEDGE_CATCH:
			print("Entered Ledge Catch")
			if parent.frame > 7: #If the player has been on the ledge for at least 7 frames
				parent.lag_frames = 0 #Set the lag frames to 0
				parent.reset_jumps() #reset the jump counter
				parent.frame_reset() #and the frame counter
				return states.LEDGE_HOLD #then transfer to the ledge hold state
		
		states.LEDGE_HOLD:
			print("Entered Ledge Hold")
			if parent.frame >= 390: #If player meets or exceeds a frame count of 392 (apparenty 3.5 seconds)
				self.parent.position.y += -25 #set the player under the ledge enough to not regrab
				parent.frame_reset() #reset the frame count
				return states.AIR #Should and will be TUMBLE eventually when coded
			
			if Input.is_action_just_pressed("down_%s" % id): #If the player presses down
				parent.fastfall = true #Go into fastfall
				parent.regrab = 30 #set the regrab variable to 30 so it doesn't instantly regrab and needs to wait 30 frames(?)
				parent.reset_ledge() #reset the ledge
				self.parent.position.y += -25 #Lower player to deter regrabs
				parent.catch = false #set the catch to false, showing they are no lonager grabbing it
				parent.frame_reset() #reset frame count
				return states.AIR #and go into the air state
			
			elif parent.LedgeF.target_position.x > 0: #if the position the raycast is pointing to is greater then 0 (pointing at a left ledge)
				parent.frame_reset()
				if Input.is_action_just_pressed("left_%s" % id): #if player is trying to go left
					parent.velocity.x = (parent.AIRACCEL / 2) #Set the velocity to half that of the air acceleration variable
					parent.regrab = 30 #Set the regrab to 30
					parent.reset_ledge() #And reset the ledge
					self.parent.position.y += -25 #Then move the player's position up by 25
					parent.catch = false #And set the catch variable to false
					return states.AIR #and go into the air state
				elif Input.is_action_just_pressed("right_%s" % id): #if right is pressed
					return states.LEDGE_CLIMB #climb the ledge
				elif Input.is_action_just_pressed("shield_%s" % id): #if shield is pressed
					return states.LEDGE_ROLL #roll over the ledge
				elif Input.is_action_just_pressed("jump_%s" % id): #if jump is pressed
					return states.LEDGE_JUMP #perform the ledge jump
			
			elif parent.LedgeF.target_position.x < 0: #Following is the same as above but for right ledge logic
				parent.frame_reset()
				if Input.is_action_just_pressed("right_%s" % id):
					parent.velocity.x = (parent.AIRACCEL / 2)
					parent.regrab = 30
					return states.AIR
				elif Input.is_action_just_pressed("left_%s" % id):
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_%s" % id):
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_%s" % id):
					return states.LEDGE_JUMP
		
		states.LEDGE_CLIMB: 
			print("Entered Ledge Climb")
			#For the first few frames do nothing, and then over the next segments of frames, go up by 25
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 25
			if parent.frame == 10:
				parent.position.y -= 25
			if parent.frame == 20:
				parent.position.y -= 25
			if parent.frame == 22: #once we hit frame 22
				parent.catch = false #Officially let go of the ledge
				parent.position.y -= 25 #continue increasing the position
				parent.position.x += 50 * parent.direction() #and move the player horizontally 50, accounting for the way we are already facing
			if parent.frame == 25: #once we hit frame 25
				parent.velocity.y = 0 #remove the velocity from the player
				parent.velocity.x = 0 #remove the velocity from the player
				parent.move_and_collide(Vector2(parent.direction() * 20, 50)) ##and call the magic move and collide function with these arguments
			if parent.frame == 30: #then on frame 30
				parent.reset_ledge() #Reset ledges
				parent.frame_reset() #and frames
				return states.STAND #and move to standing state
		
		states.LEDGE_JUMP:
			print("Entered Ledge Jump")
			if parent.frame > 14: #If on frame 14 or above
				if Input.is_action_just_pressed("attack_%s" % id): #allow for the ability to air attack
					parent.frame_reset()
					return states.AIR_ATTACK
				if Input.is_action_just_pressed("special_%s" % id): #and air special attacks
					parent.frame_reset()
					return states.SPECIAL
			if parent.frame == 5: #on the fifth frame
				#parent.frame_reset()
				parent.position.y -= 20 #move up by 20
			if parent.frame == 10: #on the 10th frame
				parent.catch = false #officially let go of the ledge
				parent.position.y -= 20 #move up by 20
				if Input.is_action_just_pressed("jump_%s" % id): #and if trying to jump
					parent.fastfall = false #turn off fast fall if it was on
					parent.position.y = -parent.DOUBLEJUMPFORCE #and perform what is essentially a double jump
					parent.position.x = 0
					parent.airJump -= 1
					parent.frame_reset()
					return states.AIR #then go into the air state
			if parent.frame == 15: #on the 15th frame, just repeat the 10th logic
				parent.position.y -= 20
				parent.velocity.y -= parent.DOUBLEJUMPFORCE
				parent.velocity.x += 220 * parent.direction()
				if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent.frame_reset()
					return states.AIR
				if Input.is_action_just_pressed("attack_%s" % id): #but allow for air attacks
					parent.frame_reset()
					return states.AIR_ATTACK
			elif parent.frame > 15 and parent.frame < 20: #When between frames 15 and 20
				parent.velocity.y += parent.FALLSPEED #increase the velocity by the fall speed
				if Input.is_action_just_pressed("jump_%s" % id): #allow for the possible jumps
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent.frame_reset()
					return states.AIR
				if Input.is_action_just_pressed("attack_%s" % id): #and air attacks
					parent.frame_reset()
					return states.AIR_ATTACK
			if parent.frame == 20:
				parent.frame_reset()
				return states.AIR
		
		states.LEDGE_ROLL:
			#This is all practically the same as ledge climb but the numbers are increased to show the rolls logic
			print("Entered Ledge Roll")
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30
			if parent.frame == 20:
				parent.catch = false
				parent.position.y -= 30
			if parent.frame == 22:
				parent.position.y -= 30
				parent.position.x += 50 * parent.direction()
			if parent.frame > 22 and parent.frame < 28:
				parent.position.x += 30 * parent.direction()
			if parent.frame == 29:
				parent.move_and_collide(Vector2(parent.direction() * 20, 50))
			if parent.frame == 30:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.reset_ledge()
				parent.frame_reset()
				return states.STAND

func enter_state(new_state, old_state):
	match new_state:
		#states.:
		#	parent.play_animation()
		#	parent.states.text = str()
		states.STAND:
			parent.play_animation('Idle')
			parent.state.text = str('STAND')
		states.DASH:
			parent.play_animation('Dash Start')
			parent.state.text = str('DASH')
		states.MOONWALK:
			parent.play_animation('Walk')
			parent.state.text = str('MOONWALK')
		states.TURN:
			parent.play_animation('Turn')
			parent.state.text = str('TURN')
		states.CROUCH:
			parent.play_animation('Crouch')
			parent.state.text = str('CROUCH')
		states.RUN:
			parent.play_animation('Dash')
			parent.state.text = str('RUN')
		states.JUMP_SQUAT:
			parent.play_animation('Jump Start')
			parent.state.text = str('JUMP_SQUAT')
		states.SHORT_HOP:
			parent.play_animation('Jump')
			parent.state.text = str('SHORT_HOP')
		states.AIR:
			parent.play_animation('Jump')
			parent.state.text = str('FULL_HOP')
		states.LAND:
			parent.play_animation('Land')
			parent.state.text = str('LANDING')
		states.LEDGE_CATCH:
			parent.play_animation('Ledge')
			parent.state.text = str("Ledge_Catch")
		states.LEDGE_HOLD:
			parent.play_animation('Ledge')
			parent.state.text = str("Ledge_Hold")
		states.LEDGE_JUMP:
			parent.play_animation('Jump')
			parent.state.text = str("Ledge_Jump")
		states.LEDGE_CLIMB:
			parent.play_animation('Roll Forward')
			parent.state.text = str("Ledge_Climb")
		states.LEDGE_ROLL:
			parent.play_animation('Roll Forward')
			parent.state.text = str("Ledge_Roll")

func exit_state(old_state, new_state):
	pass

func state_includes(state_array): #detects and creates an array based on certain properties
	for state_in in state_array: #detects if the state is in the state array passed in
		if state == state_in: #if the current state is in that array
			return true #return true
	return false #otherwise return false

func air_movement():
	if parent.velocity.y < parent.FALLINGSPEED: #if the character is falling slower then their fallspeed
		parent.velocity.y += parent.FALLSPEED #increase their falling velocity by the fallspeed
	if Input.is_action_pressed("down_%s" % id) and parent.velocity.y > -150 and not parent.fastfall: #if down is pressed in the air and not already at max fall speed or in fast fall
		##ADD THIS TO IF AFTER ADDING BUFFER SYSTEM LATER: and parent.down_buffer == 1
		parent.velocity.y = parent.MAXFALLSPEED #set their downward velocity to their max falling speed
		parent.fastfall = true #set fast fall to true
	if parent.fastfall: #if they are in fast fall
		parent.set_collision_mask_value(2, false) #set the collision with the walls to false (so they can fall through the platforms that can be fallen through)
		parent.velocity.y = parent.MAXFALLSPEED #set their downward velocty to maxfallspeed if not already there
	
	if abs(parent.velocity.x) == abs(parent.MAXAIRSPEED): #if the character is moving horizontally at the max speed in which they can
		if parent.velocity.x > 0: #if character velocity is going to the right
			if Input.is_action_pressed("left_%s" % id): #and they press left
				parent.velocity.x += -parent.AIRACCEL #slow their speed
			elif Input.is_action_pressed("right_%s" % id): #but if they press right
				parent.velocity.x = parent.velocity.x #just keep the speed at it's current (max) speed
		elif parent.velocity.x < 0: #following is the same logic but reversed for when they are moving left
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x = parent.velocity.x
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x += -parent.AIRACCEL
		
	elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED): #if the character is moving slower then max
		if Input.is_action_pressed("left_%s" % id): #and press left
			parent.velocity.x += -parent.AIRACCEL #slow them down
		elif Input.is_action_pressed("right_%s" % id): #and press right
			parent.velocity.x += parent.AIRACCEL #speed them up
	
	if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id): #if neither left or right is pressed
		if parent.velocity.x < 0: #and the velocity is less then 0
			parent.velocity.x += parent.AIRACCEL / 5 #speed them up gradually by a fifth of airaccel
		elif parent.velocity.x > 0: #and velocity is greater then 0
			parent.velocity.x += - parent.AIRACCEL / 5 #slow them down slowly by a fifth of the airaccel

func landing(): ##Function handles a character landing on the ground from being in the air
	if state_includes([states.AIR]): #as long as the character is in the air
		if (parent.GroundL.is_colliding() and parent.velocity.y >= 0): #if the left foot raycast collides with something and the velocity is greater then 0
			var collider = parent.GroundL.get_collider() #set the collider to collider
			parent.frame = 0 #reset the frame of the character manually
			if parent.velocity.y > 0: #if the velocity is still greater then 0
				parent.velocity.y = 0 #manually set the velocity to 0
			parent.fastfall = false #and turn off fastfall 
			return true #then return true to show the character is in the process of landing
		
		if (parent.GroundR.is_colliding() and parent.velocity.y >= 0): #Then repeat but for the right foot
			var collider2 = parent.GroundR.get_collider()
			parent.frame = 0
			if parent.velocity.y >= 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true

func falling(): ##Function handles falling in midair
	#if the character is currently in a state listed within state_includes
	if state_includes([states.STAND, states.DASH, states.RUN, states.WALK, states.STAND, states.CROUCH, states.LAND, states.TURN, states.JUMP_SQUAT, states.MOONWALK]): #[states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]):
		if not parent.GroundL.is_colliding() and not parent.GroundR.is_colliding(): #if neither the left or the right foot are colliding with anything
			return true #return true, as this function is called to check not transfer, so this will tell the call they are falling

func ledge(): ##Function handles ledge interactions 
	if state_includes([states.AIR]): #If the player is in the air
		if (parent.LedgeF.is_colliding()): #If the Front raycast is colliding with something it can sense
			print("Forward Ledge Grab Collided")
			var collider = parent.LedgeF.get_collider() #Set the item being collided to a new variable named collider
			#If variable has a label with the text Ledge_L (signaling it is a ledge able to be grabbed from the left), and down isn't pressed at 60% strength, and the regrab is at 0, and the collider isn't already being grabbed by another character
			if collider.get_node('Label').text == 'Ledge_L' and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				if state_includes([states.AIR]): #If the player is still in the air
					if parent.velocity.y < 0: #if the velocity of this character is greater then 0
						return false #return false, signaling they did not grab the ledge
				parent.frame = 0 #set the frame of the player to 0
				parent.velocity.x = 0 #set the velocity of the player to 0
				parent.velocity.y = 0 #set the velocity of the player to 0
				self.parent.position.x = collider.position.x - 20 #Set the player to (-20, -2) in respect to the collider's position
				self.parent.position.y = collider.position.y - 2 #Set the player to (-20, -2) in respect to the collider's position
				parent.turn(false) #make sure the player faces right
				parent.reset_jumps() #reset the jump counter
				parent.fastfall = false #Stop the fast fall
				collider.is_grabbed = true #Set the collider to being grabbed so others can't
				parent.last_ledge = collider #And set the last ledge variable on the player to the one they grabbed
				return true #finally return true for the state machine to know they are grabbing a ledge
			
			#The following is a repeat of above but for right sided ledges, as such I will only comment on the changes
			if collider.get_node('Label').text == 'Ledge_R' and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20 #Make the position (20, 1) in relation to the collision
				self.parent.position.y = collider.position.y + 1 #Make the position (20, 1) in relation to the collision
				parent.turn(true) #Make sure they face left
				parent.reset_jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
		
		#Then we repeat both above BUT for the collider on the players back, and as such I am not commenting below past the if statement
		if (parent.LedgeB.is_colliding()): #if the back raycast collides with something it can sense
			print("Back Ledge Grab Collided")
			var collider = parent.LedgeB.get_collider()
			if collider.get_node('Label').text == 'Ledge_L' and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(false)
				parent.reset_jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
			
			if collider.get_node('Label').text == "Ledge_R" and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(true)
				parent.reset_jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
