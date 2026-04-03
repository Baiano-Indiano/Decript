extends Node

# Script de teste para EnemySpawner

func _ready():
	print("Executando Testes do EnemySpawner...")
	# Nota: Os testes rodam em sequência neste nó. Cada teste faz queue_free dos seus nós,
	# mas eles só são destruídos ao final do frame. Se um teste falhar antes do queue_free,
	# pode haver estado vazado que interfira em testes subsequentes. Isso é aceitável para
	# escopo atual, mas suites maiores devem usar GdUnit4 ou estruturar testes em cenas isoladas.
	test_setup_timers()
	test_spawn_wave()
	test_difficulty_scaling()
	test_boss_spawn()
	test_pause_resume()
	test_queue_processing()
	test_enemy_cap()
	print("Todos os testes do EnemySpawner concluídos!")

func test_setup_timers():
	var spawner = EnemySpawner.new()
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # Entra na árvore — _ready() é chamado automaticamente, _container será o parent
	
	# Verificar se timers foram criados
	assert(spawner._spawn_timer != null, "Timer de spawn não criado")
	assert(spawner._boss_timer != null, "Timer de boss não criado")
	assert(spawner._queue_timer != null, "Timer de fila não criado")
	
	# Verificar configurações
	assert(spawner._spawn_timer.wait_time == spawner.base_spawn_interval, "Wait time do spawn timer incorreto")
	assert(spawner._boss_timer.wait_time == spawner.boss_spawn_time, "Wait time do boss timer incorreto")
	assert(spawner._boss_timer.one_shot == true, "Boss timer não é one_shot")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de setup dos timers passou")

func test_spawn_wave():
	var spawner = EnemySpawner.new()
	spawner.enemy_scenes = [preload("res://enemies/Inimigo.tscn")]
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente, _container será o parent
	
	# Simular spawn de onda
	spawner._spawn_wave()
	
	# Verificar se fila foi preenchida
	assert(spawner._spawn_queue > 0, "Fila de spawn não foi preenchida")
	
	# Verificar contagem relativa de filhos no container (antes do tick)
	var children_before = spawner._container.get_child_count()
	
	# Simular processamento da fila
	spawner._on_queue_tick()
	assert(spawner.active_enemy_count > 0, "Inimigo não foi spawnado da fila")
	assert(spawner._container.get_child_count() > children_before, "Nenhum inimigo adicionado ao container")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de spawn de onda passou")

func test_difficulty_scaling():
	var spawner = EnemySpawner.new()
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente
	
	# Verificar step inicial (tempo = 0)
	var step = spawner._get_current_step()
	assert(step == 0, "Step inicial deve ser 0")
	
	var interval = spawner._get_current_spawn_interval()
	assert(abs(interval - spawner.base_spawn_interval) < 0.01, "Intervalo inicial incorreto")
	
	# Verificar propriedades de dificuldade (nomes corretos do script)
	assert(spawner.difficulty_step_seconds > 0, "Step de dificuldade deve ser positivo")
	assert(spawner.speed_increase_percent > 0, "Percentual de velocidade deve ser positivo")
	assert(spawner.health_increase_percent > 0, "Percentual de vida deve ser positivo")
	assert(spawner.interval_decrease_per_step > 0, "Redução de intervalo deve ser positiva")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de escalonamento de dificuldade passou")

func test_boss_spawn():
	var spawner = EnemySpawner.new()
	spawner.boss_scene = preload("res://enemies/Inimigo.tscn")
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente
	
	# Simular timeout do boss
	spawner._on_boss_timeout()
	
	assert(spawner.state == spawner.SpawnerState.BOSS_PHASE, "Estado não mudou para BOSS_PHASE")
	assert(spawner._spawn_timer.is_stopped(), "Timer de spawn não parou")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de spawn do boss passou")

func test_pause_resume():
	var spawner = EnemySpawner.new()
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente
	
	# Pausar
	spawner.pause()
	assert(spawner.state == spawner.SpawnerState.PAUSED, "Estado não mudou para PAUSED")
	assert(spawner._spawn_timer.is_stopped(), "Timer de spawn não parou no pause")
	assert(spawner._boss_timer.is_stopped(), "Timer de boss não parou no pause")
	
	# Retomar
	spawner.resume()
	assert(spawner.state == spawner.SpawnerState.ACTIVE, "Estado não voltou para ACTIVE")
	assert(not spawner._spawn_timer.is_stopped(), "Timer de spawn não reiniciou")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de pause/resume passou")

func test_queue_processing():
	var spawner = EnemySpawner.new()
	spawner.enemy_scenes = [preload("res://enemies/Inimigo.tscn")]
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente
	
	# Adicionar à fila (mantém multiplicadores em 1.0 para teste isolado de fila)
	spawner._spawn_queue = 5
	
	# Verificar contagem relativa de filhos antes do processamento
	var children_before = spawner._container.get_child_count()
	
	# Processar fila
	for i in range(5):
		spawner._on_queue_tick()
	
	assert(spawner._spawn_queue == 0, "Fila não foi processada completamente")
	assert(spawner.active_enemy_count == 5, "Nem todos os inimigos foram spawnados")
	assert(spawner._container.get_child_count() - children_before == 5, "Inimigos não adicionados ao container")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de processamento da fila passou")

func test_enemy_cap():
	var spawner = EnemySpawner.new()
	spawner.max_enemies_on_screen = 3
	spawner.enemy_scenes = [preload("res://enemies/Inimigo.tscn")]
	var container = Node.new()
	add_child(container)
	container.add_child(spawner)  # _ready() é chamado automaticamente
	
	# Tentar adicionar mais inimigos que o cap permite
	spawner._spawn_queue = 10
	
	# Verificar contagem relativa de filhos antes do processamento
	var children_before = spawner._container.get_child_count()
	
	# Processar fila
	for i in range(10):
		spawner._on_queue_tick()
	
	assert(spawner.active_enemy_count <= spawner.max_enemies_on_screen, "Cap de inimigos não respeitado")
	assert(spawner._container.get_child_count() - children_before <= spawner.max_enemies_on_screen, "Cap não refletido no container")
	
	spawner.queue_free()
	container.queue_free()
	print("✓ Teste de cap de inimigos passou")