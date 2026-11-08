"""Valbrume character geometry. All lengths are in metres."""
import gzip
import json
from pathlib import Path
from math import cos, pi, sin, tau

ANATOMY = json.loads(gzip.decompress((Path(__file__).parent/"morphology"/"anatomie.json.gz").read_bytes()))
SKIN = {"domestique":"Visage jeune","garde":"Visage garde","intendant":"Visage mûr","roi":"Visage mûr"}


def loft(m, rings, material, part="Maillage", sides=24, folds=0.0, hem_material=None):
    # Clothing gets intermediate rings so folds can turn with the cut of each panel.
    sections = []
    for index, (lower, upper) in enumerate(zip(rings, rings[1:])):
        subdivisions = max(1, round((upper[0]-lower[0])/.035)) if folds else 1
        for step in range(subdivisions):
            t = step/subdivisions
            ring = [a+(b-a)*t for a,b in zip(lower,upper)]
            if folds and len(rings) > 2:
                before, after = rings[max(0,index-1)], rings[min(len(rings)-1,index+2)]
                # Smooth the silhouette without changing the authored hem and collar positions.
                for k in range(1,5):
                    a,b,c,d = before[k],lower[k],upper[k],after[k]
                    ring[k] = .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
            sections.append(ring)
    sections.append(rings[-1])
    vertices = []
    for y, x, z, width, depth in sections:
        for i in range(sides):
            a = i*tau/sides
            pleat = .48*sin(7*a+y*11)+.22*cos(13*a-y*18)+.19*sin(4*a+y*25)
            wrinkle = .13*sin(a*17 + y*105)*max(0, cos(a*3+y*7))
            ripple = 1 + folds*(pleat+wrinkle)
            vertices.append((x+cos(a)*width*ripple, -(z-sin(a)*depth*ripple), y))
    faces = [tuple(reversed(range(sides)))]
    for j in range(len(sections)-1):
        lo, hi = j*sides, (j+1)*sides
        faces.extend((lo+i,lo+(i+1)%sides,hi+(i+1)%sides,hi+i) for i in range(sides))
    faces.append(tuple(range(len(vertices)-sides,len(vertices))))
    colors = material
    if hem_material:
        band_faces = (1 + sides * max(1, round((rings[1][0]-rings[0][0])/.035))) if folds else 1 + sides
        colors = [hem_material] * band_faces + [material] * (len(faces) - band_faces)
    m.add(vertices, faces, colors, part)


def coat(m, material, hem, radius=.272):
    loft(m, [(hem,0,0,radius,.177),(hem+.10,0,0,radius*.97,.178),
             (.97,0,.002,.229,.156),(1.10,0,.002,.218,.149),
             (1.28,0,.003,.253,.164),(1.40,0,-.003,.272,.151),
             (1.48,0,-.010,.191,.124),(1.527,0,0,.108,.094)],
         material, sides=38, folds=.11)
    loft(m, [(1.493,0,-.007,.108,.098),(1.523,0,-.008,.105,.096),
             (1.547,0,-.009,.096,.089)],"Lin",sides=32,folds=.09)
    for side in (-1,1):
        m.beam((side*.038,1.494,.121),(side*.024,1.463,.138),.005,.005,"Lin",8)
        m.beam((side*.024,1.463,.138),(0,1.433,.150),.005,.004,"Lin",8)


def apron(m):
    rows, columns = 10, 14
    vertices = []
    for row in range(rows + 1):
        t = row / rows
        for column in range(columns + 1):
            u = 2 * column / columns - 1
            x = u * (.184 - .017*t)
            y = .771 + .246*t + .016*u*u*(1-t)
            z = .200 - .047*u*u - .013*t + .004*cos(u*15+t*4)*(1-t)
            vertices.append((x, -z, y))
    faces = []
    colors = []
    for row in range(rows):
        for column in range(columns):
            corner = row*(columns + 1) + column
            face = (corner, corner+1, corner+columns+2, corner+columns+1)
            faces.append(face)
            colors.append("Couture" if column in (0, columns-1) or row == 0 else "Toile")
    m.add(vertices, faces, colors, "Maillage")


