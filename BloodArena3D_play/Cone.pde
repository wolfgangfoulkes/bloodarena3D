class O3DCone extends Object3D 
//would be pretty easy to make a generic class with all the stuff the Shapes3D library has (radius, slices)
//and then extend just with the specific object, and default values.

{
  Cone cone;
  int nbrSg;
  PShader shader;
  
  O3DCone(PVector ip, PVector ir, PVector isize)
  {
    super(ip, ir, isize);
    type = "cone";
    nbrSg = (int) random(3, 5);
    cone = new Cone(APPLET, nbrSg);
    cone.setSize(isize.x / 2, isize.z / 2, isize.y);
    cone.moveTo(p);
    cone.rotateToY(radians(r.y));
    cone.drawMode(S3D.TEXTURE);
    cone.setTexture(terrainTexCur);
    shader = SHADER_NOISE;
  }
  
  O3DCone(float ix, float iy, float iz, float irx, float iry, float irz, PVector isize)
  {
    super(ix, iy, iz, irx, iry, irz, isize);
    type = "cone";
    cone = new Cone(APPLET, nbrSg);
    cone.setSize(isize.x / 2, isize.z / 2, isize.y);
    cone.moveTo(p);
    cone.rotateToY(radians(r.y));
    cone.drawMode(S3D.TEXTURE);
    cone.setTexture(terrainTexCur);
    shader = SHADER_NOISE;
  }
  
  void set(PVector ip, PVector ir)
  {
    super.set(ip, ir);
    cone.moveTo(p);
    cone.rotateToY(radians(r.y));
  }
  
  void set(PVector ip, PVector ir, PVector isize)
  {
    super.set(ip, ir, isize);
    cone = new Cone(APPLET, nbrSg);
    cone.setSize(size.x / 2, size.z / 2, size.y);
    cone.moveTo(p);
    cone.rotateToY(radians(r.y));
    cone.drawMode(S3D.TEXTURE);
    cone.setTexture(terrainTexCur);
    shader = SHADER_NOISE;
  }
  
  void update() //this'll cause more rather than fewer problems. movements will be small enough at a time, that there shouldn't be an issue.
  {
    cone.setTexture(terrainTexCur);
  }
  
  void display()
  {
    shader(shader);
    cone.draw();
    resetShader();
  }
  
  void setTex(PImage itex)
  {
    cone.setTexture(itex);
    shader = SHADER_NOISE;
  }
  
  
  Shape3D getShape ()
  {
    return cone;
  }
  
}
