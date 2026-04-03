extends Node2D

## Gerenciador de Ondas e Dificuldade (Refatorado)
## Controla o spawn de inimigos, escalonamento de atributos e surgimento do Boss.

## Estados da spawner
enum SpawnerState { ACTIVE, BOSS_PHASE, PAUSED }

@export_group("Configurações de Cena")
@export var enemy_scenes: Array[PackedScene] ## Lista de inimigos básicos que podem aparecer.
@export var boss_scene: PackedScene ## Cena do Chefe que nascerá no tempo estipulado.

@export_group("Contêiner de Inimigos")
@export var enemies_container: NodePath ## Caminho para o Node onde inimigos serão adicionados.

@export_group("Configurações da Horda")
@export var base_spawn_interval: float = 4.0 ## Intervalo inicial entre spawns (segundos).
@export var min_spawn_interval: float = 0.5 ## Intervalo mínimo permitido.
@export var base_enemy_count: int = 5 ## Quantidade inicial de inimigos por onda.
@export var max_enemies_on_screen: int = 150 ## Limite máximo de inimigos para manter performance.

@export_group("Escalonamento de Dificuldade")
@export var difficulty_step_seconds: float = 60.0 ## A cada X segundos, a dificuldade aumenta.
@export var count_increase_per_step: int = 5 ## Quantos inimigos a mais por onda após cada degrau.
@export var speed_increase_percent: float = 0.1 ## Aumento de velocidade (ex: 0.1 = +10%).
@export var health_increase_percent: float = 0.2 ## Aumento de vida por degrau.
@export var interval_decrease_per_step: float = 0.3 ## Redução do intervalo de spawn por degrau.

@export_group("Evento do Chefe")
@export var boss_spawn_time: float = 300.0 ## Tempo em segundos para o Boss aparecer (ex: 300s = 5min).

@export_group("Posicionamento de Spawn")
@export var spawn_distance: float = 300.0 ## Distância do spawner para criar novos inimigos.

# Variáveis de Estado Interno
var state: SpawnerState = SpawnerState.ACTIVE
var active_enemy_count: int = 0

# Referências injetadas
var _container: Node
var _spawn_timer: Timer
var _boss_timer: Timer
var _queue_timer: Timer  # Processa fila de spawn para evitar spikes de frame
var _boss_timer_remaining: float = -1.0  # -1.0 indica que não foi pausado
var _state_before_pause: SpawnerState = SpawnerState.ACTIVE
var _player: Node2D

# Estado da fila de spawn
var _spawn_queue: int = 0
var _current_speed_mult: float = 1.0
var _current_health_mult: float = 1.0

func _ready() -> void:
	_setup_timers()
	_setup_container()
	_player = get_tree().get_first_node_in_group("player")
	
	# Conecta sinais de morte de inimigos existentes (se houver)
	_connect_existing_enemies()

func _setup_timers() -> void:
	## Cria e configura os timers para spawn de onda
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = base_spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()
	
	## Cria e configura o timer para spawn do boss
	_boss_timer = Timer.new()
	_boss_timer.wait_time = boss_spawn_time
	_boss_timer.one_shot = true
	_boss_timer.timeout.connect(_on_boss_timeout)
	add_child(_boss_timer)
	_boss_timer.start()
	
	## Cria e configura o timer para processar fila de spawn (evita spikes de frame)
	_queue_timer = Timer.new()
	_queue_timer.wait_time = 0.05  # 20 spawns por segundo máximo
	_queue_timer.timeout.connect(_on_queue_tick)
	add_child(_queue_timer)
	_queue_timer.start()

func _setup_container() -> void:
	## Obtém o container onde inimigos serão adicionados
	if enemies_container == NodePath():
		# Fallback: usa o parent se nenhum container foi especificado
		_container = get_parent()
		push_warning("enemies_container não foi especificado. Usando parent como fallback.")
	else:
		_container = get_node(enemies_container)
	
	if not _container:
		push_error("Container de inimigos inválido! Verifique o NodePath 'enemies_container'")
		return

func _connect_existing_enemies() -> void:
	## Conecta sinais de morte para inimigos já na cena
	## Útil apenas para inimigos colocados manualmente na cena no editor.
	## Em runtime, todos os inimigos são criados pelo próprio Spawner.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("died"):
			if not enemy.died.is_connected(_on_enemy_died):
				enemy.died.connect(_on_enemy_died)

func _on_spawn_timeout() -> void:
	if state == SpawnerState.ACTIVE:
		_spawn_wave()
		_update_spawn_interval()

func _on_boss_timeout() -> void:
	_spawn_boss()

func _on_queue_tick() -> void:
	## Processa um item da fila de spawn por tick (evita spikes de frame)
	if _spawn_queue > 0 and active_enemy_count < max_enemies_on_screen:
		_instantiate_enemy(_current_speed_mult, _current_health_mult)
		_spawn_queue -= 1

func _update_spawn_interval() -> void:
	## Atualiza o intervalo de spawn conforme a dificuldade aumenta
	## Nota: mudar wait_time em Timer rodando não afeta o tick atual, só o próximo
	var new_interval = _get_current_spawn_interval()
	_spawn_timer.wait_time = new_interval

