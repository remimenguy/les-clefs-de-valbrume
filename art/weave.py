"""Build tileable fabric and chain-mail PBR maps with Pillow."""
from math import cos, exp, sin, sqrt, tau
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets" / "textures"
SIZE = 512


def weave(u, v):
    x, y = u*36, v*36
    warp = max(0.0, cos(tau*x))**2.5
    weft = max(0.0, cos(tau*y))**2.5
    over = cos(tau*(x+y)*.5)*.32 + .5
    height = .51*warp*over + .46*weft*(1-over)
    fibres = .024*sin(tau*(x*8+y/9))+.019*cos(tau*(y*7-x/12))
    value = .72+.21*height+fibres
    return height+fibres, value, .91-.068*height


def mail(u, v):
    x, y = u*15, v*20
    best = 0
    for row in range(int(y)-1,int(y)+2):
        column=int(x-(row%2)*.5)
        for col in range(column-1,column+2):
            dx=x-col-(row%2)*.5
            dy=(y-row)*.79
            radius=sqrt(dx*dx+dy*dy)
            best=max(best, exp(-((radius-.30)/.052)**2))
    return best*.33, .34+.29*best, .83-.34*best


def byte(value):
    return round(max(0,min(1,value))*255)


def make(name, source):
    fields = [source(x/SIZE, y/SIZE) for y in range(SIZE) for x in range(SIZE)]
    base = Image.new("L",(SIZE,SIZE))
    base.putdata([byte(value) for _,value,_ in fields])
    base.save(OUT/(name+"_albedo.jpg"),quality=92)
    roughness = Image.new("L",(SIZE,SIZE))
    roughness.putdata([byte(rough) for _,_,rough in fields])
    roughness.save(OUT/(name+"_roughness.jpg"),quality=90)
    normals=[]
    for y in range(SIZE):
        for x in range(SIZE):
            a = fields[y*SIZE+(x+1)%SIZE][0]-fields[y*SIZE+(x-1)%SIZE][0]
            b = fields[((y+1)%SIZE)*SIZE+x][0]-fields[((y-1)%SIZE)*SIZE+x][0]
            length=sqrt(a*a+b*b+1)
            normals.append((byte(.5-.5*a/length),byte(.5+.5*b/length),byte(.5+.5/length)))
    normal=Image.new("RGB",(SIZE,SIZE))
    normal.putdata(normals)
    normal.save(OUT/(name+"_normal.jpg"),quality=96,subsampling=0)


if __name__ == "__main__":
    make("valbrume_laine", weave)
    make("valbrume_maille", mail)
