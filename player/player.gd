extends CharacterBody2D

@export var speed = 200
@export var max_health = 100
var current_health = max_health

var current_xp = 0
var next_level_xp = 10
var level = 1

var attack_cooldown = 0.5
var time_since_last_attack = 0.0
var attack_range = 350.0

# Sinais
signal xp_atualizado(atual, max)
signal on_level_up_reached(novas_armas_opcoes)

# Opções de upgrade possíveis
var upgrade_options = [
	{"type": "speed", "description": "Increase Speed"},
	{"type": "health", "description": "Increase Max Health"},
	{"type": "attack_cooldown", "description": "Reduce Attack Cooldown"},
	{"type": "damage", "description": "Increase Damage"}
]

func _ready():
	current_health = max_health
	emit_signal("xp_atualizado", current_xp, next_level_xp)

func _physics_process(delta):
	var direction = Vector2.ZERO

	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	velocity = direction.normalized() * speed
	move_and_slide()

	time_since_last_attack += delta
	if time_since_last_attack >= attack_cooldown:
		auto_attack()

@export var projectile_scene: PackedScene

func auto_attack():
	var enemies = get_tree().get_nodes_in_group("inimigo")
	if enemies.size() == 0:
		return
		
	var closest_enemy = null
	var min_dist = attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_enemy = enemy
			
	if closest_enemy != null:
		shoot_at(closest_enemy.global_position)
		time_since_last_attack = 0.0

func shoot_at(target_pos: Vector2):
	var projectile = projectile_scene.instantiate()

	var dir = (target_pos - global_position).normalized()
	projectile.position = global_position
	projectile.direction = dir
	projectile.damage = get_meta("damage", 10)

	get_parent().add_child(projectile)

	$Camera2D.apply_shake(1.5)

func gain_xp(amount):
	current_xp += amount
	print("Vazio absorveu alma. XP Atual: ", current_xp)
	
	if current_xp >= next_level_xp:
		level_up()
	
	emit_signal("xp_atualizado", current_xp, next_level_xp)

@export var level_up_menu_scene: PackedScene

func level_up():
	level += 1
	current_xp -= next_level_xp  # Handle overflow
	next_level_xp = int(next_level_xp * 1.5)
	
	# Flash effect before pausing
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color.CYAN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Pausar o jogo
	get_tree().paused = true
	
	# Sortear 3 opções únicas
	var shuffled_options = upgrade_options.duplicate()
	shuffled_options.shuffle()
	var options = shuffled_options.slice(0, min(3, shuffled_options.size()))
	
	# Instanciar e mostrar menu
	var menu = level_up_menu_scene.instantiate()
	menu.process_mode = Node.PROCESS_MODE_ALWAYS  # Ensure it processes during pause
	get_tree().root.add_child(menu)
	menu.show_menu(self, options)
	
	print("O Vazio se fortalece. Nível: ", level)

func apply_upgrade(upgrade_type):
	match upgrade_type:
		"speed":
			speed += 20
		"health":
			max_health += 20
			current_health += 20
		"attack_cooldown":
			attack_cooldown = max(0.1, attack_cooldown - 0.05)
		"damage":
			# Assumindo que o dano está no projetil, mas aqui aumentamos uma variável
			# Para simplificar, vamos adicionar uma variável damage
			if not has_meta("damage"):
				set_meta("damage", 10)
			set_meta("damage", get_meta("damage") + 5)
	
	emit_signal("xp_atualizado", current_xp, next_level_xp)