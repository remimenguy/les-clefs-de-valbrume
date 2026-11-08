"""Decorative construction for the domestic and royal buildings in Valbrume."""
from math import cos, sin, tau


def tile_roof(m, random, x, z, width, depth, base, rise):
    part="Couvertures_ardoise"
    run=width/2
    rows=max(4,round(run/.32))
    for side in (-1,1):
        for row in range(rows):
            u=row*run/rows
            width_step=run/rows
            first=-depth/2 - (.17 if row%2 else 0)
            while first < depth/2:
                length=min(random.uniform(.36,.55),depth/2-first)
                if length < .04:
                    break
                z0=max(first,-depth/2)
                z1=first+length-.012
                if z1 <= z0+.018:
                    first+=length
                    continue
                left=u+random.uniform(-.007,.007)
                right=min(run,u+width_step+.024)
                up=random.uniform(.017,.032)
                coords=[(x+side*t,-(z+zz),base+rise*(1-t/run)+up+h)
                        for h in (0,.022) for t,zz in
                        ((left,z0),(right,z0),(right,z1),(left,z1))]
                faces=[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
                if side == 1:
                    faces=[tuple(reversed(face)) for face in faces]
                m.add(coords,faces,random.choice(("Ardoise","Ardoise","Ardoise claire","Ardoise patine")),part)
                first+=length


def timber_house(m, x, z, w, d, h):
    part="Charpentes"
    for side in (-1,1):
        front=z+side*(d/2+.068)
        for y in (.39,1.84,h-.15):
            if y < h:
                m.box(x,y,front,w+.10,.156,.143,"Chêne",part=part)
        for dx in (-.48,-.247,.247,.48):
            m.box(x+dx*w,h*.52,front,.162,h*.95,.140,"Chêne",part=part)
        for j in (-1,1):
            m.beam((x+j*w*.47,.41,front+side*.029),
                   (x+j*w*.25,min(h-.13,1.84),front+side*.029),
                   .083,.071,"Chêne",4,part)
        if h>2:
            for dx in (-.33,.33):
                frame_x=x+dx*w
                center_y=min(2.33,h-.67)
                m.box(frame_x,center_y,front+side*.065,.71,.76,.085,"Chêne clair",part=part)
                m.box(frame_x,center_y,front+side*.110,.55,.59,.031,"Verre sombre",part=part)
                for offset in (-.16,0,.16):
                    m.box(frame_x+offset,center_y,front+side*.135,.027,.56,.038,"Fer",part=part)
                m.box(frame_x,center_y,front+side*.135,.55,.029,.041,"Fer",part=part)
                m.box(frame_x,center_y-.394,front+side*.106,.84,.105,.241,"Dalle claire",part=part)
                m.box(frame_x,center_y+.390,front+side*.082,.83,.112,.173,"Chêne",part=part)
        for ix in (-1,1):
            xside=x+ix*(w/2+.076)
            m.box(xside,.34,z,.151,.157,d,"Chêne",part=part)
            m.box(xside,h-.18,z,.158,.153,d,"Chêne",part=part)
            m.box(xside,h*.52,z,.153,h*.91,.157,"Chêne",part=part)
            m.beam((xside,.46,z+side*d*.43),(xside,h-.28,z),.073,.074,"Chêne",4,part)
    front=z+d/2
    door_height=min(1.99,h*.88)
    m.box(x,door_height*.50,front+.126,.94,door_height,.111,"Chêne",part=part)
    for i in range(7):
        m.box(x+(i-3)*.124,door_height*.50,front+.194,.113,door_height-.06,.047,
              "Chêne clair" if i in (1,4) else "Chêne",part=part)
    for y in (door_height*.27,door_height*.75):
        m.box(x,y,front+.221,.82,.087,.046,"Fer",part=part)
        for dx in (-.32,0,.32):
            m.oval(x+dx,y,front+.25,.038,.041,.035,"Fer",8,part)
    m.box(x,door_height+.08,front+.135,1.27,.169,.235,"Chêne",part=part)
    m.oval(x+.293,door_height*.50,front+.25,.087,.087,.027,"Or mat",12,part)
    m.box(x,.074,front+.22,1.25,.147,.56,"Dalle claire",part=part)
    for i in range(10):
        sx=x+w*(i/9-.5)
        m.box(sx,h-.073,front+.195,.102,.14,.53,"Chêne",part=part)
    if h > 2.7:
        tx=x+w*.31
        tz=z-d*.26
        for i in range(6):
            m.box(tx,h+.19+i*.225,tz,.62-(i%2)*.026,.21,.66,
                  "Pierre grise" if i%2 else "Pierre ombre",part=part)
        m.box(tx,h+1.51,tz,.78,.149,.79,"Dalle sombre",part=part)
        m.box(tx,h+1.589,tz,.38,.024,.41,"Fer",part=part)


def crate(m, x, z, scale, yaw=0):
    part="Mobilier"
    m.box(x,.24*scale,z,.65*scale,.46*scale,.61*scale,"Chêne",yaw,part)
    for sign in (-1,1):
        for j in (-1,0,1):
            m.box(x,.23*scale+j*.133*scale,z+sign*.312*scale,.64*scale,
                  .115*scale,.056*scale,"Chêne clair" if j!=0 else "Chêne",yaw,part)
        m.box(x+sign*.286*scale,.26*scale,z,.059*scale,.52*scale,.68*scale,"Chêne",yaw,part)
    for a in (-.21,-.07,.07,.21):
        m.box(x+a*scale,.477*scale,z,.122*scale,.042*scale,.61*scale,"Chêne clair",yaw,part)
    for dx in (-.25,.25):
        for dz in (-.27,.27):
            m.oval(x+dx*scale,.507*scale,z+dz*scale,.031*scale,.012*scale,.031*scale,"Fer",8,part)


def bench(m, x, z):
    p="Mobilier"
    for i in range(4):
        m.box(x,.414,z+(i-1.5)*.117,1.77,.063,.104,
              "Chêne clair" if i%2 else "Chêne",part=p)
    for side in (-1,1):
        xx=x+side*.639
        for dz in (-.164,.166):
            m.beam((xx,.048,z+dz),(xx,.39,z+dz*.76),.061,.053,"Chêne",4,p)
        m.box(xx,.289,z,.115,.082,.401,"Chêne",part=p)
        m.beam((xx,.34,z+.147),(xx-side*.225,.134,z+.147),.043,.041,"Chêne",4,p)
    m.box(x,.176,z,1.23,.086,.105,"Chêne",part=p)


def vegetables(m, random, x, z, variant):
    p="Potager"
    base=.22
    if variant == 0:
        m.cone(x,base+.07,z,.058,.102,.142,"Légume",10,p)
    for i in range(8 if variant else 5):
        angle=i*tau/8+random.uniform(-.25,.25)
        reach=random.uniform(.098,.208) if variant else random.uniform(.072,.131)
        rise=random.uniform(.11,.21) if variant else random.uniform(.14,.28)
        ux,uz=cos(angle),sin(angle)
        width=(.045 if variant else .018)*random.uniform(.73,1.1)
        verts=[(x,-z,base+.035),
               (x+ux*reach*.51-uz*width,-(z+uz*reach*.51+ux*width),base+rise*.92),
               (x+ux*reach,-(z+uz*reach),base+rise*.72),
               (x+ux*reach*.51+uz*width,-(z+uz*reach*.51-ux*width),base+rise*.85),
               (x+ux*reach*.54,-(z+uz*reach*.54),base+rise)]
        m.add(verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],
              random.choice(("Feuille","Feuille claire","Feuille sombre")),p)
        m.beam((x,base+.035,z),(x+ux*reach*.51,base+rise*.87,z+uz*reach*.51),
               .005,.002,"Feuille claire",5,p)


