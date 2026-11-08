"""Stone paths and continuous earth roads for the castle and valley."""
from math import cos, sin, tau


def cobble(m, random, x, z, width, length, height, palette, part):
    angle=random.uniform(-.18,.18)
    corners=[]
    for i in range(8):
        a=tau*(i+.5)/8
        # Project to a rounded rectangular footprint before adding wear.
        radial=random.uniform(.91,1.05)
        rx=width*.5*cos(a)*radial/.924
        rz=length*.5*sin(a)*radial/.924
        corners.append((rx*cos(angle)-rz*sin(angle),rx*sin(angle)+rz*cos(angle)))
    vertices=[(x+u*scale,-(z+v*scale),y+random.uniform(-.004,.004))
              for y,scale in [(height-.036,.96),(height-.010,1),(height,.91)] for u,v in corners]
    vertices.append((x,-z,height+random.uniform(.002,.007)))
    faces=[tuple(range(8))]
    for row in range(2):
        lo,hi=row*8,(row+1)*8
        faces.extend((lo+i,hi+i,hi+(i+1)%8,lo+(i+1)%8) for i in range(8))
    faces.extend((16+(i+1)%8,16+i,24) for i in range(8))
    m.add(vertices,faces,random.choice(palette),part)


def court_paths(m, random):
    palette=("Calcaire", "Calcaire", "Dalle sombre", "Dalle claire", "Dalle olive")
    # One continuous avenue, with two wings meeting it without overlaid slabs.
    sections = [(-2.01,2.01,-19.2,22.04),(-20.55,-2.01,6.68,8.19),
                (2.01,20.53,6.68,8.19),(-16.24,-10.05,-10.62,-8.85),
                (11.15,15.9,-4.55,-2.88)]
    for x0,x1,z0,z1 in sections:
        z=z0
        while z < z1-.086:
            span=min(random.uniform(.164,.288),z1-z)
            row=z+span/2
            x=x0+random.uniform(-.052,.051)
            while x < x1-.083:
                wide=min(random.uniform(.17,.34),x1-x)
                cobble(m,random,x+wide/2,row,wide-.009,span-.009,random.uniform(.100,.116),
                       palette,"Chemins_cour")
                x+=wide
            z+=span
    for side in (-1,1):
        for i in range(116):
            z=-18.8+i*.351
            x=side*(2.06+random.uniform(-.04,.04))
            if not 6.43<z<8.45:
                cobble(m,random,x,z,.16,.338,random.uniform(.112,.127),palette,"Bordures")
    for _ in range(86):
        x,z=random.uniform(-20.7,20.7),random.uniform(-20.4,20.8)
        if abs(x) < 2.4 or abs(z-7.4)<1:
            continue
        span=random.uniform(.07,.19)
        cobble(m,random,x,z,span,span*.83,.089,palette,"Galets_cour")


def _ribbon(m, points, material):
    vertices=[]
    for i,(x,z,w,y) in enumerate(points):
        ax,az,*_=points[max(0,i-1)]
        bx,bz,*_=points[min(len(points)-1,i+1)]
        dx,dz=bx-ax,bz-az
        length=(dx*dx+dz*dz)**.5
        nx,nz=dz/length,-dx/length
        for side in (-1,1):
            vertices.append((x+nx*w*side,-(z+nz*w*side),y))
    faces=[(2*i+1,2*i,2*i+2,2*i+3) for i in range(len(points)-1)]
    m.add(vertices,faces,material,"Chemins_vallee")


def valley_paths(m, random):
    road=[]
    for i in range(78):
        z=34.5+i*.63
        w=2.60+.14*sin(z*.7)+.12*cos(z*1.7)
        x=(.36*sin((z-34.5)*.19)+.27*sin((z-34.5)*.41))
        road.append((x,z,w,.019))
    _ribbon(m,road,"Chemin vallée")
    _ribbon(m,[(0,22.4,2.57,.025),(0,24.95,2.61,.025)],"Chemin vallée")
    for direction in (-1,1):
        branch=[]
        for i in range(41):
            x=direction*(2.27+i*.62)
            z=46.12+1.62*sin(abs(x)*.115)+.22*sin(x*.44)
            w=1.78+.13*sin(i*.82)
            branch.append((x,z,w,.015))
        _ribbon(m,branch,"Chemin traverse")
    for z in (24.6,35.15):
        for _ in range(31):
            x=random.uniform(-2.19,2.19)
            span=random.uniform(.09,.21)
            cobble(m,random,x,z+random.uniform(-.32,.35),span,span*.86,.055,
                   ("Calcaire","Dalle sombre","Dalle olive"),"Approche_pont")
