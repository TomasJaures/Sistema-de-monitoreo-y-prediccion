# MockArduino

Simula el Arduino (`Arduino/s3_V2.ino`) cuando no tenés el M5Stick a mano, para
poder probar el flujo real de `Motor.pde`: listar puertos seriales, "conectar"
y ver datos moviéndose en el panel.

Processing solo puede abrir un puerto serie real (COM en Windows, `/dev/tty*`
en Mac/Linux), así que hace falta un **par de puertos virtuales enlazados**:
lo que se escribe en uno sale por el otro, como si fuera un cable serie.

## 1. Crear el par de puertos virtuales

**Windows** — instalar [com0com](https://com0com.sourceforge.net/) (gratis,
código abierto) y crear un par durante la instalación o con su instalador de
pares (`setupc.exe`). Vas a terminar con dos puertos, p.ej. `CNCA0` y `CNCB0`.

**macOS / Linux** — no hace falta instalar nada, `socat` ya trae lo necesario:

```bash
socat -d -d pty,raw,echo=0,link=/tmp/ttyFAKE0 pty,raw,echo=0,link=/tmp/ttyFAKE1
```

Dejalo corriendo en su propia terminal; crea `/tmp/ttyFAKE0` y `/tmp/ttyFAKE1`,
enlazados entre sí.

## 2. Instalar pyserial

```bash
pip install pyserial
```

## 3. Correr el emisor falso

Apuntalo a **uno** de los dos extremos del par (p.ej. `CNCA0` o `/tmp/ttyFAKE0`):

```bash
python fake_motor_sender.py CNCA0
```

Por defecto rota las 4 fases del protocolo de ensayo del manual (línea base →
fallo severo) cada 20 segundos, para que se vea el panel cambiando de estado.
Para fijar una sola fase:

```bash
python fake_motor_sender.py CNCA0 --phase 3   # vibración severa (1 perno)
```

## 4. "Conectar" desde Processing

En `Motor.pde`, dejá `setupArduino();` descomentado en `setup()` y corré el
sketch una vez para ver la lista de puertos en la consola de Processing
(`printArray(Serial.list())`). Buscá ahí el índice del **otro** extremo del
par (p.ej. `CNCB0` o `/tmp/ttyFAKE1`) y ponelo en `PORT_ID`. También recordá
presionar **espacio** al arrancar para pausar la simulación — si no,
`updateSimulation()` sigue pisando los valores con datos falsos propios de
`Motor.pde` en vez de los que manda este script.

El formato que emite este script es idéntico al de `Arduino/s3_V2.ino`
(`timestamp_ms,ax,ay,az,temp_ambiente,temp_objeto,adc_mv` a 115200 baudios),
así que `serialEvent()` en `Motor.pde` lo procesa exactamente igual que al
hardware real.
