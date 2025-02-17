import oscP5.*;
import netP5.*;
import papaya.*;
import java.util.*; 
import java.util.concurrent.*;

import processing.video.*;
//import processing.opengl.*;
import shapes3d.*;
import shapes3d.utils.*;
import shapes3d.animation.*;

int ADEBUG = 0;
PVector TEMP_SPAWN = new PVector(0, 0, 0);
boolean IS_INIT = false;
boolean IS_CONNECTED = false;

///////////****OSC****\\\\\\\\\\\\\
OscP5 pos_in;
OscP5 oscP5;
int lport = 12000;
int coutport = 14000;
int cinport = 14001;
int bcport = 32000;
String BROADCAST_LOCATION = "169.254.144.125";
NetAddress myLocation;
NetAddress myBroadcastLocation; 
String MY_PREFIX = "/tw33z";

PApplet APPLET = this;
Map map;
Camera cam;
Terrain terrain;

//-----CONSTANTS for Terrain
int X_SIZE = 1001;
int Z_SIZE = 1001;
int TERRAIN_SLICES = 16;
float TERRAIN_HORIZON = 300;
float TERRAIN_AMP = 70; 

//-----CONSTANTS for Objects
int height_OFFSET = 50;

//-----CONSTANTS for Players
float STRIKE_RADIUS = 50;
float DISTANCE_FROM_PLAYER = 500;
float SHOTS = 0;

//-----COLOR CONSTANTS
PVector COLOR = new PVector(1.0, 0, .8);
float COLOR_RATE = .01;


//*******Texture Arrays*******\\ 

String[] respawnTex = new String[] {
  "newKS1.png", "newKS1.png", "newKS1.png"
};
String[] laserTex = new String[] {
  "laser1.jpg", "laser2.jpg", "laser3.JPG", "laser4.jpg", "laser1.jpg", "laser2.jpg"
};
//texture order is fire/ice/glass/space/abstract repeating
String[] terrainTex = new String[] {//textures for terrain
  "lava1.jpg", "elec1.jpg", "laser3.JPG", "sky14.jpg"
};

String[] skyTex = new String[] {//could load fog as background
  "laser3.JPG", "axe5.jpg", "wires1.jpg", "snow1.jpg", "fire1.jpg", "metal2.jpg"
};

PImage laserTexCur;
PImage terrainTexCur;
PImage killScreen;

PShader SHADER_NOISE;
PShader SHADER_LASER;
PShader SHADER_CROSSHAIR;
PShader SHADER_DEATH;
PShader SHADER_MELEE;

PVector acc = new PVector(0, 0, 0); //can we set Camera directly from OSC?
PVector joystick = new PVector(0, 0, 0);

/*
boolean sketchFullScreen()
 {
 return true;
 }
 */

void setup() 
{
  smooth();
  size(900, 900, P3D);
  //size(displayWidth, displayHeight, P3D);
  frameRate(24);

  pos_in = new OscP5(this, cinport);
  pos_in.plug(this, "accelData", "/nunchuck/accel");
  pos_in.plug(this, "joystickData", "/nunchuck/joystick");
  pos_in.plug(this, "chuckRespawn", "/chuck/init");
  pos_in.plug(this, "cButtonPing", "/nunchuck/Cbutton");
  pos_in.plug(this, "zButtonPing", "/nunchuck/Zbutton");

  oscP5 = new OscP5(this, lport);
  //oscP5.plug(this, "hostAdd", "/host/add");
  //oscP5.plug(this, "hostRemove", "/host/remove");
  //oscP5.plug(this, "hostObject", "/host/object");

  myLocation = new NetAddress("127.0.0.1", coutport);
  myBroadcastLocation = new NetAddress(BROADCAST_LOCATION, bcport);

  map = new Map(1001, 1001);
  cam = new Camera(this);

  terrain = new Terrain(APPLET, TERRAIN_SLICES, X_SIZE, TERRAIN_HORIZON);
  terrain.usePerlinNoiseMap(-TERRAIN_AMP, TERRAIN_AMP, 2.125f, 2.125f);
  terrain.cam = cam.cam;

  initTextures(); //here only, for now.

  SHADER_NOISE = loadShader("noisenormalizedfrag.glsl");
  SHADER_LASER = loadShader("sinelines2frag.glsl"); //needs color
  SHADER_CROSSHAIR = loadShader("circlefrag.glsl"); //needs color
  SHADER_DEATH = loadShader("opttexnormfrag.glsl"); //needs color
  SHADER_MELEE = loadShader("pixelfrag.glsl");

  println("width:", width);
  println("displayWidth:", displayWidth);
  IS_INIT = true;
  println("setup successful");
}

