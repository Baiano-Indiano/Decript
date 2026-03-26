import re

with open('Inimigo.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r'@export var zumbi_scene: PackedScene.*?add_child\(zumbi\)\n\t', '', text, flags=re.DOTALL)

with open('Inimigo.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
print('Inimigo cleaned')

with open('project.godot', 'r', encoding='utf-8') as f:
    godot_text = f.read()
    
if '[layer_names]' not in godot_text:
    with open('project.godot', 'a', encoding='utf-8') as f:
        f.write('\n[layer_names]\n\n2d_physics/layer_1="Player"\n2d_physics/layer_2="Inimigos"\n2d_physics/layer_3="Projeteis"\n2d_physics/layer_4="Ambiente"\n')
    print('Layers added')
