// Ilustración simple de un motor DC en posición vertical: eje arriba, carcasa
// cilíndrica al centro, brida de montaje abajo y dos cables de alimentación (+/-).
class EngineImage {
    private int x1, y1, x2, y2;

    // Proporciones de cada pieza como fracción del alto total (0.0 -> 1.0),
    // de arriba (eje) hacia abajo (cables). Se solapan un poco a propósito
    // para que las uniones entre piezas no dejen huecos.
    private final float SHAFT_TOP    = 0.00;
    private final float SHAFT_BOTTOM = 0.16;
    private final float BODY_TOP     = 0.14;
    private final float BODY_BOTTOM  = 0.74;
    private final float FLANGE_TOP   = 0.72;
    private final float FLANGE_BOTTOM = 0.86;

    // Paleta: carcasa metálica, brida oscura, eje claro y cables +/-
    private final color BODY_COLOR     = color(110, 115, 128);
    private final color BODY_HIGHLIGHT = color(140, 145, 158);
    private final color HOT_COLOR      = color(250, 70, 56); // tiñe la carcasa cuando sube la temperatura
    private final color FLANGE_COLOR   = color(64, 68, 80);
    private final color BOLT_COLOR     = color(40, 43, 52);
    private final color SHAFT_COLOR    = color(205, 208, 216);
    private final color WIRE_POS_COLOR = color(220, 66, 66);
    private final color WIRE_NEG_COLOR = color(24, 24, 28);
    private final color SPARK_COLOR    = color(255, 232, 130); // Chispazo cuando el voltaje es muy alto

    // Amplitud máxima (px) del temblor cuando la vibración está al tope de su rango.
    private final float MAX_SHAKE = 5;

    EngineImage(int x1, int y1, int x2, int y2){
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
    }

    // Dibuja el motor completo, aplicando efectos según el estado de cada variable:
    // vibración -> tiembla, temperatura -> tiñe la carcasa, voltaje -> los cables brillan.
    void drawEngine(EngineVar[] vars){
        float vibrationT = vars[0].getIntensity();
        float temperatureT = vars[1].getIntensity();
        float voltageT = vars[2].getIntensity();

        float w = x2 - x1;
        float h = y2 - y1;
        float cx = x1 + w / 2;

        pushMatrix();
        applyShake(vibrationT);

        drawWires(w, h, cx, voltageT);
        drawShaft(w, h, cx); //Asta
        drawBody(w, h, cx, temperatureT);
        drawFlange(w, h, cx);

        popMatrix();
    }

    // Desplaza el resto del dibujo en una posición aleatoria pequeña, cada vez mayor
    // mientras más alta esté la vibración.
    void applyShake(float vibrationT){
        float amp = vibrationT * MAX_SHAKE;
        translate(random(-amp, amp), random(-amp, amp));
    }

    // Dos cables saliendo de la brida, con un punto de conexión en la punta que
    // brilla y pulsa cuando el voltaje se acerca al máximo de su rango.
    void drawWires(float w, float h, float cx, float voltageT){
        float startY = y1 + h * FLANGE_BOTTOM;
        float offsetX = w * 0.12;

        drawWire(cx - offsetX, startY, cx - offsetX * 1.6, y2, WIRE_POS_COLOR, voltageT);
        drawWire(cx + offsetX, startY, cx + offsetX * 1.6, y2, WIRE_NEG_COLOR, voltageT);
    }

    void drawWire(float startX, float startY, float endX, float endY, color c, float voltageT){
        color liveColor = lerpColor(c, SPARK_COLOR, voltageT);

        stroke(liveColor);
        strokeWeight(3 + voltageT * 3);
        line(startX, startY, endX, endY);

        float pulse = 0.5 + 0.5 * sin(millis() * 0.02);

        noStroke();
        fill(red(liveColor), green(liveColor), blue(liveColor), 200 * voltageT * pulse);
        ellipse(endX, endY, 10 + 20 * voltageT * pulse, 10 + 20 * voltageT * pulse);

        fill(liveColor);
        ellipse(endX, endY, 8, 8);

        // A partir de voltaje "alerta" en adelante, chispazos intermitentes en la punta.
        if (voltageT > 0.55 && random(1) < voltageT * 0.5) {
            drawSpark(endX, endY, voltageT);
        }
    }

    // Chispazo tipo rayo: una línea quebrada corta que aparece y desaparece
    // en cada frame, más frecuente y más larga cuanto más alto es el voltaje.
    void drawSpark(float x, float y, float voltageT){
        float len = 10 + voltageT * 16;
        float angle = random(TWO_PI);

        noFill();
        stroke(SPARK_COLOR);
        strokeWeight(1.5);
        beginShape();
        float sx = x, sy = y;
        vertex(sx, sy);
        for (int i = 0; i < 3; i++) {
            sx += cos(angle) * (len / 3) + random(-4, 4);
            sy += sin(angle) * (len / 3) + random(-4, 4);
            vertex(sx, sy);
        }
        endShape();
        noStroke();
    }

    // Brida de montaje: placa inferior con un perno a cada lado.
    void drawFlange(float w, float h, float cx){
        float flangeW = w * 0.7;
        float flangeY = y1 + h * FLANGE_TOP;
        float flangeH = h * (FLANGE_BOTTOM - FLANGE_TOP);

        noStroke();
        fill(FLANGE_COLOR);
        rect(cx - flangeW / 2, flangeY, flangeW, flangeH, 4, 4, 10, 10);

        float boltY = flangeY + flangeH / 2;
        drawBolt(cx - flangeW / 2 + 10, boltY);
        drawBolt(cx + flangeW / 2 - 10, boltY);
    }

    void drawBolt(float bx, float by){
        noStroke();
        fill(BOLT_COLOR);
        ellipse(bx, by, 8, 8);
    }

    // Carcasa cilíndrica: relleno plano más una franja clara que sugiere volumen.
    // Se tiñe de rojo progresivamente a medida que sube la temperatura.
    void drawBody(float w, float h, float cx, float temperatureT){
        float bodyW = w * 0.55;
        float bodyY = y1 + h * BODY_TOP;
        float bodyH = h * (BODY_BOTTOM - BODY_TOP);

        noStroke();
        fill(lerpColor(BODY_COLOR, HOT_COLOR, temperatureT));
        rect(cx - bodyW / 2, bodyY, bodyW, bodyH, 6);

        fill(lerpColor(BODY_HIGHLIGHT, HOT_COLOR, temperatureT));
        rect(cx - bodyW * 0.28, bodyY + bodyH * 0.08, bodyW * 0.16, bodyH * 0.84, 4);
    }

    // Eje saliente en la parte superior, con la punta redondeada.
    void drawShaft(float w, float h, float cx){
        float shaftW = w * 0.10;
        float shaftBottom = y1 + h * SHAFT_BOTTOM;
        float shaftH = shaftBottom - y1;

        noStroke();
        fill(SHAFT_COLOR);
        rect(cx - shaftW / 2, y1, shaftW, shaftH, 3, 3, 0, 0);
        ellipse(cx, y1, shaftW, shaftW);
    }
}