void draw() 
{

  if ( (cam.living == false) || (IS_CONNECTED == false) )
  {
    background(0);

    killCamera(); //should have this display death for a certain number of seconds, I guess, and return to trigger the next thing.
    noLoop();
  }
  else
  {
    background(0);
    lights(); //unneccessary, this just calls the default.

    SHADER_NOISE.set("time", (millis() * .001));
    SHADER_NOISE.set("resolution", (float) width * random(1, 1), (float) height * random(1, 1)); //these values reproduce the site's effect
    SHADER_NOISE.set("alpha", .8); 
    SHADER_NOISE.set("floor", .8);
    SHADER_NOISE.set("ceil", 1.0);
    shader(SHADER_NOISE);
    terrain.draw();
    map.update();
    map.display();

    resetShader();

    cam.display();
    cam.look(acc.x, acc.y);
    cam.move(joystick);
    PVector next = adjustY(PVector.add(cam.pos, cam.move), terrain, 0);
    if (map.checkBounds(next) == -1)
    { 
      cam.update();
      cam.adjustToTerrain(terrain, -30); //should be fine, because it only alters the eye, which is overwritten by pos. gottabe after update for that reason. if you wanted to update pos, or an object, use Terrain.adjustPosition.
      //println(cam.pos);
      sendPos(cam.pos.x, 0, cam.pos.z, 0, cam.rot.y, 0);
    }
    else
    {
      println("boundary!", cam.pos);
      cam.move(new PVector(0, 0, 0));
    }
  }
}

//-----OSC SEND FUNCTIONS
void connect(int ilport, String ipre) //should do all this crap automatically before players "spawn" because we ought to have bugs in this worked out before players are allowed to see anything
{
  OscMessage m = new OscMessage("/server/connect");
  m.add(ilport); 
  m.add(ipre);
  oscP5.send(m, myBroadcastLocation);
}

void disconnect(int ilport, String ipre)
{
  map.clear();
  OscMessage m = new OscMessage("/server/disconnect");
  m.add(ilport); 
  m.add(ipre);
  oscP5.send(m, myBroadcastLocation);
}


void sendPos(float ix, float iy, float iz, float irx, float iry, float irz) //+ rotation
{
  OscMessage ocoor = new OscMessage(MY_PREFIX + "/pos");
  ocoor.add(ix);
  ocoor.add(iy);
  ocoor.add(iz);
  ocoor.add(irx);
  ocoor.add(iry);
  ocoor.add(irz);
  oscP5.send(ocoor, myBroadcastLocation);
}

void sendShot(PVector ipos, PVector iaim, NetAddress ilocation)
{
  OscMessage ocoor = new OscMessage(MY_PREFIX + "/shot");
  ocoor.add(ipos.x);
  ocoor.add(ipos.y);
  ocoor.add(ipos.z);
  ocoor.add(iaim.x);
  ocoor.add(iaim.y);
  ocoor.add(iaim.z);
  oscP5.send(ocoor, ilocation);
}

void sendBlankPing(NetAddress ilocation)
{
  OscMessage oping = new OscMessage(MY_PREFIX + "/blank");
  oping.add(1);
  oscP5.send(oping, ilocation);
}

void sendKill(String iaddr, NetAddress ilocation)
{
  OscMessage oaddr = new OscMessage(MY_PREFIX + "/kill");
  oaddr.add(iaddr);
  oscP5.send(oaddr, ilocation);
}

void sendMelee(int istatus, NetAddress ilocation)
{
  OscMessage oint = new OscMessage(MY_PREFIX + "/melee");
  oint.add(istatus);
  oscP5.send(oint, ilocation);
}

void sendDist(float idist)
{
  OscMessage odist = new OscMessage(MY_PREFIX + "/distance");
  odist.add(idist);
  oscP5.send(odist, myLocation);
}

void newPlayer() 
{
  OscMessage newP = new OscMessage("/arena/newPlayer");
  newP.add(1);
  oscP5.send(newP, myLocation);
}

void sendExplosion() 
{ //maybe redundant, only happens on kill and death
  OscMessage sendExplosion = new OscMessage(MY_PREFIX + "/explosion");
  sendExplosion.add(1);
  oscP5.send(sendExplosion, myLocation);
  println("explosion Trigger sent to Chuck");
}

//-----OSC FROM CHUCK
public void cButtonPing(int ping) 
{
  if (IS_INIT == false) 
  { 
    return;
  }
  shoot();
}

public void zButtonPing(int ping) 
{
  if (IS_INIT == false) 
  { 
    return;
  }
  melee();
}

