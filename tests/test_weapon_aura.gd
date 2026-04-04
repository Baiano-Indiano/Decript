extends Node

# Script de teste para AuraDano

func _ready():
	print("Executando Testes da Aura de Dano...")
	await test_dot_damage()
	await test_overlapping_bodies()
	print("Todos os testes da Aura de Dano concluídos!")

func test_dot_damage():
	var aura = preload("res://weapons/AuraDano.tscn").instantiate()
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(aura)
	add_child(enemy)
	
	# Posicionar inimigo dentro da aura
	enemy.position = aura.position
	await get_tree().physics_frame  # Aguardar física processar sobreposição
	await get_tree().create_timer(aura.interval + 0.1).timeout
	
	# Verificar se dano foi aplicado
	assert(enemy.health < enemy.max_health, "Dano DoT não foi aplicado")
	
	aura.queue_free()
	enemy.queue_free()
	print("✓ Teste de dano DoT passou")

func test_overlapping_bodies():
	var aura = preload("res://weapons/AuraDano.tscn").instantiate()
	var enemy1 = preload("res://enemies/Inimigo.tscn").instantiate()
	var enemy2 = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(aura)
	add_child(enemy1)
	add_child(enemy2)
	
	# Posicionar inimigos dentro da aura
	enemy1.position = aura.position
	enemy2.position = aura.position + Vector2(50, 0)  # Dentro do raio
	await get_tree().physics_frame  # Aguardar física processar sobreposição
	await get_tree().create_timer(aura.interval + 0.1).timeout
	
	# Verificar se ambos sofreram dano
	assert(enemy1.health < enemy1.max_health, "Inimigo 1 não sofreu dano DoT")
	assert(enemy2.health < enemy2.max_health, "Inimigo 2 não sofreu dano DoT")
	
	aura.queue_free()
	enemy1.queue_free()
	enemy2.queue_free()
	print("✓ Teste de corpos sobrepostos passou")