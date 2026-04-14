extends Area2D

@export var damage: float = 5.0
@export var interval: float = 1.0  # seconds
@export var radius: float = 100.0

func _ready():
	$Timer.wait_time = interval
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

func _on_timer_timeout():
	for body in get_overlapping_bodies():
		if body.is_in_group("inimigo"):
			body.take_damage(damage)