# O VAZIO (Projeto Godot)

Um jogo top-down roguelite no estilo *Vampire Survivors*. O jogador controla "O Vazio", um ser que absorve almas para se fortalecer e sobreviver a hordas de mortos-vivos.

## 🚀 Como Rodar o Jogo
1. Baixe a engine [Godot 4.x](https://godotengine.org/).
2. Abra o executável e clique em **Import** (Importar).
3. Selecione o arquivo `project.godot` que está na raiz desta pasta.
4. Para testar o jogo, pressione `F5` ou clique no botão de "Play" no canto superior direito para rodar a cena principal (`Main.tscn`).

---

## 📁 Estrutura do Projeto
O projeto foi modelado usando uma **Arquitetura Baseada em Componentes e Arquivos**, separando claramente as lógicas por suas *Features* (Funcionalidades). Isso evita conflitos e facilita a escalabilidade.

```
res://
├── assets/         # Sprites, efeitos sonoros e músicas.
├── collectibles/   # Itens que dropam no chão (ex: alma.tscn / pedras de XP).
├── enemies/        # Inimigos, seus comportamentos e o Spawner de hordas.
├── levels/         # Mapas (Cenas onde o gameplay acontece, ex: Main.tscn).
├── player/         # O personagem controlável, vida e câmera.
├── weapons/        # Armas, projéteis e suas lógicas de ataque e cooldown.
└── tools/          # Scripts/Ferramentas do projeto externo.
```

---

## 🤝 Colaboração (Fluxo da Equipe)

O desenvolvimento é dividido de forma paralela via Git/GitHub:

### 🛠️ Programação / Scripts
- **Responsabilidades:** Lógica matemática, inteligência artificial, movimentação, disparos automáticos e detecção de colisões no Godot (arquivos `.gd`). Sistemas numéricos (XP, Vida, Dano) e diretrizes de tempo para o Spawner.
- **Como trabalhar sem quebrar nada:** Construa os nós internos lógicos ou exponha parâmetros (`@export var dano = 10`) nos scripts para que o Designer apenas precise mexer nos valores visuais de fora.

### 🎨 Level Design / UI
- **Responsabilidades:** Trabalhar nas Cenas visuais, ajustando sprites (`Sprite2D`), texturas de terreno (`TileMapLayer`), Interfaces bonitas (`CanvasLayer` para Vida/Contadores) e Partículas (`GPUParticles2D`).
- **Como trabalhar sem quebrar nada:** Você pode abrir cenas baseadas nos scripts do Programador e **alterar o Design dos Nós** visualmente em cima desse código rodando sem risco de conflito na aba *Scripts*. Salve as UIs em Cenas Próprias (como `HUD.tscn`) e insira dentro na cena Final.

---

> Evitem editar o exato mesmo arquivo `.tscn` enorme ao mesmo tempo no mesmo ramo (branch). Trabalhem em *features* modulares e instanciem uma cena dentro da outra.
