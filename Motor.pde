import processing.serial.*;

Serial port;
float vibration, temperature, voltage;

boolean simulating = true; // barra espaciadora: pausa/reanuda la simulación

// Duración de un ciclo completo (subida + bajada) de cada variable, en ms.
// Cada variable tiene un período distinto para que no oscilen en sincronía.
final float VIBRATION_PERIOD = 10000; // 5 s subiendo + 5 s bajando
final float TEMPERATURE_PERIOD = 16000; // 8 s subiendo + 8 s bajando
final float VOLTAGE_PERIOD = 12000; // 6 s subiendo + 6 s bajando

final int PORT_ID = 0; //port de arduino
final int BAUD_RATE = 115200; // debe coincidir con Serial.begin(...) del .ino

// El Arduino (s3_V2.ino) no mide vibración/voltaje directamente: manda datos crudos
// (aceleración en g, temperatura IR, milivolts del sensor de voltaje) y acá se
// convierten a las unidades del panel. Calibrar contra un instrumento de referencia.
final float VIBRATION_SCALE = 50; // desviación de 1g -> mm/s (aproximado, falta calibrar)
final float VOLTAGE_SCALE   = 1;  // V leídos por el DFR0051 -> V reales del motor (depende del sensor)

EngineVar[] engineVars;
EngineLayout engineLayout;
EngineImage engineImage;

void setup() {
    size(880, 560);

    // Imprime ports disponibles en la consola
    showPorts();

    // Si el Arduino está conectado, descomentar la linea de abajo
    //setupArduino();
    setupEngineVars();
}

void showPorts(){
    println("--- INICIO PUERTOS ---");
    printArray(Serial.list());
    println("--- FIN PUERTOS ---");
}

void setupArduino(){
    String portName = Serial.list()[PORT_ID];
    port = new Serial(this, portName, BAUD_RATE);
}

void setupEngineVars() {
    // Define las 3 variables monitoreadas: sus límites de estado (Perfect, Good, Mid,
    // Bad, Terrible), el rango visual de su barra de nivel, su unidad y su ícono.

    //Temperatura
    EngineVar temperatureVar = new EngineVar("Temperatura");
    temperatureVar.setRange(20, 80);
    temperatureVar.setUnit("°C");
    temperatureVar.setIcon("temperature");

    temperatureVar.setStatesLimits(
        32, //perfect
        44, //good
        56, //mid
        68, //bad
        80  //terrible
    );

    //Vibración
    EngineVar vibrationVar = new EngineVar("Vibración");
    vibrationVar.setRange(0, 10);
    vibrationVar.setUnit("mm/s");
    vibrationVar.setIcon("vibration");

    vibrationVar.setStatesLimits(
        2, //perfect
        4, //good
        6, //mid
        8, //bad
        10 //terrible
    );
    
    //Voltage
    EngineVar voltageVar = new EngineVar("Voltaje");
    voltageVar.setRange(110, 240);
    voltageVar.setUnit("V");
    voltageVar.setIcon("voltage");

    voltageVar.setStatesLimits(
        150, //perfect
        180, //good
        200, //mid
        220, //bad
        240 //terrible
    );

    engineVars = new EngineVar[]{
        vibrationVar,
        temperatureVar,
        voltageVar
    };

    engineLayout = new EngineLayout(24, 130, 456, 520);
    engineLayout.setInfoBlocksAmount(engineVars.length);

    engineImage = new EngineImage(568, 130, 768, 510);
}

void draw() {
    if (simulating) updateSimulation();
    updateEngineVars(); //Actualizar datos

    
    drawBackground();
    drawHeader();

    engineLayout.drawSummary(engineVars, 24, 90, 432, 28);
    engineLayout.drawInfoBlocks(engineVars);
    engineImage.drawEngine(engineVars);

    drawFooter();
}

// Recibe datos crudos del Arduino (s3_V2.ino) por USB, en formato CSV:
// timestamp_ms,ax,ay,az,temp_ambiente,temp_objeto,adc_mv
void serialEvent(Serial p) {
    String line = p.readStringUntil('\n');
    if (line == null) return;

    String[] info = split(trim(line), ',');
    if (info.length != 7) return; // ignora el encabezado CSV u otras líneas inesperadas

    float ax, ay, az, tempObjeto, adcMv;
    try {
        ax         = Float.parseFloat(info[1]);
        ay         = Float.parseFloat(info[2]);
        az         = Float.parseFloat(info[3]);
        tempObjeto = Float.parseFloat(info[5]);
        adcMv      = Float.parseFloat(info[6]);
    } catch (NumberFormatException e) {
        return; // línea no numérica (p.ej. el encabezado)
    }

    float accelMagnitude = sqrt(ax * ax + ay * ay + az * az);
    vibration   = abs(accelMagnitude - 1.0) * VIBRATION_SCALE; // desviación de 1g en reposo
    temperature = tempObjeto; // temperatura del motor medida por el sensor IR (MLX90614)
    voltage     = (adcMv / 1000.0) * VOLTAGE_SCALE;
}


void keyPressed() {
    if (key == ' ') {
        simulating = !simulating;
    }
}



void updateEngineVars() {
    // Actualiza los valores de cada unidad de medida de la Clase y calcula en que estado (Aceptable, Critico, Etc.) se encuentra.

    engineVars[0].setVarAndCalculateState(vibration);
    engineVars[1].setVarAndCalculateState(temperature);
    engineVars[2].setVarAndCalculateState(voltage);
}

/**====================================
        INTERFAZ GRAFICA
====================================**/
void drawBackground() {
    color top = color(22, 24, 32);
    color bottom = color(32, 35, 46);
    for (int y = 0; y < height; y++) {
        stroke(lerpColor(top, bottom, y / (float) height));
        line(0, y, width, y);
    }
}

void drawHeader() {
    noStroke();
    textAlign(LEFT, TOP);

    fill(235);
    textSize(22);
    text("Monitor de Motor", 24, 24);

    fill(150, 155, 170);
    textSize(13);
    text("Panel de estado en tiempo real", 24, 52);
}

void drawFooter() {
    noStroke();
    fill(120, 124, 138);
    textAlign(LEFT, TOP);
    textSize(12);
    String estadoSim = simulating ? "activa" : "en pausa";
    text("Simulación " + estadoSim + " — [ESPACIO] pausar/reanudar", 24, height - 26);
}

/**====================================
            SIMULACION
====================================**/

void updateSimulation() {
    vibration = triangularSine(millis(), VIBRATION_PERIOD,   0, 10);
    temperature = triangularSine(millis(), TEMPERATURE_PERIOD, 20, 80);
    voltage = triangularSine(millis(), VOLTAGE_PERIOD,     110, 240);
}

float triangularSine(float timeMS, float periodMs, float minVal, float maxVal){
    //Oscila los valores
    float phase = (timeMS % periodMs) / periodMs; // 0.0 -> 1.0 dentro del ciclo
    float triangle = 1 - abs(phase * 2 - 1);          // 0->1 (sube) y 1->0 (baja)
    return map(triangle, 0, 1, minVal, maxVal);
}
