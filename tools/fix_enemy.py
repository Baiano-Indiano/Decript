import re

with open('Inimigo.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

old_td = r'func take_damage\(amount\):.*?\t\tdie\(\)'
new_td = '''func take_damage(amount, knockback_dir = Vector2.ZERO):
\thealth -= amount
\tmodulate = Color.RED
\t
\tif knockback_dir != Vector2.ZERO:
\t\tvelocity = knockback_dir * 300
\t\tmove_and_slide()
\t\t
\tawait get_tree().create_timer(0.1).timeout
\tmodulate = Color.WHITE
\t
\tif health <= 0:
\t\tdie()'''
text = re.sub(old_td, new_td, text, flags=re.DOTALL)

old_die = r'func die\(\):.*?\tqueue_free\(\)'
new_die = '''const ALMA_SCENE = preload("res://alma.tscn")

func die():
\tvar alma = ALMA_SCENE.instantiate()
\talma.global_position = global_position
\tget_parent().call_deferred("add_child", alma)
\tqueue_free()'''
text = re.sub(old_die, new_die, text, flags=re.DOTALL)

with open('Inimigo.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
print('Enemy patched')
