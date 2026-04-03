extends Node

# Script de teste para character_body_2d (Inimigo base)

func _ready():
	print("Executando Testes do Inimigo Base...")
	# Nota: Os testes rodam em sequência. Cada teste faz queue_free(), mas a destruição
	# é enfileirada para o fim do frame. Se um teste falhar antes de queue_free,
	# pode haver estado vazado que interfira em testes subsequentes.
	test_apply_difficulty_modifiers()
	test_take_damage_nonfatal()
	test_take_damage_fatal()
	test_take_damage_postmortem()
	test_death_signal()
	print("Todos os testes do Inimigo Base concluídos!")

func test_apply_difficulty_modifiers():
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(enemy)  # _ready() é chamado automaticamente
	
	# Os valores base são setados automaticamente pelo _ready()
	# Verificar que os valores base foram capturados corretamente
	var base_speed = enemy._base_speed
	var base_max_health = enemy._base_max_health
	
	assert(base_speed > 0, "Base speed não foi inicializado")
	assert(base_max_health > 0, "Base max_health não foi inicializado")
	
	# Aplicar modificadores
	enemy.apply_difficulty_modifiers(1.2, 1.5)
	
	assert(abs(enemy.speed - base_speed * 1.2) < 0.01, "Velocidade não aplicada corretamente")
	assert(abs(enemy.max_health - base_max_health * 1.5) < 0.01, "Vida máxima não aplicada corretamente")
	assert(abs(enemy.health - base_max_health * 1.5) < 0.01, "Vida atual não atualizada")
	
	# Teste de idempotência
	enemy.apply_difficulty_modifiers(1.2, 1.5)
	assert(abs(enemy.speed - base_speed * 1.2) < 0.01, "Modificadores não são idempotentes para velocidade")
	assert(abs(enemy.max_health - base_max_health * 1.5) < 0.01, "Modificadores não são idempotentes para vida")
	
	enemy.queue_free()
	print("✓ Teste de aplicação de modificadores de dificuldade passou")

func test_take_damage_nonfatal():
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(enemy)  # _ready() é chamado automaticamente
	
	# Guardar vida máxima
	var max_hp = enemy.max_health
	
	# Tomar dano não-letal (30% da vida — sempre abaixo do máximo)
	var partial_damage = max_hp * 0.3
	enemy.take_damage(partial_damage)
	assert(abs(enemy.health - (max_hp - partial_damage)) < 0.01, "Dano não aplicado corretamente")
	assert(not enemy._is_dead, "Flag de morte incorreta após dano não-letal")
	
	enemy.queue_free()
	print("✓ Teste de take_damage (não-fatal) passou")

func test_take_damage_fatal():
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(enemy)  # _ready() é chamado automaticamente
	
	var max_hp = enemy.max_health
	
	# Tomar dano letal
	enemy.take_damage(max_hp)  # Dano suficiente para matar
	assert(abs(enemy.health) < 0.01, "Vida não zerada após dano letal")
	assert(enemy._is_dead, "Flag de morte não setada")
	
	# Guard: take_damage pode chamar queue_free internamente
	if is_instance_valid(enemy):
		enemy.queue_free()
	print("✓ Teste de take_damage (fatal) passou")

func test_take_damage_postmortem():
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(enemy)  # _ready() é chamado automaticamente
	
	var max_hp = enemy.max_health
	
	# Matar o inimigo
	enemy.take_damage(max_hp)
	assert(enemy._is_dead, "Flag de morte não setada")
	
	# Tomar dano após morto (não deve fazer nada) — usar is_instance_valid para segurança
	if is_instance_valid(enemy):
		var health_before = enemy.health
		enemy.take_damage(10)
		assert(abs(enemy.health - health_before) < 0.01, "Dano aplicado após morte")
		assert(enemy._is_dead, "Flag de morte alterada após morte")
		
		enemy.queue_free()
	print("✓ Teste de take_damage (post-mortem) passou")

func test_death_signal():
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(enemy)  # _ready() é chamado automaticamente
	
	var signal_emitted = false
	enemy.died.connect(func(): signal_emitted = true)
	
	# Matar o inimigo
	enemy.take_damage(enemy.max_health)
	
	assert(signal_emitted, "Sinal 'died' não foi emitido")
	
	# Apenas fazer queue_free se o nó ainda é válido (ele pode ter sido destruído internamente)
	if is_instance_valid(enemy):
		enemy.queue_free()
	print("✓ Teste de sinal de morte passou")