class EngineVar {

    private String name;
    private float var;

    //Determina en que limites pasa de estado: Perfect -> Good -> Mid -> Bad -> Terrible
    private float[] statesLimits;
    private int state;

    public EngineVar(String name){
        this.name = name;
    }

    //Once
    public void setStatesLimits(float perfect, float good, float mid, float bad, float terrible){
        this.statesLimits = new float[]{perfect, good, mid, bad, terrible};
    }

    //Once
    public void setName(String name){
        this.name = name;
    }

    //Repeated
    public void setVar(float var){
        this.var = var;
    }

    public void setVarAndCalculateState(float var){
        setVar(var);
        calculateState(var);
    }

    public void calculateState(float var){
        for (int i = 0; i < this.statesLimits.length; i++){
            if (var < this.statesLimits[i]){
                state = i;
                return;
            }
        }
        state = this.statesLimits.length; // por encima del último límite -> peor estado
    }

    public int getState(){
        return this.state;
    }

    public String getName(){
        return this.name;
    }

    public float getVar(){
        return this.var;
    }

    public float[] getStatesLimits(){
        return this.statesLimits;
    }


}