def hall(m):
    p="Logis"
    for x in (-7.3,7.3):
        for offset in (-.34,.34):
            m.box(x+offset,2.68,-12.99,.123,4.46,.134,"Dalle claire",part=p)
        for y,w in ((.32,1.17),(.47,1.04),(4.44,.92),(4.58,1.07),(4.72,1.18)):
            m.box(x,y,-13.45,w,.145,w*.94,"Calcaire",part=p)
    for x in (-6.9,-5.1,-3.3,-1.6,0,1.6,3.3,5.1,6.9):
        m.box(x,5.53,-18.77,.33,.47,.44,"Pierre claire",part=p)
        m.box(x,5.77,-18.80,.52,.133,.53,"Calcaire",part=p)
    for x in (-2.77,2.77):
        m.box(x,3.32,-18.758,.81,1.40,.088,"Dalle sombre",part=p)
        m.box(x,3.27,-18.693,.62,1.14,.058,"Verre sombre",part=p)
        for dx in (-.25,0,.25):
            m.box(x+dx,3.25,-18.658,.047,1.05,.053,"Fer",part=p)
        for y in (2.91,3.24,3.62):
            m.box(x,y,-18.652,.65,.043,.053,"Fer",part=p)
        m.box(x,2.64,-18.68,.98,.18,.35,"Calcaire",part=p)
    for x in (-6.41,6.41):
        m.box(x,1.04,-16.39,.85,.11,.60,"Chêne",part=p)
        m.box(x,.55,-16.39,.10,.86,.45,"Chêne clair",part=p)
        for z in (-16.55,-16.21):
            m.oval(x,1.18,z,.17,.26,.16,"Argile",14,p)


