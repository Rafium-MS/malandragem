# Cidade Low Poly

Protótipo inicial de um jogo 3D de mundo aberto feito com Godot 4 e GDScript.

## Como executar

1. Abra a Godot e clique em **Importar**.
2. Selecione `project.godot` nesta pasta.
3. Abra o projeto e pressione **F6** ou **F5**.

## Controles

- `WASD` ou setas: movimentar
- `Shift`: correr
- Mouse: girar câmera e personagem
- Roda do mouse: aproximar ou afastar a câmera
- Espaço: pular
- `Esc`: liberar o cursor
- Clique: capturar o cursor novamente
- `E`: entrar ou sair de um veículo próximo

### Veículo

- `W` / `S`: acelerar e dar ré
- `A` / `D`: virar
- Espaço: frear
- Mouse: controlar a câmera do veículo

## Colaboracao com Git

- Cada pessoa trabalha em uma branch propria: `git switch -c nome/tarefa`.
- Evitem editar a mesma cena `.tscn` ao mesmo tempo.
- Separem objetos reutilizaveis em cenas proprias.
- Facam commits pequenos, descrevendo uma unica mudanca.
- Nao versionem a pasta `.godot`; ela e gerada localmente.

## Próximos marcos

- Refinar o controlador e adicionar animações
- Construir um quarteirão modular
- Variar fachadas e adicionar mais objetos urbanos
- Criar o primeiro veículo
- Implementar entrada e saída do veículo
