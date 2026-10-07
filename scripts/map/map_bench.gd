class_name MapBench
extends RefCounted
## Reserva (bench estilo TFT) de um time: terraço plano num lado comprido da arena.
## Só dado e consulta; slots e regras de reserva são de uma spec futura.

## 0 = sul (embaixo na câmera padrão), 1 = norte.
var team: int = 0
## Área útil (onde a peça pode ficar), em unidades do mundo.
var rect: Rect2 = Rect2()
## Terraço inteiro (inclui escadas e as bordas).
var terrace_rect: Rect2 = Rect2()
var level: int = 0
