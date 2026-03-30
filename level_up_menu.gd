extends CanvasLayer

var player: Node
var options: Array

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	$Panel/VBoxContainer/Button1.connect("pressed", Callable(self, "_on_button1_pressed"))
	$Panel/VBoxContainer/Button2.connect("pressed", Callable(self, "_on_button2_pressed"))
	$Panel/VBoxContainer/Button3.connect("pressed", Callable(self, "_on_button3_pressed"))

func show_menu(p_player, p_options):
	player = p_player
	options = p_options
	$Panel/VBoxContainer/Button1.text = options[0]["description"] if options.size() > 0 else "No Upgrade"
	$Panel/VBoxContainer/Button2.text = options[1]["description"] if options.size() > 1 else "No Upgrade"
	$Panel/VBoxContainer/Button3.text = options[2]["description"] if options.size() > 2 else "No Upgrade"
	
	# Hide buttons if no options
	$Panel/VBoxContainer/Button1.visible = options.size() > 0
	$Panel/VBoxContainer/Button2.visible = options.size() > 1
	$Panel/VBoxContainer/Button3.visible = options.size() > 2
	
	show()

func _on_button1_pressed():
	if options.size() > 0:
		player.apply_upgrade(options[0]["type"])
	hide()
	get_tree().paused = false

func _on_button2_pressed():
	if options.size() > 1:
		player.apply_upgrade(options[1]["type"])
	hide()
	get_tree().paused = false

func _on_button3_pressed():
	if options.size() > 2:
		player.apply_upgrade(options[2]["type"])
	hide()
	get_tree().paused = false
    queue_free()  # remove o nó da árvore e libera memória