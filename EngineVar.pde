class EngineVar {

    // Textos de estado, en el mismo orden que statesLimits: Perfect -> Good -> Mid -> Bad -> Terrible
    private final String[] stateLabels = {"ÓPTIMO", "BUENO", "REGULAR", "ALERTA", "CRÍTICO"};

    private String name;
    private String unit;
    private String icon; // "vibration", "temperature" o "voltage" (ver EngineLayout.drawIcon)
    private float var;
    private float minRange, maxRange; // rango visual usado por la barra de nivel

    //Determina en que limites pasa de estado: Perfect -> Good -> Mid -> Bad -> Terrible
    private float[] statesLimits;
    private int state;

    EngineVar(String name){
        this.name = name;
    }

    //Once
    void setStatesLimits(float perfect, float good, float mid, float bad, float terrible){
        this.statesLimits = new float[]{perfect, good, mid, bad, terrible};
    }

    //Once
    void setRange(float minRange, float maxRange){
        this.minRange = minRange;
        this.maxRange = maxRange;
    }

    //Once
    void setUnit(String unit){
        this.unit = unit;
    }

    //Once
    void setIcon(String icon){
        this.icon = icon;
    }

    //Once
    void setName(String name){
        this.name = name;
    }

    //Repeated
    void setVar(float var){
        this.var = var;
    }

    void setVarAndCalculateState(float var){
        setVar(var);
        calculateState(var);
    }

    void calculateState(float var){
        for (int i = 0; i < statesLimits.length; i++){
            if (var < statesLimits[i]){
                state = i;
                return;
            }
        }
        state = statesLimits.length - 1; // por encima del último límite -> mismo estado "crítico"
    }

    int getState(){
        return this.state;
    }

    String getStateLabel(){
        return getStateLabelFor(this.state);
    }

    String getStateLabelFor(int s){
        return stateLabels[s];
    }

    String getName(){
        return this.name;
    }

    String getUnit(){
        return this.unit;
    }

    String getIcon(){
        return this.icon;
    }

    float getVar(){
        return this.var;
    }

    float getMinRange(){
        return this.minRange;
    }

    float getMaxRange(){
        return this.maxRange;
    }

    float[] getStatesLimits(){
        return this.statesLimits;
    }
}
