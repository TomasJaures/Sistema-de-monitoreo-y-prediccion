class EngineLayout {

    // IB = InfoBlock: la tarjeta que muestra el estado de una variable
    private int x1, y1, x2, y2;
    private int amountIB;

    private int widthIB;
    private int heightIB;

    private final int CARD_MARGIN = 12;
    private final int CORNER_RADIUS = 14;

    EngineLayout(int x1, int y1, int x2, int y2){
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
    }

    void setInfoBlocksAmount(int amount){
        this.amountIB = amount;
        this.widthIB = this.x2 - this.x1;
        this.heightIB = (this.y2 - this.y1) / amount;
    }

    // Banner con el peor estado entre todas las variables (para ver de un vistazo
    // si hay que prestar atención sin tener que leer cada tarjeta).
    void drawSummary(EngineVar[] vars, float bx, float by, float bw, float bh){
        int worst = 0;
        for (int i = 0; i < vars.length; i++) {
            worst = max(worst, vars[i].getState());
        }

        color c = stateColor(worst);
        boolean critical = worst == 4;
        float pulse = critical ? (0.5 + 0.5 * sin(millis() * 0.006)) : 1;

        noStroke();
        fill(red(c), green(c), blue(c), 35);
        rect(bx, by, bw, bh, bh / 2);

        fill(red(c), green(c), blue(c), 255 * pulse);
        ellipse(bx + 18, by + bh / 2, 12, 12);

        fill(225);
        textAlign(LEFT, CENTER);
        textSize(13);
        text("Estado general: " + vars[0].getStateLabelFor(worst), bx + 36, by + bh / 2 + 1);
        textAlign(LEFT, TOP);
    }

    // Dibuja una tarjeta por cada EngineVar con el estado ya calculado.
    // No recalcula nada: quien actualiza los valores debe llamar antes
    // a var.setVarAndCalculateState(nuevoValor).
    void drawInfoBlocks(EngineVar[] vars){
        for (int i = 0; i < vars.length; i++) {
            int cellY = y1 + heightIB * i;
            drawCard(vars[i], x1, cellY, widthIB, heightIB);
        }
    }

    void drawCard(EngineVar v, int cellX, int cellY, int cellW, int cellH){
        float cardX = cellX + CARD_MARGIN;
        float cardY = cellY + CARD_MARGIN;
        float cardW = cellW - CARD_MARGIN * 2;
        float cardH = cellH - CARD_MARGIN * 2;

        color c = stateColor(v.getState());
        boolean critical = v.getState() == 4;
        float pulse = critical ? (0.5 + 0.5 * sin(millis() * 0.006)) : 1;

        noStroke();

        // sombra
        fill(0, 50);
        rect(cardX + 3, cardY + 5, cardW, cardH, CORNER_RADIUS);

        // fondo de la tarjeta
        fill(42, 46, 58);
        rect(cardX, cardY, cardW, cardH, CORNER_RADIUS);

        // barra de acento a la izquierda (parpadea si el estado es crítico)
        fill(red(c), green(c), blue(c), 255 * pulse);
        rect(cardX, cardY, 8, cardH, 4, 0, 0, 4);

        // ícono de la variable
        drawIcon(v.getIcon(), cardX + 38, cardY + 36, c);

        // nombre
        fill(190, 195, 210);
        textAlign(LEFT, TOP);
        textSize(14);
        text(v.getName(), cardX + 66, cardY + 14);

        // valor + unidad
        fill(245);
        textSize(26);
        String unitLabel = v.getUnit() == null ? "" : " " + v.getUnit();
        text(nf(v.getVar(), 1, 1) + unitLabel, cardX + 66, cardY + 32);

        // insignia de estado
        drawBadge(v.getStateLabel(), c, cardX + cardW - 104, cardY + 14, 84, 22);

        // barra de nivel dentro del rango visual de la variable
        drawGauge(v, cardX + 20, cardY + cardH - 22, cardW - 40, 8, c);
    }

    void drawBadge(String label, color c, float bx, float by, float bw, float bh){
        noStroke();
        fill(red(c), green(c), blue(c), 45);
        rect(bx, by, bw, bh, bh / 2);

        fill(c);
        textAlign(CENTER, CENTER);
        textSize(11);
        text(label, bx + bw / 2, by + bh / 2 + 1);
        textAlign(LEFT, TOP);
    }

    void drawGauge(EngineVar v, float gx, float gy, float gw, float gh, color c){
        float t = constrain(map(v.getVar(), v.getMinRange(), v.getMaxRange(), 0, 1), 0, 1);

        noStroke();
        fill(60, 64, 76);
        rect(gx, gy, gw, gh, gh / 2);

        fill(c);
        rect(gx, gy, gw * t, gh, gh / 2);

        fill(245);
        ellipse(gx + gw * t, gy + gh / 2, gh + 5, gh + 5);
    }

    // Dibuja un ícono simple (sin imágenes externas) según el tipo de variable
    void drawIcon(String icon, float cx, float cy, color c){
        noFill();
        stroke(c);
        strokeWeight(2.5);

        if ("vibration".equals(icon)) {
            // onda tipo osciloscopio
            beginShape();
            for (int i = -14; i <= 14; i += 2) {
                float yOff = sin(i * 0.5) * 8;
                vertex(cx + i, cy + yOff);
            }
            endShape();
        } else if ("temperature".equals(icon)) {
            // termómetro
            noStroke();
            fill(c);
            rect(cx - 3, cy - 14, 6, 20, 3);
            ellipse(cx, cy + 10, 14, 14);
        } else if ("voltage".equals(icon)) {
            // rayo
            noStroke();
            fill(c);
            beginShape();
            vertex(cx + 2, cy - 14);
            vertex(cx - 8, cy + 2);
            vertex(cx - 1, cy + 2);
            vertex(cx - 4, cy + 14);
            vertex(cx + 9, cy - 4);
            vertex(cx + 1, cy - 4);
            endShape(CLOSE);
        } else {
            noStroke();
            fill(c);
            ellipse(cx, cy, 16, 16);
        }

        noStroke();
    }

    // Paleta: Verde Esmeralda / Verde Lima / Ámbar / Naranja Alerta / Rojo Crítico
    color stateColor(int state){
        if (state == 0) return color(46, 204, 113);  // Verde Esmeralda - Óptimo
        if (state == 1) return color(162, 217, 89);  // Verde Lima - Bueno
        if (state == 2) return color(241, 196, 15);  // Amarillo / Ámbar - Regular
        if (state == 3) return color(230, 126, 34);  // Naranja Alerta - Alerta
        return color(231, 76, 60);                   // Rojo Crítico
    }
}
