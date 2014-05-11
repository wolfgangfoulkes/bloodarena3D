class Map
{
  float xsize;
  float zsize;
  ArrayList<Object3D> objects;
  
  Map(float ixs, float izs)
  {
    xsize = ixs;
    zsize = izs;
    objects = new ArrayList<Object3D>(100);
    objects.ensureCapacity(100);
  }
  
  int add(Object3D iobject) //type-check to include "?" right now.
  {
    objects.ensureCapacity(100);
    int isIn = objects.indexOf(iobject);
    int isInBounds = checkBounds(iobject.p);
    if ( (isIn == -1) && (isInBounds == -1) )
    {
      objects.add(iobject);
      //println(iobject.p, iobject.r, iobject.radius);
      
      return 0;
    }
    
    return -1;
  }
  
  int remove(Object3D iobject)
  {
    objects.ensureCapacity(100);
    int indexof = objects.indexOf(iobject);
    if (indexof != -1)
    {
      objects.remove(iobject);
      return indexof;
    }
    
    return -1;
  }
  
  void clear()
  {
    objects.clear();
  }
  
  int move(Object3D iobject, PVector ipos, PVector irot)
  {
    objects.ensureCapacity(100);
    int iindx = this.remove(iobject);
    int isInBounds = checkBounds(ipos);
    if ( (iindx != -1) ) //janky as shit.
    {
      iobject.set(ipos, irot);
      this.add(iobject); 
      return iindx;
    }
    else 
    {
      return -1;
    }
  }
  
  void update()
  {
    objects.ensureCapacity(100);
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D object = objects.get(i);
      object.update();
      if (object.isLiving == -1)
      {
        objects.remove(object);
      }
    }
  }
  
  void display()
  {
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D object = objects.get(i);
      shader(SHADER_NOISE);
      object.display();
      resetShader();
    }
  }
  
  int checkBounds(PVector icoord, float dist)
  {
    objects.ensureCapacity(100);
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= (oobject.radius + dist))
      {
        return i; 
      }
    }  
    return -1;
  }
  
  int checkBounds(PVector icoord)
  {
    objects.ensureCapacity(100);
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= oobject.radius)
      {
        return i; 
      }
    }  
    return -1;
  }
  
  int checkBounds(float ix, float iy, float iz)
  {
    objects.ensureCapacity(100);
    PVector icoord = new PVector(ix, iy, iz);
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= oobject.radius)
      {
        return i;
      }
    }  
    return -1;
  }
  
  float getDistFromAvatar(PVector icoord, float idist) //if an object's distance < input, return distance, else return input.
  {
    float dist = idist;
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      float dist2 = PVector.dist(ic, oc);
      if ((oobject.type.equals("avatar")) && (dist2 < dist))
      {
        dist = dist2; 
      }
    }  
    return dist;
  }
  
  int checkCoord(PVector icoord)
  {
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      if (oobject.p == icoord) 
      {
        return i;
      }
    }  
    return -1;
  }
 
 
  int checkCoord(float ix, float iy, float iz)
  {
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      if ((oobject.p.x == ix) && (oobject.p.y == iy) && (oobject.p.z == iz))
      {
        return i;
      }
    }  
    return -1;
  }
  
  int getIndexByAngle(PVector ipos, PVector iaim) 
  {
    objects.ensureCapacity(100);
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      PVector vec1 = PVector.sub(iaim, ipos);
      PVector vec2 = PVector.sub(objects.get(i).p, ipos);
      vec1.y = 0;
      vec2.y = 0;
      //could individually check the xz angles (using vector2s) and the xyz angle and xz would be less forgiving.
      float vecangle = degrees(PVector.angleBetween(vec1, vec2));
      if (vecangle <= 9)
      {
        return i;
      }
    }
    return -1;
  }
  
  boolean isAvatar (int iindx)
  {
    if (iindx < 0 || iindx >= objects.size())
    {
      return false;
    }
    return objects.get(iindx).type.equals("avatar");
  }
  
  void setTex (PImage itex)
  {
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      oobject.setTex(itex);
    }
  }
    
  void print()
  {
    println("-----MAP-----");
    println("size = "+objects.size()+"");
    for (int i = objects.size() - 1; i >= 0; i--)
    {
      Object3D oobject = objects.get(i);
      println("object at index "+i+": type = "+oobject.getType()+", position = "+oobject.p+", rotation = "+oobject.r+"");
    }
  }
}
