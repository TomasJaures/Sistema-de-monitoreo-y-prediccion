#!/usr/bin/env python3
"""
Emula el datalogger CSV de Arduino/s3_V2.ino (M5Stick S3) para poder probar
el panel de Processing sin tener el hardware conectado.

Escribe por un puerto serie exactamente el mismo formato que manda el firmware
real (ver doc/Manual_Tecnico_Mantenimiento_Predictivo_M5Stick.pdf, secciones 4 y 5):

    timestamp_ms,ax,ay,az,temp_ambiente,temp_objeto,adc_mv

Requiere un puerto serie que Processing pueda abrir del otro lado. Este script
NO crea un puerto virtual por sí solo, necesita un par de puertos enlazados:

  Windows: instalar com0com (https://com0com.sourceforge.net/) y crear un par,
           p.ej. CNCA0 <-> CNCB0 (aparecen como dos puertos, uno para cada extremo).
  macOS/Linux: correr `socat -d -d pty,raw,echo=0,link=/tmp/ttyFAKE0 pty,raw,echo=0,link=/tmp/ttyFAKE1`
           (crea /tmp/ttyFAKE0 y /tmp/ttyFAKE1 enlazados entre sí).

Este script escribe en un extremo del par; en Motor.pde apuntás PORT_ID al índice
del OTRO extremo dentro de Serial.list(), y ahí "conectás" datos falsos como si
fuera el Arduino real.

Uso:
    pip install pyserial
    python fake_motor_sender.py COM8
    python fake_motor_sender.py COM8 --phase 3   # fuerza vibración severa (1 tornillo)
    python fake_motor_sender.py /tmp/ttyFAKE0
"""

import argparse
import random
import time

import serial

BAUD_RATE = 115200
ACCEL_INTERVAL_S = 0.005      # ~200 Hz, igual que el delay(5) del firmware
SLOW_SENSOR_INTERVAL_S = 0.5  # igual que el refresco de temp/voltaje del firmware

# Amplitud de ruido en la aceleración (en g) para cada fase del protocolo de
# ensayo (manual, sección 6): menos tornillos -> más desbalance -> más vibración.
PHASE_NOISE_G = {
    0: 0.01,  # Fase 0: línea base, 4 pernos
    1: 0.04,  # Fase 1: holgura leve, 3 pernos
    2: 0.09,  # Fase 2: desbalance moderado, 2 pernos
    3: 0.18,  # Fase 3: fallo severo, 1 perno
}

NOMINAL_VOLTAGE = 5.0  # motor DC de 5V sin carga (manual, sección 1)
DIVIDER_RATIO = 5.0    # DFR0051 5:1 (manual, sección 5)
AMBIENT_TEMP_C = 24.0


def build_arg_parser():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("port", help="Puerto serie a abrir (p.ej. COM8 o /tmp/ttyFAKE0)")
    parser.add_argument("--baud", type=int, default=BAUD_RATE)
    parser.add_argument(
        "--phase", type=int, choices=[0, 1, 2, 3], default=None,
        help="Fija una fase del protocolo de ensayo. Si se omite, rota las 4 fases.",
    )
    parser.add_argument(
        "--cycle-seconds", type=float, default=20.0,
        help="Duración de cada fase cuando no se fija --phase (default: 20s)",
    )
    return parser


def current_phase(args, elapsed):
    if args.phase is not None:
        return args.phase
    return int(elapsed // args.cycle_seconds) % 4


def fake_accel(noise_g):
    # En reposo el eje Z mide ~1g; el resto del ruido simula la vibración mecánica.
    ax = random.gauss(0, noise_g)
    ay = random.gauss(0, noise_g)
    az = 1.0 + random.gauss(0, noise_g)
    return ax, ay, az


def fake_slow_sensors(elapsed, phase):
    # La temperatura del motor sube con el tiempo, más rápido cuanto peor la fase
    # (más fricción por el desbalance), como describe el protocolo de ensayo.
    heating_rate = 0.02 * (1 + phase)
    temp_objeto = AMBIENT_TEMP_C + min(30.0, heating_rate * elapsed) + random.uniform(-0.3, 0.3)
    temp_ambiente = AMBIENT_TEMP_C + random.uniform(-0.2, 0.2)

    voltage = NOMINAL_VOLTAGE + random.uniform(-0.05, 0.05)
    adc_mv = int(voltage * 1000.0 / DIVIDER_RATIO)

    return temp_ambiente, temp_objeto, adc_mv


def main():
    args = build_arg_parser().parse_args()

    with serial.Serial(args.port, args.baud, timeout=1) as ser:
        print(f"Enviando datos falsos por {args.port} @ {args.baud} baudios. Ctrl+C para detener.")
        ser.write(b"timestamp_ms,ax,ay,az,temp_ambiente,temp_objeto,adc_mv\n")

        start = time.time()
        temp_ambiente, temp_objeto, adc_mv = fake_slow_sensors(0, current_phase(args, 0))
        last_slow_update = start

        try:
            while True:
                now = time.time()
                elapsed = now - start
                phase = current_phase(args, elapsed)

                if now - last_slow_update >= SLOW_SENSOR_INTERVAL_S:
                    temp_ambiente, temp_objeto, adc_mv = fake_slow_sensors(elapsed, phase)
                    last_slow_update = now

                ax, ay, az = fake_accel(PHASE_NOISE_G[phase])

                line = (
                    f"{int(now * 1000)},{ax:.4f},{ay:.4f},{az:.4f},"
                    f"{temp_ambiente:.2f},{temp_objeto:.2f},{adc_mv}\n"
                )
                ser.write(line.encode("ascii"))

                time.sleep(ACCEL_INTERVAL_S)
        except KeyboardInterrupt:
            print("\nDetenido.")


if __name__ == "__main__":
    main()
