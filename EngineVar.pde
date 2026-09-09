class EngineVar {

    // Textos de estado, en el mismo orden que statesLimits: Perfect -> Good -> Mid -> Bad -> Terrible
    private final String[] stateLabels = {
        "ÓPTIMO",
        "BUENO",
        "REGULAR",
        "ALERTA",
        "CRÍTICO"
    };

    private String name;
    private String unit;
    private String icon; 
    private float var;
    private float minRange, maxRange; // rango visual usado por la barra de nivel

    //Determina en que limites pasa de estado: Perfect -> Good -> Mid -> Bad -> Terrible
    private float[] statesLimits;
    private int state;

    EngineVar(String name){
        this.name = name;
    }

    void setStatesLimits(float perfect, float good, float mid, float bad, float terrible){
        //Determina en que rangos la unidad de medida se encuentra en estado: Perfecto, bueno, etc.
        this.statesLimits = new float[]{
            perfect,
            good,
            mid,
            bad,
            terrible
        };
    }

    void setRange(float minRange, float maxRange){

        //Si supera uno de los limites no pasara nada visualmente.

        this.minRange = minRange;
        this.maxRange = maxRange;
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
        state = statesLimits.length - 1; // Si llega acá es estado critico
    }
    
    float getIntensity(){

        //Metodo util para dibujar `EngineImage.pde`, sirve para que los cambios NO sean lineales, en cambio, se basan en los rangos dictados por `setStatesLimits();`

        int lastState = statesLimits.length - 1;
        float lower = (state == 0) ? minRange : statesLimits[state - 1];
        float upper = (state == lastState) ? maxRange : statesLimits[state];
        if (upper <= lower) return constrain((float) state / lastState, 0, 1);

        float within = constrain(map(var, lower, upper, 0, 1), 0, 1);
        return constrain((state + within) / lastState, 0, 1);
    }

    /**=================================
            GETTERS Y SETTERS
    ===================================**/

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

    void setUnit(String unit){
        this.unit = unit;
    }

    void setVar(float var){
        this.var = var;
    }

    void setIcon(String icon){
        this.icon = icon;
    }

    void setName(String name){
        this.name = name;
    }
}