def belt(m, height, formal=False):
    loft(m, [(height-.034,0,0,.224,.171),(height+.034,0,0,.217,.164)],
         "Cuir sombre", sides=30, folds=.017)
    for y in (height-.031,height+.031):
        loft(m, [(y-.004,0,0,.226,.172),(y+.004,0,0,.226,.172)],
             "Couture", sides=30)
    for x in (-.052,.052):
        m.box(x,height,.178,.017,.077,.018,"Or")
    for y in (height-.035,height+.035):
        m.box(0,y,.18,.11,.015,.019,"Or")
    m.beam((-.043,height,.189),(.047,height,.189),.005,.005,"Or",8)
    if formal:
        for i in range(7):
            a=.29*i-.89
            m.oval(.226*sin(a),height,.173*cos(a),.009,.009,.007,"Or",8)


def face(m, role):
    scale = .106
    height = 1.811
    breadth = {"domestique":.97,"garde":1.025,"intendant":1.0,"roi":.985}[role]
    points, faces, uvs = ANATOMY["head"]
    mesh=[]
    for x,y,z in points:
        neck=max(0.0,min(1.0,(y-5.66)/.72))
        width=min(abs(x),.44+neck*.79)
        refined_x=width if x>=0 else -width
        mesh.append((refined_x*scale*breadth,
                     -(z-.50)*scale*(.62+.38*neck),height+(y-8.491)*scale-.026*(1-neck)))
    m.add(mesh,faces,SKIN[role],"Tete",uvs)
    if role == "domestique":
        points, scalp_faces, _ = ANATOMY["head"]
        faces = []
        for face in scalp_faces:
            middle = [sum(points[index][axis] for index in face)/len(face) for axis in range(3)]
            hairline = 7.47 + max(0.0,middle[2]-.57)*.67 - abs(middle[0])*.21
            if middle[1] > hairline and all(points[index][1] > 7.24 for index in face):
                faces.append(face)
        selected = sorted({index for face in faces for index in face})
        remap = {source: target for target,source in enumerate(selected)}
        points = [points[index] for index in selected]
        faces = [[remap[index] for index in face] for face in faces]
    else:
        points, faces, _ = ANATOMY["hair"]
    hair = [(x*scale*breadth*1.055,-(.49+(z-.50)*1.055-.50)*scale,height+.005+(y-8.491)*scale)
            for x,y,z in points]
    m.add(hair,faces,"Cheveux gris" if role=="intendant" else "Cheveux","Coiffure")
    for side in (-1,1):
        x = side*.308*scale*breadth
        y = height+(7.284-8.491)*scale
        eye_z=(1.245-.50)*scale+.004
        m.oval(x,y,eye_z,.0276,.0276,.0284,"Ivoire",24,"Tete")
        m.oval(x,y,eye_z+.0140,.0101,.0103,.0029,"Iris",18,"Tete")
        m.oval(x,y,eye_z+.0151,.0048,.0052,.0017,"Crinière",12,"Tete")


def hand(m, role, side, part):
    points, faces, uvs = ANATOMY["hand_r" if side > 0 else "hand_l"]
    vertices=[]
    for x,y,z in points:
        dx,dy=abs(x)-3.87,y-2.86
        length=.52*dx-.85*dy
        width=.85*dx+.52*dy
        front=.021+.078*(z-1.36-.70*length)+.021*length**2/(1+length**2)
        vertices.append((side*(.413+.116*width),-front,1.039-.089*length))
    m.add(vertices,faces,SKIN[role],part,uvs)


