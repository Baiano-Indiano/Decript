import re

with open('Projetil.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

old_body = r'func _on_body_entered\(body\):.*?\t\tqueue_free\(\)\n'
new_body = '''func _on_body_entered(body):
\tprint("Projétil encostou em algo: ", body.name)
\tif body.has_method("take_damage"):
\t\tbody.take_damage(damage, direction)
\t\t
\t\tvar camera = get_viewport().get_camera_2d()
\t\tif camera and camera.has_method("apply_shake"):
\t\t\tcamera.apply_shake(5.0)
\t\t\t
\t\tqueue_free()
\t
\telif body is TileMapLayer or body is StaticBody2D:
\t\tqueue_free()
'''
text = re.sub(old_body, new_body, text, flags=re.DOTALL)

with open('Projetil.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
print('Projectile patched')