public void joystickData(int x, int z) 
{
  if (IS_INIT == false) { 
    return;
  }
  if (joystick != null)
  {
    if ((z > 110) && (z <= 135)) { 
      joystick.x = 0;
    }
    else { 
      joystick.x = map(constrain(z, 0, 256), 0, 256, -1, 1);
    }
    if ((x > 110) && (x <= 135)) { 
      joystick.z = 0;
    } 
    else { 
      joystick.z = map(constrain(x, -32, 220), -32, 220, -1, 1);
    }

    joystick.x *= 2.5;
    joystick.z *= 2.5;
  }
}

public void accelData(int x, int y, int z) 
{ 
  if (IS_INIT == false) { 
    return;
  }
  if (acc != null)
  {
    //println("Receiving accel Data");
    if ((x > -30) && (x <= 30)) { 
      acc.x = 0;
    } 
    else { 
      acc.x = map(constrain(x, -70, 70), -70, 70, -1, 1);
    }

    acc.y = map(constrain(y, 30, 120), 30, 120, -1, 1);
    acc.z = acc.y;

    acc.x *= -1.5;
    acc.y *= -1.0; //this is a "set" not an "increment.
  }
}


//-----OSC RECIEVE

/*void hostAdd(String iprefix)
{
  IS_CONNECTED = true;
  int mapindx = map.indexFromPrefix(iprefix);
  if ( (iprefix.equals(MY_PREFIX)) || (mapindx != -1) ) 
  { 
    println("recieved duplicate object! prefix = "+iprefix+""); 
    map.print();
    return;
  }
  PVector isize = new PVector(random(20, 90), random(110, 180), random(20, 90)); //set size here, just once.
  Avatar iavatar = new Avatar(new PVector(0, 0, 0), new PVector(0, 0, 0), isize, iprefix, -1);
  if (map.add(iavatar)) { println("new Avatar added to map! prefix = "+iprefix+""); map.print(); }
  else { println("failed to add object to map! prefix = "+iprefix+""); map.print(); }
}
*/

