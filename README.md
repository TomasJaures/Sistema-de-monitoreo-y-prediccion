# Monitor de Motor DC — Mantenimiento Predictivo
Panel gráfico en Processing que muestra en tiempo real el estado de un motor DC (vibración, temperatura y voltaje), pensado para un ensayo de mantenimiento predictivo con un **M5Stick S3 (ESP32-S3)** como datalogger. Cada variable se clasifica en 5 estados (ÓPTIMO → BUENO → REGULAR → ALERTA → CRÍTICO) y el motor dibujado en pantalla reacciona visualmente: la carcasa se tiñe de rojo con la temperatura, los cables chispean con el voltaje y todo el dibujo tiembla con la vibración.

Puede correr de dos formas:

- **Simulado** (por defecto, sin hardware): valores oscilando artificialmente.
- **Conectado al Arduino real**: leyendo el CSV que manda el M5Stick por USB.

## Estructura del proyecto

| Archivo / carpeta  | Qué hace                                                               |
| ------------------ | ---------------------------------------------------------------------- |
| `Motor.pde`        | Sketch principal: setup, loop de dibujo, lectura serial y simulación   |
| `EngineVar.pde`    | Modela una variable monitoreada (valor, rango, límites de estado)      |
| `EngineLayout.pde` | Dibuja las tarjetas de estado y el resumen general                     |
| `EngineImage.pde`  | Dibuja el motor DC ilustrado y sus efectos visuales                    |

## Requisitos

- **Processing 4.5.6** o superior ([processing.org/download](https://processing.org/download))
## Uso rápido (modo simulado)

1. Abrir `Motor.pde` con Processing.
2. Presionar ▶ (Run). El panel arranca directamente en modo simulado —no requiere ningún puerto conectado.
3. Presionar **espacio** en cualquier momento para pausar/reanudar la simulación.

## Conectar el M5Stick S3 real
1. Conectarlo por USB y correr `Motor.pde` una vez con `setupArduino();` **sin descomentar todavía** — la consola de Processing va a listar los puertos disponibles (`Serial.list()`).
2. Identificar el índice del M5Stick en esa lista y asignarlo a `PORT_ID` (línea ~14 de `Motor.pde`).
3. Descomentar la llamada a `setupArduino();` dentro de `setup()`.
4. Volver a correr el sketch y presionar **espacio** para pausar la simulación — si no, `updateSimulation()` sigue pisando los valores con datos falsos en vez de los que manda el Arduino.

## Calibración
El Arduino manda datos crudos (aceleración en g, temperatura IR, milivolts), no las unidades que muestra el panel. La conversión vive al principio de `Motor.pde`:

- `VOLTAGE_SCALE` — factor del divisor DFR0051 (5:1), confirmado por el manual.
- `VIBRATION_SCALE` — factor aproximado de RMS de aceleración a la escala visual del panel; **no está calibrado con un instrumento real**, ajustarlo comparando contra un vibrómetro de referencia.
- Los límites de estado de cada variable (`setStatesLimits(...)` dentro de `setupEngineVars()`) son estimados para el motor DC de 5V del banco de pruebas — conviene afinarlos con datos reales de los 4 ensayos del manual (línea base, holgura leve, desbalance moderado, fallo severo).