def legs_and_sleeves(m, cloth, role):
    for side, code in ((-1,"G"),(1,"D")):
        leg, arm = "Jambe"+code, "Bras"+code
        x=side*.141
        loft(m, [(0.16,x,.009,.067,.065),(.27,x,-.012,.075,.069),
                 (.44,x,-.016,.092,.084),(.56,x,.014,.096,.085),
                 (.71,x,.002,.107,.100),(.90,x,-.009,.110,.111)], "Braies", leg, folds=.08)
        loft(m, [(0.13,x,-.005,.084,.077),(.24,x,-.01,.088,.076),
                 (.37,x,-.015,.097,.085),(.46,x,-.018,.097,.088)],
             "Cuir sombre", leg, folds=.068)
        loft(m, [(.028,x,.071,.093,.149),(.051,x,.073,.095,.151),
                 (.090,x,.078,.087,.141),(.125,x,.055,.078,.112),
                 (.18,x,.014,.072,.071)], "Cuir sombre", leg)
        loft(m, [(.023,x,.070,.095,.151),(.057,x,.070,.097,.153)],
             "Semelle", leg, sides=20)
        for y in (.27,.37,.43):
            loft(m, [(y-.011,x,-.016,.099,.091),(y+.011,x,-.016,.098,.091)],
                 "Cuir", leg, sides=18)
            m.box(x+side*.036,y,.074,.022,.021,.010,"Or" if role in ("roi","intendant") else "Fer",part=leg)
        x=side*.319
        cuff = "Or" if role == "roi" else ("Fer" if role == "garde" else "Lin")
        loft(m, [(1.015,x+side*.095,.027,.060,.058),
                 (1.054,x+side*.091,.025,.064,.061),
                 (1.101,x+side*.086,.023,.072,.064),
                 (1.206,x+side*.067,.009,.091,.082),
                 (1.315,x+side*.018,-.005,.100,.089),
                 (1.406,x-side*.023,-.006,.098,.084),(1.451,x-side*.049,-.004,.082,.075),
                 (1.474,x-side*.079,-.006,.056,.062)],
             cloth, arm, sides=28, folds=.13, hem_material=cuff)
        hand(m,role,side,arm)
        if role == "garde":
            for i in range(3):
                m.oval(x+side*(.018+i*.025),1.414-i*.043,.002,
                       .221-i*.015,.113,.207-i*.015,"Acier",14,arm)
            loft(m, [(1.073,x+side*.087,.026,.074,.067),
                     (1.157,x+side*.080,.017,.083,.074)], "Acier",arm,sides=18)


def helmet(m):
    loft(m, [(1.711,0,0,.137,.129),(1.758,0,0,.142,.137),
             (1.807,0,-.007,.128,.127),(1.856,0,-.009,.096,.098),
             (1.893,0,-.017,.042,.049),(1.907,0,-.020,.012,.019)],
         "Acier",sides=32)
    loft(m, [(1.711,0,.004,.138,.132),(1.739,0,.003,.145,.139)], "Fer",sides=32)
    m.beam((0,1.746,.148),(0,1.624,.164),.019,.009,"Acier",10)
    for i in range(12):
        a=i*tau/12
        m.oval(.145*cos(a),1.73,.139*sin(a),.020,.018,.020,"Fer",8)
    for side in (-1,1):
        m.beam((side*.123,1.739,-.032),(side*.121,1.607,-.041),.052,.041,"Maille",10)


def crown(m):
    levels=48
    verts=[]
    for j in range(4):
        for i in range(levels):
            a=i*tau/levels
            x,z=sin(a),cos(a)
            peak=(1-abs((i%6)-3)/3)**1.8
            radius=.117 if j in (0,3) else .134
            y=1.766 if j < 2 else 1.799+.053*peak
            verts.append((x*radius,-z*radius,y))
    faces=[]
    for j in range(4):
        k=(j+1)%4
        faces.extend((j*levels+i,j*levels+(i+1)%levels,
                      k*levels+(i+1)%levels,k*levels+i) for i in range(levels))
    m.add(verts,faces,"Or","Maillage")
    for y in (1.771,1.787):
        loft(m, [(y-.003,0,0,.135,.135),(y+.003,0,0,.136,.136)],"Or",sides=44)
    for i in range(48):
        a=i*tau/48
        m.oval(sin(a)*.136,1.780,cos(a)*.137,.010,.009,.010,"Or mat",8)
    for i in range(8):
        a=(i+.5)*tau/8
        m.oval(sin(a)*.133,1.847,cos(a)*.133,.019,.025,.019,"Or",12)
    for a in (-.85,0,.85,pi):
        m.oval(sin(a)*.136,1.796,cos(a)*.138,.027,.023,.020,
               "Rubis" if a != pi else "Iris",12)