void oscEvent(OscMessage theOscMessage) 
{
  //println("###1 received an osc message with addrpattern "+theOscMessage.addrPattern()+" and typetag "+theOscMessage.typetag());
  //theOscMessage.print();
  if (IS_INIT == false) 
  { 
    println("failed to recieve"); 
    return;
  }

  String messageIP = theOscMessage.netaddress().address();
  String messageaddr = theOscMessage.addrPattern();
  String messagetag = theOscMessage.typetag();
  String iaddr = map.removePrefix(messageaddr);
  int isin = map.indexFromAddrPattern(messageaddr); //this could be the only check function, because "begins with" is the same as "equals"

  //player initialization message. 
  if (messageaddr.equals("/host/add")) //remember this fucking string functions you fucking cunt don't fuck up and fucking == with two strings.
  {
    IS_CONNECTED = true; //ought to be another message that just sets this.
    String iprefix = theOscMessage.get(0).stringValue();
    int mapindx = map.indexFromPrefix(iprefix);
    if ( (iprefix.equals(MY_PREFIX)) || (mapindx != -1) ) 
    { 
      println("recieved duplicate object! prefix = "+iprefix+""); 
      map.print();
      return;
    }
    PVector isize = new PVector(random(20, 90), random(90, 180), random(20, 90)); //set size here, just once.
    Avatar iavatar = new Avatar(new PVector(0, 0, 0), new PVector(0, 0, 0), isize, iprefix, -1);
    if (map.add(iavatar)) { 
      println("new Avatar added to map! prefix = "+iprefix+""); 
      map.print();
    }
    else { 
      println("failed to add object to map! prefix = "+iprefix+""); 
      map.print();
    }
  }

  //player removal message
  if (messageaddr.equals("/host/remove")) //remember this fucking string functions you fucking cunt don't fuck up and fucking == with two strings.
  {
    String iprefix = theOscMessage.get(0).stringValue();
    int mapindx = map.indexFromPrefix(iprefix);
    if ( iprefix.equals(MY_PREFIX) || mapindx == -1 ) 
    { 
      return;
    }
    else 
    {
      Avatar iavatar = (Avatar) map.objects.get(mapindx);
      map.remove(iavatar); //checks "isin" so null won't throw
    }

    return;
  }

  if (messageaddr.equals("/host/object") && messagetag.equals("ffffffs"))
  {
    float ix = theOscMessage.get(0).floatValue();
    float iy = theOscMessage.get(1).floatValue();
    float iz = theOscMessage.get(2).floatValue();
    float irx = theOscMessage.get(3).floatValue();
    float iry = theOscMessage.get(4).floatValue();
    float irz = theOscMessage.get(5).floatValue();
    String itype = theOscMessage.get(6).stringValue();


    if (itype.equals("cone")) 
    { 
      PVector ivec = adjustY(new PVector(ix, iy, iz), terrain, iy);
      O3DCone iobject = new O3DCone(ivec, new PVector(irx, iry, irz), new PVector(random(20, 90), random(90, 180), random(20, 90)));
      map.checkBounds(ivec, iobject.radius); //can't check bounds of an uninitialized avatar, yo
      map.add(iobject);
    }

    else 
    { 
      println("recieved bad object type");
    }
  }

  if (isin != -1)
  {
    Avatar ia = (Avatar) map.objects.get(isin);

    if (iaddr.equals("/shot") && messagetag.equals("ffffff"))
    {
      //println("###2 received an osc message with addrpattern "+the.addrPattern()+" and typetag "+theOscMessage.typetag());
      //the.print();
      float ipx = theOscMessage.get(0).floatValue();
      float ipy = theOscMessage.get(1).floatValue();
      float ipz = theOscMessage.get(2).floatValue();
      float ix = theOscMessage.get(3).floatValue();
      float iy = theOscMessage.get(4).floatValue();
      float iz = theOscMessage.get(5).floatValue();

      if (ia.isLiving == 1) 
      {
        ia.startLaser(new PVector(ix, iy, iz));
      }
    }

    if (iaddr.equals("/melee") && messagetag.equals("i"))
    {
      //println("###2 received an osc message with addrpattern "+the.addrPattern()+" and typetag "+theOscMessage.typetag());
      //the.print();
      if (ia.isLiving == 1) 
      {
        ia.melee();
      }
    }

    //a player has been killed
    if (iaddr.equals("/kill") && messagetag.equals("s"))
    {
      //println("###2 received an osc message with addrpattern "+theOscMessage.addrPattern()+" and typetag "+theOscMessage.typetag());
      //theOscMessage.print();
      String is = theOscMessage.get(0).stringValue();
      if (is.equals(MY_PREFIX)) 
      {
        sendKill(MY_PREFIX, myLocation);
        cam.living = false;
      }
      else //everything below should be encapsulated.
      {
        sendKill(is, myLocation);
        int indx = map.indexFromPrefix(is);
        if (indx != -1)
        {
          Avatar avatar = (Avatar) map.objects.get(indx);
          if (avatar.isLiving == 1);
          {
            avatar.kill();
          }
        }
      }
    }



    //player positions, currently updated at draw-rate (could be just at change))
    else if (iaddr.equals("/pos") && messagetag.equals("ffffff"))
    {
      float ix = theOscMessage.get(0).floatValue();
      float iy = theOscMessage.get(1).floatValue();
      float iz = theOscMessage.get(2).floatValue();
      float irx = theOscMessage.get(3).floatValue();
      float iry = theOscMessage.get(4).floatValue();
      float irz = theOscMessage.get(5).floatValue();

      PVector ip = new PVector(ix, iy, iz); //ignore lookheight
      PVector ir = new PVector(irx, iry, irz); //don't rotate avatar
      PVector ivec = adjustY(new PVector(ix, iy, iz), terrain, height_OFFSET); 

      //ia.isLiving = -1; //gotta do this to check bounds
      //if (map.checkBounds(ivec) == -1)
      //{
      ia.set(ivec, new PVector(0, 0, 0));
      ia.isLiving = 1;
      //}
    }
  }
}


public void chuckRespawn(int in)
{
  loop();
  map.setTex(terrainTexCur);
  if (randomSpawnCamera(5000) == -1)
  {
    cam.living = false; 
    sendKill(MY_PREFIX, myLocation);
    sendKill(MY_PREFIX, myBroadcastLocation);
    println("chaos reigns!");
  }
}


