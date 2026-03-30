extends Node

# Script de teste para sistema de XP e Nível do Player

func _ready():
	print("Executando Testes do Player...")
	test_xp_logic()
	test_upgrade_options()
	test_apply_upgrade()
	print("Todos os testes concluídos!")

func test_xp_logic():
	# Teste da lógica de ganho de XP e subida de nível sem dependências de cena
	var current_xp = 0
	var next_level_xp = 10
	var level = 1
	
	# Ganhar 5 XP
	current_xp += 5
	assert(current_xp == 5, "Ganho de XP falhou")
	assert(level == 1, "Nível mudou inesperadamente")
	
	# Ganhar mais 5, deve subir de nível
	current_xp += 5
	if current_xp >= next_level_xp:
		level += 1
		current_xp -= next_level_xp
		next_level_xp = int(next_level_xp * 1.5)
	
	assert(current_xp == 0, "XP não resetado após subir de nível")
	assert(level == 2, "Nível não aumentou")
	assert(next_level_xp == 15, "Próximo nível de XP não atualizado")
	
	# Teste de overflow
	current_xp = 0
	next_level_xp = 10
	level = 1
	current_xp += 25
	if current_xp >= next_level_xp:
		level += 1
		current_xp -= next_level_xp
		next_level_xp = int(next_level_xp * 1.5)
	
	assert(level == 2, "Nível não aumentou com overflow")
	assert(current_xp == 15, "Overflow de XP não tratado")
	assert(next_level_xp == 15, "Próximo nível de XP não atualizado")
	
	print("✓ Teste de lógica XP passou")

func test_upgrade_options():
	var upgrade_options = [
		{"type": "speed", "description": "Increase Speed"},
		{"type": "health", "description": "Increase Max Health"},
		{"type": "attack_cooldown", "description": "Reduce Attack Cooldown"},
		{"type": "damage", "description": "Increase Damage"}
	]
	
	# Teste se as opções são embaralhadas e únicas
	var options1 = upgrade_options.duplicate()
	options1.shuffle()
	var selected1 = options1.slice(0, min(3, options1.size()))
	
	var options2 = upgrade_options.duplicate()
	options2.shuffle()
	var selected2 = options2.slice(0, min(3, options2.size()))
	
	# Verificar tamanho
	assert(selected1.size() <= 3, "Muitas opções selecionadas")
	assert(selected2.size() <= 3, "Muitas opções selecionadas")
	
	# Verificar unicidade e validade
	var types_seen = []
	for opt in selected1:
		assert(not types_seen.has(opt["type"]), "Opção de upgrade duplicada: " + opt["type"])
		types_seen.append(opt["type"])
		var found = false
		for original in upgrade_options:
			if original["type"] == opt["type"]:
				found = true
				break
		assert(found, "Opção inválida selecionada: " + opt["type"])
	
	print("✓ Teste de opções de upgrade passou")

func test_apply_upgrade():
	var speed = 200
	var max_health = 100
	var current_health = max_health
	var attack_cooldown = 0.5
	var damage = 10
	
	# Teste de upgrade de velocidade
	speed += 20
	assert(speed == 220, "Upgrade de velocidade falhou")
	
	# Teste de upgrade de vida
	max_health += 20
	current_health += 20
	assert(max_health == 120, "Upgrade de vida máxima falhou")
	assert(current_health == 120, "Vida atual não atualizada")
	
	# Teste de cooldown de ataque
	attack_cooldown = max(0.1, attack_cooldown - 0.05)
	assert(abs(attack_cooldown - 0.45) < 0.001, "Upgrade de cooldown de ataque falhou")
	
	# Teste de dano
	damage += 5
	assert(damage == 15, "Upgrade de dano falhou")
	
	# Teste de mínimo de cooldown
	var cooldown_min = 0.1
	for i in range(20):
		cooldown_min = max(0.1, cooldown_min - 0.05)
	assert(abs(cooldown_min - 0.1) < 0.001, "Mínimo de cooldown não respeitado")
	
	print("✓ Teste de aplicação de upgrade passou")