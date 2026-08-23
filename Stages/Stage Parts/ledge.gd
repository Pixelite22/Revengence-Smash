extends Area2D

@export_enum("Left", "Right") var ledge_side = "Left"
@onready var label = $Label
@onready var collision = $CollisionShape2D
var is_grabbed = false


func _on_ledge_body_exited(body : Node2D):
	is_grabbed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ledge_side == "Left":
		label.text = "Ledge_L"
	else:
		label.text = "Ledge_R"