void keyPressed()
{
  switch(key)
  {
  case 'C': 
    disconnect(lport, MY_PREFIX); 
    connect(lport, MY_PREFIX); 
    break;
  case 'f': 
    disconnect(lport, MY_PREFIX); 
    IS_CONNECTED = false; 
    break;
  case 'M': 
    map.print(); 
    break;
  case 'I':  
    loop(); 
    SHOTS = 10; 
    if (map.checkBounds(TEMP_SPAWN) == -1) { 
      cam.spawnCamera(TEMP_SPAWN, new PVector(0, 0, 0));
    } 
    else { 
      println("spawning out of bounds at: "+TEMP_SPAWN+"");
    } 
    break;
  case 'v': 
    cam.living = false; 
    sendKill(MY_PREFIX, myLocation); 
    sendKill(MY_PREFIX, myBroadcastLocation); 
    break; //cam.living = false; killCamera(); (MY_PREFIX); break;

    //temp testing variables
  case 'w': 
    joystick.x = 2; 
    break;
  case 'x': 
    joystick.x = -2; 
    break;
  case 'a': 
    joystick.z = -2; 
    break;
  case 'd': 
    joystick.z = 2; 
    break;
  case 's': 
    joystick.x = 0; 
    joystick.z = 0; 
    break;

  case 'j': 
    acc.x = -1;  
    break;
  case 'k': 
    acc.x = 0; 
    acc.y = 0; 
    break;
  case 'l': 
    acc.x = 1; 
    break;
  case 'u': 
    acc.y = 1; 
    break;
  case 'm': 
    acc.y = -1; 
    break;
  case 'O': 
    sendExplosion(); 
    break;
  case 'T': 
    initTextures();  
    break;
  case 'c': 
    shoot(); 
    break;
  case 'z': 
    melee(); 
    break;

  }
}

int randomSpawnCamera(int tries) 
{
  for (int i = 0; i <= tries; i++)
  {
    PVector pvec = new PVector(random( -(map.xsize / 2), (map.xsize / 2) ), 0, random( -(map.zsize / 2), (map.zsize / 2) ));
    pvec = adjustY(pvec, terrain, 0);
    PVector rvec = new PVector(0, 0, 0);
    if (map.checkBounds(pvec) == -1)
    {
      //println("pvec", pvec);
      cam.spawnCamera(pvec.get(), rvec);
      return 0;
    }
  }
  return -1;
}

void killCamera()
{
  camera();
  killScreen = loadImage(respawnTex[(int)random(0, respawnTex.length -1)]);
  image(killScreen, 0, 0, width, height);
  sendExplosion();
}

PVector adjustY(PVector ipv, Terrain it)
{
  PVector opv = ipv.get();
  it.adjustPosition(opv, Terrain.WRAP);
  float oy = it.getHeight(opv.x, opv.z);
  opv.y = oy;
  return opv;
}

PVector adjustY(PVector ipv, Terrain it, float ihover)
{
  PVector opv = ipv.get();
  it.adjustPosition(opv, Terrain.WRAP);
  float oy = it.getHeight(opv.x, opv.z) + ihover; //keep in mind this is gonna want a negative value.
  opv.y = oy;
  return opv;
}

void initTextures() //probably not this.
{//for syncing texture changes  
  laserTexCur = loadImage( laserTex[ (int) random(0, laserTex.length - 1) ] );
  terrainTexCur = loadImage( terrainTex[ (int) random(0, terrainTex.length - 1) ] );
  terrain.setTexture(terrainTexCur, TERRAIN_SLICES);
  terrain.drawMode(S3D.TEXTURE);
  map.setTex(terrainTexCur);
  println("Texture for laser:", laserTexCur, "texture for terrain:", terrainTexCur);
}

PVector shiftGlobalColors()
{
  PVector ocolor = COLOR.get();
  ocolor.x *= sin(3.14 * 300.0 * (millis() * COLOR_RATE));
  ocolor.z *= sin(3.14 * 500.0 * (millis() * COLOR_RATE));
  return ocolor;
}

void shoot()
{
  if (SHOTS <= 0) 
  { 
    println("out of ammo!"); 
    sendBlankPing(myLocation);
  }
  else 
  {
    SHOTS--;
    cam.laser = 1.0;
    sendShot(cam.pos, cam.aim, myLocation);
    sendShot(cam.pos, cam.aim, myBroadcastLocation);
    int indx = map.getIndexByAngle(cam.pos, cam.aim);
    if (map.isAvatar(indx))
    {
      Avatar a = (Avatar) map.objects.get(indx);
      if ( a.kill() != -1 )
      {
        sendKill(a.prefix, myLocation);
        sendKill(a.prefix, myBroadcastLocation);
      }
    }
    else 
    {
      println("shootin' blanks!");
    }
  }
}

void melee()
{
  sendMelee(1, myLocation);
  sendMelee(1, myBroadcastLocation);
  int indx = map.checkBounds(cam.pos, STRIKE_RADIUS);
  if (map.isAvatar(indx))
  {
    Avatar a = (Avatar) map.objects.get(indx);
    if ( a.kill() != -1 )
    {
      sendKill(a.prefix, myLocation);
      sendKill(a.prefix, myBroadcastLocation);
    }
  }
  else 
  {
    println("beatin' meat!");
  }
}

