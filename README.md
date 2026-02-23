LABORATORIO 3 – CONTADOR 00–59 CON INTERRUPCIONES

Descripción:
En este laboratorio se implementó un contador de segundos utilizando el microcontrolador ATmega328P y dos displays de 7 segmentos multiplexados.
El sistema simula el funcionamiento de los segundos de un reloj digital, contando desde 00 hasta 59 y reiniciando automáticamente.

Funcionalidades:

- Conteo automático de 00 a 59.
- Multiplexado de dos displays de 7 segmentos.
- Base de tiempo generada por Timer0.
- Interrupciones utilizadas para:
- Timer0 (conteo de tiempo).
- PCINT (botones).
- Contador binario independiente controlado por botones.
- Funcionamiento
- Timer0 genera interrupciones cada ~10 ms.
- Cada 100 interrupciones se completa 1 segundo.
- El contador incrementa unidades (0–9).
- Al llegar a 10, incrementa decenas (0–5).
- Al llegar a 60, el contador se reinicia a 00.
- Los displays se multiplexan alternando rápidamente entre unidades y decenas.

Hardware Utilizado
- ATmega328P – 16 MHz
- 2 Displays de 7 segmentos (cátodo común)
- 4 LEDs para contador binario
- 2 Pushbuttons
- Resistencias de 220 Ω

Conceptos Aplicados:
- Manejo de interrupciones.
- Configuración de Timer0.
- Multiplexado de displays.
- Detección de flancos mediante PCINT.
