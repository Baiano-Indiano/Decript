extends Node

# Script de teste para EspadaGiratoria

func _ready():
	print("Executando Testes da Espada Giratória...")
	test_orbital_movement()
	test_damage_on_contact()
	test_damage_cooldown()
	print("Todos os testes da Espada Giratória concluídos!")

func test_orbital_movement():
	var sword = preload("res://weapons/EspadaGiratoria.tscn").instantiate()
	add_child(sword)
	var area = sword.get_node("Area2D")
	
	# Simular alguns frames
	for i in range(10):
		area._process(0.1)  # 0.1 segundo por frame
	
	# Verificar se a posição mudou (órbita)
	assert(area.position != Vector2.ZERO, "Espada não se moveu em órbita")
	
	sword.queue_free()
	print("✓ Teste de movimento orbital passou")

func test_damage_on_contact():
	var sword = preload("res://weapons/EspadaGiratoria.tscn").instantiate()
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(sword)
	add_child(enemy)
	
	# Posicionar inimigo dentro da área da espada
	enemy.position = sword.position + Vector2(10, 0)
	var area = sword.get_node("Area2D")
	area._on_body_entered(enemy)
	
	# Verificar se dano foi aplicado
	assert(enemy.health < enemy.max_health, "Dano não foi aplicado ao inimigo")
	
	sword.queue_free()
	enemy.queue_free()
	print("✓ Teste de dano no contato passou")

func test_damage_cooldown():
	var sword = preload("res://weapons/EspadaGiratoria.tscn").instantiate()
	var enemy = preload("res://enemies/Inimigo.tscn").instantiate()
	add_child(sword)
	add_child(enemy)
	
	enemy.position = sword.position + Vector2(10, 0)
	var area = sword.get_node("Area2D")
	
	# Primeiro dano
	var initial_health = enemy.health
	area._on_body_entered(enemy)
	assert(enemy.health < initial_health, "Primeiro dano não aplicado")
	
	# Segundo dano imediato (deve ser bloqueado pelo cooldown)
	var health_after_first = enemy.health
	area._on_body_entered(enemy)
	assert(enemy.health == health_after_first, "Cooldown não funcionou - dano aplicado prematuramente")
	
	sword.queue_free()
	enemy.queue_free()
	print("✓ Teste de cooldown de dano passou")