## Calcula em qual "nível de dificuldade" o jogo está baseado no tempo decorrido
## Fonte de verdade: timer do boss (sincroniza sempre que o jogo faz pause)
## Limitação: após boss aparecer, time_left fica 0.0 permanentemente, congelando o step
func _get_current_step() -> int:
	var time_elapsed = boss_spawn_time - _boss_timer.time_left
	return int(time_elapsed / difficulty_step_seconds)

## Calcula o intervalo de spawn atual com escalonamento
func _get_current_spawn_interval() -> float:
	var step = _get_current_step()
	return max(min_spawn_interval, base_spawn_interval - (step * interval_decrease_per_step))

func _spawn_wave() -> void:
	## Gera uma onda de inimigos com escalonamento dinâmico
	if active_enemy_count >= max_enemies_on_screen:
		return

	var step = _get_current_step()
	
	# Cálculo de escalonamento
	var enemies_to_spawn = base_enemy_count + (step * count_increase_per_step)
	_current_speed_mult = 1.0 + (step * speed_increase_percent)
	_current_health_mult = 1.0 + (step * health_increase_percent)
	
	# Adiciona à fila em vez de instanciar diretamente (evita spike de frame)
	_spawn_queue += enemies_to_spawn

func _instantiate_enemy(speed_mult: float, health_mult: float) -> void:
	## Cria e configura uma instância de inimigo com modificadores
	if not _container:
		push_error("Spawner: _container é null, abortando spawn.")
		return
	
	if enemy_scenes.is_empty():
		return

	var scene = enemy_scenes.pick_random()
	var enemy = scene.instantiate()
	
	# Aplica modificadores de forma explícita (contrato claro)
	if enemy.has_method("apply_difficulty_modifiers"):
		enemy.apply_difficulty_modifiers(speed_mult, health_mult)
	else:
		# Fallback para duck typing (compatibilidade com inimigos antigos)
		if "speed" in enemy:
			enemy.speed *= speed_mult
		if "max_health" in enemy:
			enemy.max_health *= health_mult
			if "health" in enemy:
				enemy.health = enemy.max_health

	# Define posição de spawn fora da câmera do player
	var spawn_pos = _calculate_spawn_position()
	enemy.global_position = spawn_pos
	
	# Conecta sinal de morte
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	
	# Adiciona à árvore
	_container.add_child(enemy)
	active_enemy_count += 1

func _calculate_spawn_position() -> Vector2:
	## Calcula uma posição de spawn fora da câmera do player
	## Spawn em ângulo aleatório com distância fixa (distribui uniformemente)
	var player_pos: Vector2 = global_position
	if is_instance_valid(_player):
		player_pos = _player.global_position
	
	# Ângulo aleatório em 360 graus para distribuição uniforme
	var angle = randf() * TAU
	var distance = spawn_distance + randf_range(0, 100)
	
	return player_pos + Vector2(cos(angle), sin(angle)) * distance

func _spawn_boss() -> void:
	## Spawna o boss e transiciona para a fase de boss
	if state != SpawnerState.ACTIVE:
		return
	
	if not _container:
		push_error("Spawner: _container é null, abortando spawn do boss.")
		return
	
	if not boss_scene:
		push_error("Spawner: boss_scene não foi configurado no Inspector!")
		return
	
	state = SpawnerState.BOSS_PHASE
	_spawn_timer.stop()
	
	print("⚠️  ALERTA: O Chefe apareceu!")
	
	var boss = boss_scene.instantiate()
	var spawn_pos = _calculate_spawn_position()
	boss.global_position = spawn_pos
	boss.add_to_group("enemies")
	
	# Conecta sinal de morte do boss
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)
	
	_container.add_child(boss)
	active_enemy_count += 1

func _on_enemy_died() -> void:
	## Callback quando um inimigo morre
	active_enemy_count = max(0, active_enemy_count - 1)

func _on_boss_died() -> void:
	## Callback quando o boss morre
	_on_enemy_died()  # Reutiliza lógica de decremento
	print("🎮 Boss derrotado!")
	# Opcional: retomar a horda comum ou encerrar jogo
	# state = SpawnerState.ACTIVE
	# _spawn_timer.start()

## Pausa o spawn de inimigos
func pause() -> void:
	if state == SpawnerState.PAUSED:
		return
	_state_before_pause = state  # Guarda o estado anterior
	state = SpawnerState.PAUSED
	_boss_timer_remaining = _boss_timer.time_left
	_spawn_timer.stop()
	_boss_timer.stop()
	_queue_timer.stop()

## Retoma o spawn de inimigos
func resume() -> void:
	if state != SpawnerState.PAUSED:
		return
	state = _state_before_pause  # Restaura o estado anterior
	if state == SpawnerState.ACTIVE:
		_spawn_timer.start()
		if _boss_timer_remaining > 0.0:
			_boss_timer.start(_boss_timer_remaining)
	_queue_timer.start()