def bridge(m):
    p="Ouvrage_pont"
    for side in (-1,1):
        x=side*1.66
        m.box(x,.041,29.9,.22,.22,10.43,"Chêne",part=p)
        for i in range(21):
            z=25+i*.49
            for offset in (-.12,.12):
                m.oval(x,.232,z+offset,.041,.013,.038,"Fer",8,p)
        for z in (25,27,29,31,33,34.88):
            m.oval(side*1.96,.935,z,.20,.11,.20,"Chêne",10,p)
            m.cone(side*1.96,.638,z,.127,.127,.069,"Fer",10,p)
    for z in (25.13,34.78):
        m.box(0,.075,z,4.65,.244,.53,"Dalle sombre",part=p)


def throne(m):
    p="Trone"
    seat_y=.947
    m.box(0,seat_y-.11,-17.99,.88,.11,.69,"Chêne",part=p)
    m.oval(0,seat_y,-17.97,.812,.135,.607,"Velours",26,p)
    m.box(0,1.415,-18.335,.861,.935,.137,"Chêne",part=p)
    m.oval(0,1.403,-18.258,.691,.853,.085,"Velours",28,p)
    for side in (-1,1):
        x=side*.442
        for z in (-18.301,-17.706):
            rings=[(.477,.031),(.541,.052),(.614,.045),(.662,.038),(.733,.050),
                   (.820,.045),(.870,.058),(.956,.042)]
            for (a,r),(b,s) in zip(rings,rings[1:]):
                m.beam((x,a,z),(x,b,z),r,s,"Chêne",14,p)
        z=-18.31
        for lo,hi,r,s in [(1.008,1.16,.057,.034),(1.16,1.82,.034,.043),(1.82,1.897,.043,.035),
                           (1.897,1.94,.039,.022)]:
            m.beam((x,lo,z),(x,hi,z),r,s,"Chêne clair",14,p)
        m.oval(x,1.968,z,.064,.079,.064,"Chêne clair",18,p)
        for y in (1.079,1.203,1.82,1.897):
            m.cone(x,y,z,.041,.041,.024,"Or mat",14,p)
        m.beam((x,1.145,-17.698),(x,1.149,-18.298),.044,.044,"Chêne",10,p)
        m.oval(x,1.148,-17.686,.097,.071,.12,"Chêne clair",20,p)
        m.beam((x,.95,-17.77),(x,1.14,-17.75),.028,.031,"Chêne",14,p)
        for j in range(14):
            y=1.042+j*.054
            z=-18.247-.012*(j%2)
            m.beam((x-side*.036,y,z),(x-side*.009,y+.026,z),.006,.005,"Or mat",6,p)
    for row in range(6):
        for col in range(5):
            x=(col-2)*.091+(.022 if row%2 else -.022)
            y=1.123+row*.103
            m.oval(x,y,-18.211,.014,.015,.012,"Or mat",10,p)
    last=None
    for i in range(21):
        x=(i/20-.5)*.802
        y=1.843+.089*(1-(abs(x)/.401)**1.71)
        point=(x,y,-18.271)
        if last:
            m.beam(last,point,.023,.023,"Chêne clair",9,p)
        last=point
        if i%2==0:
            m.oval(x,y-.022,-18.250,.023,.026,.013,"Or mat",10,p)
    for side in (-1,1):
        points=[(0,1.910,-18.237),(side*.041,1.955,-18.237),
                (side*.067,1.945,-18.237),(side*.059,1.921,-18.237)]
        for a,b in zip(points,points[1:]):
            m.beam(a,b,.009,.006,"Or mat",8,p)
    m.beam((0,1.902,-18.237),(0,1.981,-18.237),.012,.004,"Or",10,p)