def cloak(m):
    verts=[]
    across, rows=27, 12
    for j in range(rows):
        t=j/(rows-1)
        for i in range(across):
            u=2*i/(across-1)-1
            fold=.035*sin(13*u+.5*t)*(t*.8+.20)
            x=u*(.264+.171*t)
            y=1.428-.958*t+.076*(abs(u)**2)*t
            z=-.128-.18*t+abs(u)**1.45*.109+fold
            verts.append((x,-z,y))
    faces, colors = [], []
    for j in range(rows-1):
        for i in range(across-1):
            faces.append((j*across+i,j*across+i+1,(j+1)*across+i+1,(j+1)*across+i))
            colors.append("Or mat" if i in (1,across-3) or j==rows-2 else "Velours")
    m.add(verts,faces,colors,"Maillage")
    for i in range(16):
        a=pi*i/15
        x,z=cos(a)*.243,-sin(a)*.126
        m.oval(x,1.445-abs(x)*.11,z,.083,.059,.070,"Fourrure",10)
    for x in (-.193,.193):
        m.oval(x,1.385,.109,.052,.045,.019,"Or",14)
    for i in range(14):
        a=i*pi/13
        m.oval(.181*cos(a),1.38-.053*sin(a),.145,.018,.013,.011,"Or",8)


def sword(m):
    a,b=(.234,1.018,-.075),(.365,.316,-.212)
    m.beam(a,b,.044,.029,"Cuir sombre",10)
    m.beam((.345,.374,-.203),(.363,.312,-.215),.036,.025,"Acier",10)
    m.beam((.234,1.034,-.067),(.196,1.234,-.038),.028,.026,"Cuir",10)
    m.beam((.153,1.047,-.052),(.305,1.087,-.075),.018,.016,"Acier",9)
    m.oval(.194,1.251,-.031,.062,.052,.054,"Acier",12)


def make_person(Model, name, material, crowned=False):
    m=Model(name)
    face(m,name)
    if name == "garde":
        coat(m,"Gambison",.79)
        belt(m,1.02)
        helmet(m)
        loft(m, [(1.016,0,.028,.202,.150),(1.157,0,.024,.239,.157),
                 (1.285,0,.023,.253,.156),(1.414,0,.006,.223,.133),
                 (1.464,0,-.008,.122,.103)],"Acier",sides=30)
        for y in (1.042,1.084,1.126):
            loft(m, [(y-.011,0,.021,.225,.167),(y+.009,0,.021,.224,.166)],
                 "Fer",sides=30)
        sword(m)
    elif crowned:
        coat(m,"Velours",.70,.294)
        belt(m,1.04,True)
        cloak(m)
        crown(m)
        for x in (-.037,.037):
            m.beam((x,1.374,.159),(x,.75,.18),.005,.004,"Or mat",8)
            for stitch in range(25):
                y=.77+stitch*.024
                m.beam((x-.004,y,.179),(x+.005,y+.006,.179),.0014,.0014,"Couture",5)
    elif name == "intendant":
        coat(m,"Bordeaux",.74,.291)
        belt(m,1.04,True)
        loft(m, [(1.748,0,-.001,.119,.115),(1.78,0,-.009,.133,.125),
                 (1.822,0,-.011,.135,.131),(1.845,0,-.022,.091,.098),
                 (1.852,0,-.026,.023,.034)],"Bordeaux",sides=30)
        for j in range(6):
            m.oval(0,1.12+j*.048,.166,.032,.034,.019,"Or",10)
        m.beam((-.244,.997,.056),(-.238,.757,.098),.047,.044,"Lin",12)
        m.beam((-.242,.891,.073),(-.243,.862,.081),.049,.049,"Bordeaux",10)
    else:
        coat(m,material,.79)
        belt(m,1.028)
        # A belt apron and a small leather pouch keep the worker’s silhouette practical.
        loft(m, [(.841,.205,.087,.051,.039),(.944,.212,.093,.059,.048),
                 (1.005,.209,.090,.052,.043)],"Cuir",sides=16,folds=.06)
        m.beam((.155,.992,.132),(.241,.985,.132),.012,.010,"Cuir sombre",8)
        apron(m)
    legs_and_sleeves(m,material if not crowned else "Velours",name)
    # Keep head measurements from the anatomical base and tailor the clothing around it.
    width = .74 if name == "garde" else .69
    for part,(vertices,_,_) in m.parts.items():
        if part not in ("Tete","Coiffure"):
            vertices[:] = [(x*width,z*.87,y) for x,z,y in vertices]
    return m
