# Roadmap — Malandragem

Este documento acompanha a evolução do protótipo. Ele deve ser atualizado sempre
que uma funcionalidade for concluída ou mudar de escopo.

## Legenda

- [x] Concluído
- [ ] Pendente
- 🚧 Implementado parcialmente

## 1. Melhorar o personagem

- [x] Câmera suave com zoom
- [x] Caminhada e corrida
- [x] Aceleração e desaceleração
- [x] Controle no ar
- [x] Animações provisórias

### Estado atual

O controlador em terceira pessoa possui movimento relativo à câmera, corrida,
controle aéreo, pulo com altura variável, *coyote time* e buffer de pulo. Os
estados `idle`, `walk`, `sprint`, `jump` e `fall` controlam as animações
procedurais do homem low poly. No futuro, elas poderão ser substituídas por
animações esqueléticas usando um `AnimationTree`.

## 2. Construir um quarteirão low poly

- [x] Ruas, calçadas e cruzamento
- [ ] Prédios modulares simples — 🚧 os prédios existem, mas ainda precisam virar cenas individuais reutilizáveis
- [x] Postes, árvores e obstáculos
- [x] Colisões organizadas

### Estado atual

O mapa possui quatro trechos de quarteirão conectados por um cruzamento, faixas
de pedestres, semáforos, postes, árvores e três estilos provisórios de prédio.
A composição geral já está separada nas cenas `city_map.tscn`,
`intersection.tscn` e `quarter_block.tscn`.

## 3. Criar o primeiro carro

- [x] Aceleração, freio e ré
- [x] Direção e câmera
- [ ] Suspensão simplificada
- [x] Entrada e saída do veículo

### Estado atual

O primeiro carro utiliza uma física arcade baseada em `CharacterBody3D`. Ele
possui direção sensível à velocidade, colisões, desaceleração natural, câmera
própria e integração com o personagem pela tecla `E`. A suspensão visual e a
adaptação individual das rodas ao terreno ainda não foram implementadas.

## 4. Adicionar NPCs

- [ ] Pedestres caminhando
- [ ] Rotas simples
- [ ] Reação ao jogador e veículos
- [ ] Trânsito básico

### Próximo resultado esperado

Um pedestre low poly deve percorrer uma rota de pontos, parar diante de um
obstáculo e reagir quando um veículo se aproximar.

## 5. Criar a primeira missão

- [ ] Marcadores no mapa
- [ ] Objetivos e mensagens
- [ ] Condições de sucesso e falha
- [ ] Recompensa provisória

### Próximo resultado esperado

O jogador deve entrar no carro, dirigir até um marcador, coletar um objeto e
entregá-lo em outro ponto para concluir a missão.

## 6. Sistema de procurado

- [ ] Níveis de alerta
- [ ] Perseguição policial
- [ ] Área de busca
- [ ] Perda gradual do alerta

### Próximo resultado esperado

Uma infração deve ativar o primeiro nível de alerta. O jogador poderá escapar
saindo da área de busca e permanecendo fora da visão policial por um período.

## Próxima prioridade

1. Implementar suspensão visual no carro.
2. Criar o primeiro pedestre com rota simples.
3. Transformar os prédios em módulos reutilizáveis.
