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
  
  Object3D getObject(int iindx)
  {
    if (iindx >= 0 && iindx < objects.size())
    {
      Object3D oobject = objects.get(iindx);
      return oobject;
    }
    
    return null;
  }
  
  Avatar getAvatar(int iindx)
  {
    if (iindx >= 0 && iindx < objects.size())
    {
      Object3D oobject = objects.get(iindx);
      if (oobject.type.equals("avatar"));
      {
        return (Avatar) oobject;
      }
    }
    
    return null;
  }
  
  boolean add(Object3D iobject) //type-check to include "?" right now.
  {
      return objects.addIfAbsent(iobject);
  }
  
  boolean remove(Object3D iobject)
  {
      return objects.remove(iobject);
  }
  
  void clear()
  {
    objects.clear();
  }
  
  
  void update()
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D object = it.next();
      object.update();
    }
  }
  
  void display()
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      Object3D object = it.next();
      if (object.isLiving != -1)
      {
        shader(SHADER_NOISE);
        object.display();
        resetShader();
      }
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
      if ((oobject.isLiving == 1) && (PVector.dist(ic, oc) <= oobject.radius + dist))
      {
        println("bounds! position: "+oobject.p+" type: "+oobject.type+"");
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
      if ((oobject.isLiving == 1) && (PVector.dist(ic, oc) <= oobject.radius))
      {
        println("bounds! position: "+oobject.p+" type: "+oobject.type+"");
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
      if ((oobject.isLiving == 1) && (PVector.dist(ic, oc) <= oobject.radius))
      {
        println("bounds! position: "+oobject.p+" type: "+oobject.type+"");
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
      if ((oobject.isLiving == 1) && (oobject.type.equals("avatar")) && (dist2 < dist))
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
      if ((oobject.isLiving == 1) && (vecangle <= 9))
      {
        return oindx;
      }
    }
    return -1;
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
      println("object at index "+oindx+": type = "+oobject.getType()+", position = "+oobject.p+", rotation = "+oobject.r+", status, "+oobject.isLiving+"");
      if (oobject.type.equals("avatar"))
      {
        Avatar oavatar = (Avatar) oobject;
        String oprefix = oavatar.prefix;
        println("prefix = "+oprefix+"");
      }
      else
      {
        println("no prefix");
      }
      
    }
  }
  
  //-----AVATAR FUNCTIONS-----//
  
  boolean isAvatar (int iindx)
  {
    if (iindx >= 0 && iindx <= objects.size())
    {
      println("good index for IsAvatar "+iindx+"");
      return objects.get(iindx).type.equals("avatar");
    }
    println("bad index for IsAvatar "+iindx+"");
    return false;
  }
  
  int indexFromPrefix(String ipre)
  {
    int oindx = -1;
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int indx = it.nextIndex();
      Object3D oobject = it.next();
      if (oobject.type.equals("avatar"))
      {
        Avatar oavatar = (Avatar) oobject;
        if (oavatar.prefix.equals(ipre))
        {
          oindx = indx;
        }
      }
    }
    return oindx;
  }
  
  String removePrefix(String iaddr)
  {
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int indx = it.nextIndex();
      Object3D oobject = it.next();
      if (oobject.type.equals("avatar"))
      {
        Avatar oavatar = (Avatar) oobject;
        if (iaddr.startsWith(oavatar.prefix))
        {
          String ostring = iaddr.substring(oavatar.prefix.length(), iaddr.length()); //-1 to remove the last parenthesis
          return ostring;
        }
      }
    }
    
    return iaddr;
  }
  
  int indexFromAddrPattern(String iaddr)
  {
    int oindex = -1;
    for (ListIterator<Object3D> it = objects.listIterator(); it.hasNext();)
    {
      int indx = it.nextIndex();
      Object3D oobject = it.next();
      if (oobject.type.equals("avatar"))
      {
        Avatar oavatar = (Avatar) oobject;
        if (iaddr.startsWith(oavatar.prefix))
        {
          return indx;
        }
      }
    }
    return oindex;
  }
}
 
