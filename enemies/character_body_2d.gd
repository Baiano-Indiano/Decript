extends CharacterBody2D

## Sinais emitidos pelo inimigo
signal died

## Atributos exportáveis
@export var speed: float = 100.0
@export var max_health: float = 10.0

## Estado interno
var player: Node2D
var health: float = 0.0  # será sobrescrito no _ready
var _is_dead: bool = false
var _base_speed: float
var _base_max_health: float

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: nenhum node no grupo 'player' encontrado.")
	_base_speed = speed
	_base_max_health = max_health
	health = max_health
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

## Aplica modificadores de dificuldade de forma idempotente
func apply_difficulty_modifiers(speed_mult: float, health_mult: float) -> void:
	speed = _base_speed * speed_mult
	max_health = _base_max_health * health_mult
	health = max_health

## Reduz a saúde do inimigo e o destrói se chegar a 0
func take_damage(damage: float) -> void:
	if _is_dead:
		return
	health = max(0.0, health - damage)
	if health == 0.0:
		_is_dead = true
		died.emit()
		queue_free()
