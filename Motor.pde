import processing.serial.*;

Serial puerto;
float vibration, temperature, voltage;

boolean simulating = true; // barra espaciadora: pausa/reanuda la simulación

// Duración de un ciclo completo (subida + bajada) de cada variable, en ms.
// Cada variable tiene un período distinto para que no oscilen en sincronía.
final float VIBRATION_PERIOD = 10000; // 5 s subiendo + 5 s bajando
final float TEMPERATURE_PERIOD = 16000; // 8 s subiendo + 8 s bajando
final float VOLTAGE_PERIOD = 12000; // 6 s subiendo + 6 s bajando

EngineVar[] engineVars;
EngineLayout engineLayout;

void setup() {
  size(400, 340);

  // Imprime puertos disponibles en la consola
  printArray(Serial.list());

  // Si el Arduino está conectado, descomenta las 2 líneas de abajo
  // e indica el número de puerto correcto entre corchetes [x]:
  // String nombrePuerto = Serial.list()[0];
  // puerto = new Serial(this, nombrePuerto, 9600);

  setupEngineVars();
}

// Define los 3 bloques de estado y sus límites (Perfect, Good, Mid, Bad, Terrible)
// calibrados según el rango que ya usa la simulación de cada variable.
void setupEngineVars() {
  EngineVar vibrationVar = new EngineVar("Vibración");
  vibrationVar.setStatesLimits(2, 4, 6, 8, 10);

  EngineVar temperatureVar = new EngineVar("Temperatura");
  temperatureVar.setStatesLimits(32, 44, 56, 68, 80);

  EngineVar voltageVar = new EngineVar("Voltaje");
  voltageVar.setStatesLimits(150, 180, 200, 220, 240);

  engineVars = new EngineVar[]{vibrationVar, temperatureVar, voltageVar};

  engineLayout = new EngineLayout(20, 40, 200, 220);
  engineLayout.setInfoBlocksAmount(engineVars.length);
}

void draw() {
    if (simulating) updateSimulation();

    background(30);
    fill(255);
    text("Estado del motor", 20, 25);

    updateEngineVars();
    engineLayout.drawInfoBlocks(engineVars);

    fill(255);
    text("[ESPACIO] pausar/reanudar simulación", 20, 300);
}

// Copia los valores simulados/reales hacia los EngineVar y recalcula su estado
void updateEngineVars() {
    engineVars[0].setVarAndCalculateState(vibration);
    engineVars[1].setVarAndCalculateState(temperature);
    engineVars[2].setVarAndCalculateState(voltage);
}



// SIMULACIÓN: hace oscilar las 3 variables entre un mínimo y un máximo
// siguiendo una onda triangular (sube en línea recta, luego baja en línea recta).
void updateSimulation() {
    vibration = triangularSine(millis(), VIBRATION_PERIOD,   0, 10);
    temperature = triangularSine(millis(), TEMPERATURE_PERIOD, 20, 80);
    voltage = triangularSine(millis(), VOLTAGE_PERIOD,     110, 240);
}

// Devuelve un valor entre minVal y maxVal que sube y baja linealmente
// completando un ciclo cada periodoMs milisegundos.
float triangularSine(float timeMS, float periodMs, float minVal, float maxVal){
    float phase = (timeMS % periodMs) / periodMs; // 0.0 -> 1.0 dentro del ciclo
    float triangle = 1 - abs(phase * 2 - 1);          // 0->1 (sube) y 1->0 (baja)
    return map(triangle, 0, 1, minVal, maxVal);
}

// Recibe datos del Arduino REAL por USB
void serialEvent(Serial p) {
    String line = p.readStringUntil('\n');
    if (line != null) {
        String[] info = split(trim(line), ',');
        if (info.length == 3) {
            vibration = float(info[0]);
            temperature = float(info[1]);
            voltage = float(info[2]);
        }

    }
}

// Barra espaciadora: pausa la simulación (para congelar un valor y probar
// la GUI en un punto exacto) o la reanuda.
void keyPressed() {
    if (key == ' ') {
        simulating = !simulating;
    }
}
