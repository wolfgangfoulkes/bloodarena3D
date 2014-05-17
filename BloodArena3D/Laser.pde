class Laser 
{
  Tube laser;
  PVector pos;
  PVector aim;
  float lifespan;
  float rate;
  float thresh;
  int elapsed;

  Laser(float rTopX, float rTopZ, float rBotX, float rBotZ, PVector ipos)
  {
    pos = ipos;
    aim = PVector.add(ipos, new PVector(0, 0, -1)); //radius must be >=0.
    lifespan = 0;
    rate = 0;
    elapsed = 0;
    laser = new Tube(APPLET, 10, 30);
    laser.visible(false);
    laser.setSize(rTopX, rTopZ, rBotX, rBotZ);
    laser.setWorldPos(pos, aim);
  }

  void set(PVector ipos, PVector iaim, float irate, float ithresh)
  {
    pos = ipos;
    aim = iaim;
    laser.visible(false);
    laser.setWorldPos(pos, aim);
    lifespan = 1;
    rate = irate;
    thresh = ithresh;
    elapsed = 0;
  }

  void update()
  {
    elapsed++;
    if (lifespan >= thresh)
    {
      lifespan *= rate;
      //println(lifespan);
    }
    else
    {
      lifespan = 0;
      rate = 0;
    }
  }

  void display() //the actual visual here is kinda whatever.
  {
    PVector lpos = PVector.lerp(aim, pos, 1 - lifespan); //PVector.lerp(aim, pos, pow(1 - lifespan, 2)) //a more traditional effect.
    laser.setWorldPos(pos, lpos); //end -> end
    laser.drawMode(S3D.TEXTURE);
    laser.setTexture(laserTexCur);
    if (lifespan > 0)
    {
      pushStyle();
      laser.visible(true);
      SHADER_LASER.set("time", (millis()) * .001 * 8); //elapsed could be set to the initial elapsed value, then mod by that number to get count from 0
      SHADER_LASER.set("resolution", (float) width, (float) height);
      SHADER_LASER.set("alpha", 1.0);

      SHADER_LASER.set("bars1", lerp(300.0, 1.0, 1 - lifespan));
      SHADER_LASER.set("bars2", 300.0);

      SHADER_LASER.set("thresh1", 0.9);
      SHADER_LASER.set("thresh2", 0.9 * lifespan * lifespan);

      SHADER_LASER.set("rate1", 30.0);
      SHADER_LASER.set("rate2", 30.0);
      SHADER_LASER.set("color", shiftGlobalColors());
      shader(SHADER_LASER);
      laser.draw();
      resetShader();
    }
    else 
    {
      laser.visible(false);
      laser.draw();
    }
  }
}

