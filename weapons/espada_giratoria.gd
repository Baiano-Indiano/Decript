extends Area2D

@export var damage: float = 10.0
@export var cooldown: float = 1.0
@export var radius: float = 50.0
@export var orbit_speed: float = 2.0  # radians per second

var angle: float = 0.0
var last_damage_time: float = 0.0

func _ready():
	# Connect to body_entered signal
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	angle += orbit_speed * delta
	position = Vector2(cos(angle), sin(angle)) * radius

func _on_body_entered(body):
	if body.is_in_group("inimigo"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_damage_time >= cooldown:
			body.take_damage(damage)
			last_damage_time = current_time