class EngineLayout {

    //IB = InfoBlock, bloque que muestra la información de una variable
    private int x1, y1, x2, y2;
    private int amountIB;

    private int widthIB;
    private int heightIB;

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

    // Dibuja un bloque por cada EngineVar con el estado ya calculado.
    // No recalcula nada: quien actualiza los valores debe llamar antes
    // a var.setVarAndCalculateState(nuevoValor).
    void drawInfoBlocks(EngineVar[] vars){
        for (int i = 0; i < vars.length; i++) {
            int blockY = y1 + heightIB * i;

            colorByState(vars[i].getState());
            rect(x1, blockY, widthIB, heightIB, 8);

            fill(textColorByState(vars[i].getState()));
            text(vars[i].getName() + ": " + nf(vars[i].getVar(), 1, 2), x1 + 8, blockY + heightIB / 2);
        }
    }

    void colorByState(int state){
        if (state == 0){
            fill(204, 229, 255); //Perfect
        } else if (state == 1){
            fill(153, 255, 204); //Good
        } else if (state == 2){
            fill(255, 153, 51); //Mid
        } else if (state == 3){
            fill(255, 51, 51); // Bad
        } else {
            fill(153, 0, 0); //Terrible
        }
    }

    // Texto oscuro sobre fondos claros (Perfect/Good), texto claro sobre fondos oscuros
    color textColorByState(int state){
        if (state == 0 || state == 1){
            return color(20);
        }
        return color(255);
    }
}
