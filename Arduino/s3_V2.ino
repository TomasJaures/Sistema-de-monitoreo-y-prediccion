#include <M5Unified.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>

// ============================================================================
// PINES
// ============================================================================
const int PIN_MOSFET  = 1;
const int PIN_I2C_SDA = 2;
const int PIN_I2C_SCL = 3;
const int PIN_DFR0051 = 4;

// ============================================================================
// OBJETOS Y VARIABLES GLOBALES
// ============================================================================
TwoWire I2C_External = TwoWire(1);
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// Caché para sensores lentos
float temp_amb_cache = 0.0;
float temp_obj_cache = 0.0;
int adc_mv_cache     = 0;

unsigned long ultimo_tiempo_lento = 0;

void setup() {
  auto cfg = M5.config();
  M5.begin(cfg);

  // Aumentamos la velocidad del puerto serie a 115200 (o 921600 si requieres máxima frecuencia)
  Serial.begin(115200);

  // Encender motor vía MOSFET
  pinMode(PIN_MOSFET, OUTPUT);
  digitalWrite(PIN_MOSFET, HIGH);

  // Inicializar I2C para GY-906
  I2C_External.begin(PIN_I2C_SDA, PIN_I2C_SCL, 100000);
  mlx.begin(0x5A, &I2C_External);

  // Encabezado CSV para el programa externo (opcional)
  Serial.println("timestamp_ms,ax,ay,az,temp_ambiente,temp_objeto,adc_mv");
}

void loop() {
  M5.update();

  // 1. Lectura periódica de sensores lentos (cada 500 ms)
  if (millis() - ultimo_tiempo_lento >= 500) {
    ultimo_tiempo_lento = millis();
    
    temp_amb_cache = mlx.readAmbientTempC();
    temp_obj_cache = mlx.readObjectTempC();
    adc_mv_cache   = analogReadMilliVolts(PIN_DFR0051);
  }

  // 2. Lectura directa e instantánea del acelerómetro
  M5.Imu.update();
  auto imu = M5.Imu.getImuData();

  // 3. Envío directo de datos crudos vía Serial en formato CSV
  Serial.print(millis());
  Serial.print(",");
  Serial.print(imu.accel.x, 4);
  Serial.print(",");
  Serial.print(imu.accel.y, 4);
  Serial.print(",");
  Serial.print(imu.accel.z, 4);
  Serial.print(",");
  Serial.print(temp_amb_cache, 2);
  Serial.print(",");
  Serial.print(temp_obj_cache, 2);
  Serial.print(",");
  Serial.println(adc_mv_cache);

  // Controla la frecuencia de muestreo del acelerómetro (~200 Hz = 5 ms)
  delay(5); 
}