class_name MapBench
extends RefCounted
## Reserva (bench estilo TFT) de um time: faixa plana no terraço do anel, colada a um lado
## comprido da arena. Só dado e consulta; slots e regras de reserva são de uma spec futura.

## 0 = sul (embaixo na câmera padrão), 1 = norte.
var team: int = 0
## Área útil (onde a peça pode ficar), em unidades do mundo.
var rect: Rect2 = Rect2()
## Faixa inteira da reserva (inclui as bordas fora da área útil).
var terrace_rect: Rect2 = Rect2()
## Altura do piso da reserva.
var height: float = 0.0
