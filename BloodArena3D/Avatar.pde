class Avatar extends O3DCone
{
  String prefix;
  Laser laser;
  //could have a "shader" parameter that is set along with death and melee. then, we don't have to call so much if/then in display
  //PShader shader;
  float lifespan;
  float melee;

  
  float D_THRESH = .0001;
  float D_RATE = .90;
  float M_THRESH = .001;
  float M_RATE = .98;
  float L_THRESH = .008;
  float L_RATE = .8;
  
  Avatar(PVector ip, PVector ir, PVector isize, String ipre, int status)
  {
    super(ip, ir, isize);
    type = "avatar";
    prefix = ipre;
    laser = new Laser(0.6, 0.6, 0.6, 0.6, new PVector(p.x, p.y-isize.y, p.z)); //set it to apex, later.
    //println("new Avatar!", p, r, prefix);
    isLiving = status;
    
    lifespan = 0.0;
    melee = 0.0;
  }
  
  void update()
  { 
    if (isLiving == 1)
    {
      if (melee > M_THRESH)
      {
        melee *= M_RATE;
        println("melee!");
      }
      else 
      {
        melee = 0.0;
      }
    }
    else if (isLiving == 0)
    {
      if (lifespan > D_THRESH) 
      { 
        lifespan *= D_RATE;
      }
      else
      {
        lifespan = 0.0;
        isLiving = -1;
      }
    }
  }

  void display()
  {
    if (isLiving == 1) //rather than these checks, could implement a dig where the shader is set externally, and handle most stuff in-shader with millis()
    {

      super.display();
      resetShader();
      SHADER_LASER.set("time", (millis()) * .001 * 8); //elapsed could be set to the initial elapsed value, then mod by that number to get count from 0
      SHADER_LASER.set("resolution", (float) width, (float) height);
      SHADER_LASER.set("alpha", lerp(.7, .4, lifespan - 1));
      
      SHADER_LASER.set("bars1", lerp(300.0, 1.0, (1.0 - laser.lifespan)));
      SHADER_LASER.set("bars2", 300.0);
      
      SHADER_LASER.set("thresh1", 0.9);
      SHADER_LASER.set("thresh2", 0.9 * lifespan * lifespan);
      
      SHADER_LASER.set("rate1", 30.0);
      SHADER_LASER.set("rate2", 30.0);
      SHADER_LASER.set("color", shiftGlobalColors());
      shader(SHADER_LASER);
      laser.update(); //right now, this's all that'd be in "update" for any object excepting the camera.
      laser.display();
      resetShader();
    }
    else if (isLiving == 0)
    {
      
      SHADER_DEATH.set("time", millis() * .001);
      SHADER_DEATH.set("resolution", (float) width, (float) height);
      SHADER_DEATH.set("floor", lerp(.8, 1.4, 1 - lifespan)); 
      SHADER_DEATH.set("alpha", .8);
    
      SHADER_DEATH.set("mouse", (float) width/2, (float) (-acc.y * height/2) + height/2);
    
      //SHADER_DEATH.set("circle_radius", lerp(.08, 8.0, 1 - lifespan)); //relative to center of screen.
      //SHADER_DEATH.set("border", 8.0); //1.0 for filled circle
      //SHADER_DEATH.set("periods", 1000.0); //high or 1-2
      //SHADER_DEATH.set("rate", 60.0);
      
      SHADER_DEATH.set("mix", lerp(0, .6, (1 - lifespan)));
      SHADER_DEATH.set("cover", .6); //amount of clouds v/ black 
      SHADER_DEATH.set("sharpness", 0.0003); //at zero this is just white and black
      
      SHADER_DEATH.set("color", shiftGlobalColors()); //new PVector(random(1.0), 0.0, random(1.0)));

      shader(SHADER_DEATH);
      super.display();
      resetShader();
    }
  }
  
  void startLaser(PVector ipos, PVector iaim)
  {
    laser.set(ipos, iaim, .88, .08);//laser.adjustToTerrain?
  }
  
  void startLaser(PVector iaim)
  {
    laser.set(new PVector(p.x, p.y-size.y, p.z), iaim, L_RATE, L_THRESH); //laser.adjustToTerrain?
  }
  
  void melee()
  {
    melee = 1.0;
  }
  
  int kill()
  {
    if (isLiving == 1)
    {
      isLiving = 0;
      lifespan = 1.0;
      return 0;
    }
    return -1;
  }
  
  void print()
  {
    println("Avatar for player "+prefix+"", "position:", p, "rotation", r);
  }
}
