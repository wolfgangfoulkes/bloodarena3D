class Map
{
  float xsize;
  float zsize;
  CopyOnWriteArrayList<Object3D> objects;
  
  Map(float ixs, float izs)
  {
    xsize = ixs;
    zsize = izs;
    objects = new CopyOnWriteArrayList<Object3D>();
  }
  
  boolean add(Object3D iobject) //type-check to include "?" right now.
  {
    int isInBounds = checkBounds(iobject.p);
    if ( isInBounds == -1)
    {
      return objects.addIfAbsent(iobject);
    }
    return false;
  }
  
  boolean remove(Object3D iobject)
  {
      return objects.remove(iobject);
  }
  
  void clear()
  {
    objects.clear();
  }
  
  boolean move(Object3D iobject, PVector ipos, PVector irot) //with the CopyOnWriteArrayList this will be costly as fuck
  {
    boolean removed = this.remove(iobject);
    int isInBounds = checkBounds(ipos);
    if ( removed )
    {
      iobject.set(ipos, irot);
      this.add(iobject); 
    }
    
    return removed;
  }
  
  void update()
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D object = it.next();
      object.update();
      if (object.isLiving == -1)
      {
        objects.remove(object);
      }
    }
  }
  
  void display()
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D object = it.next();
      shader(SHADER_NOISE);
      object.display();
      resetShader();
    }
  }
  
  int checkBounds(PVector icoord, float dist)
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int oindx = it.nextIndex();
      Object3D oobject = it.next();
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= (oobject.radius + dist))
      {
        return oindx;
      }
    }  
    return -1;
  }
  
  int checkBounds(PVector icoord)
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int oindx = it.nextIndex();
      Object3D oobject = it.next();
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= oobject.radius)
      {
        return oindx;
      }
    }  
    return -1;
  }
  
  int checkBounds(float ix, float iy, float iz)
  {
    PVector icoord = new PVector(ix, iy, iz);
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int oindx = it.nextIndex();
      Object3D oobject = it.next();
      PVector ic = new PVector(icoord.x, 0, icoord.z);
      PVector oc = new PVector(oobject.p.x, 0, oobject.p.z);
      if (PVector.dist(ic, oc) <= oobject.radius)
      {
        return oindx;
      }
    }  
    return -1;
  }
  
  float getDistFromAvatar(PVector icoord, float idist) //if an object's distance < input, return distance, else return input.
  {
    float dist = idist;
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D oobject = it.next();
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
  
  int getIndexByAngle(PVector ipos, PVector iaim) 
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int oindx = it.nextIndex();
      Object3D oobject = it.next();
      PVector vec1 = PVector.sub(iaim, ipos);
      PVector vec2 = PVector.sub(oobject.p, ipos);
      println("isAvatar within indexByAngle:", this.isAvatar(oindx));
      vec1.y = 0;
      vec2.y = 0;
      //could individually check the xz angles (using vector2s) and the xyz angle and xz would be less forgiving.
      float vecangle = degrees(PVector.angleBetween(vec1, vec2));
      if (vecangle <= 9)
      {
        return oindx;
      }
    }
    return -1;
  }
  
  boolean isAvatar (int iindx)
  {
    if (iindx < 0 || iindx >= objects.size())
    {
      println("bad index for IsAvatar "+iindx+"");
      return false;
    }
    println("good index for IsAvatar "+iindx+"");
    return objects.get(iindx).type.equals("avatar");
  }
  
  void setTex (PImage itex)
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D oobject = it.next();
      oobject.setTex(itex);
    }
  }
    
  void print()
  {
    println("-----MAP-----");
    println("size = "+objects.size()+"");
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int oindx = it.nextIndex();
      Object3D oobject = it.next();
      println("object at index "+oindx+": type = "+oobject.getType()+", position = "+oobject.p+", rotation = "+oobject.r+"");
    }
  }
}
