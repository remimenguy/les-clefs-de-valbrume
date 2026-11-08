"""Generate the editable Valbrume asset library and Godot GLB files in Blender."""
from collections import defaultdict
from math import cos, exp, pi, sin, tau
from pathlib import Path
from random import Random
from runpy import run_path

import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
RNG = Random(1738)
PATHS = run_path(str(ROOT / "art" / "paths.py"))
DETAILS = run_path(str(ROOT / "art" / "architecture.py"))
PALETTE = {
    "Mortier": "#817B6B", "Pierre": "#B2A48B", "Pierre claire": "#CAB99C",
    "Pierre mousse": "#817E63",
    "Cour": "#9B8770", "Dalle": "#AC9C85", "Crépi": "#D0BC9B", "Flamme": "#FFD890",
    "Calcaire": "#A99B84", "Dalle sombre": "#817868", "Dalle claire": "#BAAA90",
    "Dalle olive": "#92917C", "Chemin vallée": "#968773", "Chemin traverse": "#968773",
    "Verre sombre": "#273234", "Ardoise patine": "#4C5554",
    "Pierre ombre": "#9B907C", "Pierre grise": "#A39C8E", "Pavé": "#9F8C72",
    "Ardoise": "#263D46", "Ardoise claire": "#3C5960", "Chêne": "#60402B",
    "Chêne clair": "#A17041", "Fer": "#2E3333", "Or": "#D5A24C",
    "Bordeaux": "#812E3D", "Lin": "#F0DBAF", "Foin": "#C99A43",
    "Feuille": "#52663D", "Feuille claire": "#75874D", "Feuille sombre": "#344F3C",
    "Terre": "#685343", "Herbe": "#798650", "Herbe claire": "#909552",
    "Herbe ombre": "#626E49", "Eau": "#4D8C89", "Écume": "#86AF9D",
    "Roche": "#716E62", "Boue": "#574C3A",
    "Écorce": "#5B4B3C", "Chêne feuillage": "#527043", "Chêne pousses": "#6D804B",
    "Chêne ombre": "#3B5639", "Chêne or": "#857848",
    "Argile": "#A5573C", "Peau": "#C78859", "Marron": "#865138",
    "Crinière": "#302420", "Beurre": "#FFB956", "Tunique": "#43676C",
    "Cuir": "#593B30", "Pomme": "#C25C42", "Légume": "#BA6734",
    "Cuir sombre": "#35281E", "Semelle": "#24211B", "Braies": "#52473E",
    "Couture": "#B4A181", "Toile": "#716045", "Fourrure": "#DACDB2",
    "Lèvres": "#8F5649", "Peau ombre": "#9D634D", "Ivoire": "#DED8C5", "Iris": "#4C5040",
    "Barbe grise": "#7E7268", "Acier": "#777D80", "Maille": "#5B6264",
    "Visage jeune": "#BF947D", "Visage mûr": "#AE826A", "Visage garde": "#79543E",
    "Cheveux": "#2C221B", "Cheveux gris": "#686058",
    "Rubis": "#9E192C", "Velours": "#762536", "Gambison": "#55463E", "Or mat": "#B58748",
}


def srgb(value):
    value /= 255
    return value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4


def material(name, code):
    mat = bpy.data.materials.new(name)
    color = tuple(srgb(int(code[i:i + 2], 16)) for i in (1, 3, 5)) + (1,)
    mat.diffuse_color = color
    mat.use_nodes = True
    shader = next(node for node in mat.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = .78
    if name in ("Fer", "Or", "Acier", "Maille", "Or mat"):
        shader.inputs["Metallic"].default_value = .68
        shader.inputs["Roughness"].default_value = .48 if name == "Acier" else .55
    if name == "Verre sombre":
        shader.inputs["Roughness"].default_value = .23
    if name == "Flamme":
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = 2.2
    return mat


def axis(x, y, z):
    return (x, -z, y)


class Model:
    def __init__(self, name):
        self.name = name
        self.parts = defaultdict(lambda: ([], [], []))
        self.uvs = defaultdict(dict)

    def add(self, vertices, faces, mat, part, uvs=None):
        verts, polys, colors = self.parts[part]
        offset = len(verts)
        if uvs is not None:
            self.uvs[part].update(enumerate(uvs, len(polys)))
        verts.extend(vertices)
        polys.extend(tuple(i + offset for i in face) for face in faces)
        colors.extend([mat] * len(faces) if isinstance(mat, str) else mat)

    def box(self, x, y, z, w, h, d, mat, angle=0, part="Maillage"):
        cx, sx = cos(angle), sin(angle)
        corners = [(-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1),
                   (-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1)]
        vertices = [axis(x + a*w/2*cx + c*d/2*sx, y + b*h/2, z - a*w/2*sx + c*d/2*cx)
                    for a, b, c in corners]
        self.add(vertices, [(0,1,2,3), (7,6,5,4), (0,4,5,1),
                            (1,5,6,2), (2,6,7,3), (3,7,4,0)], mat, part)

    def cone(self, x, y, z, bottom, top, height, mat, n=12, part="Maillage"):
        self.beam((x, y-height/2, z), (x, y+height/2, z), bottom, top, mat, n, part)

    def beam(self, a, b, bottom, top, mat, n=10, part="Maillage"):
        start, end = Vector(axis(*a)), Vector(axis(*b))
        basis = Vector((0, 0, 1)).rotation_difference((end-start).normalized())
        # The tip ring uses a tiny radius to preserve a closed mesh without zero-area faces.
        radii = (max(bottom, .0005), max(top, .0005))
        verts = [point + basis @ Vector((r*cos(tau*i/n), r*sin(tau*i/n), 0))
                 for point, r in zip((start, end), radii) for i in range(n)]
        faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
        faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
        self.add(verts, faces, mat, part)

    def oval(self, x, y, z, w, h, d, mat, n=16, part="Maillage"):
        rings = 10
        vertices = [axis(x, y-h/2, z)]
        for j in range(1, rings):
            latitude = -pi/2 + j*pi/rings
            for i in range(n):
                t = tau*i/n
                vertices.append(axis(x+w/2*cos(latitude)*cos(t), y+h/2*sin(latitude),
                                     z-d/2*cos(latitude)*sin(t)))
        vertices.append(axis(x, y+h/2, z))
        faces = [(0, 1+(i+1)%n, 1+i) for i in range(n)]
        for j in range(rings-2):
            a = 1+j*n
            faces.extend((a+i, a+(i+1)%n, a+n+(i+1)%n, a+n+i) for i in range(n))
        faces.extend((len(vertices)-1, len(vertices)-1-n+i, len(vertices)-1-n+(i+1)%n)
                     for i in range(n))
        self.add(vertices, faces, mat, part)

    def partition(self, part, size):
        if part not in self.parts:
            return
        verts, faces, colors = self.parts.pop(part)
        cells = {}
        for face, color in zip(faces, colors):
            center = sum((Vector(verts[index]) for index in face), Vector())/len(face)
            key = (int((center.x+72)//size), int((center.y+72)//size))
            indices = cells.setdefault(key, {})
            out, polygons, materials = self.parts[f"{part}_{key[0]}_{key[1]}"]
            for index in face:
                if index not in indices:
                    indices[index] = len(out)
                    out.append(verts[index])
            polygons.append(tuple(indices[index] for index in face))
            materials.append(color)

    def finish(self, library):
        collection = bpy.data.collections.new(self.name)
        library.collection.children.link(collection)
        for label, (verts, faces, colors) in self.parts.items():
            mesh = bpy.data.meshes.new(self.name + " " + label)
            mesh.from_pydata(verts, [], faces)
            mesh.validate()
            if len(mesh.polygons) != len(colors):
                raise ValueError(f"{self.name}/{label}: material assignments no longer match faces")
            mesh.update()
            if label in self.uvs:
                uv_layer = mesh.uv_layers.new()
                for poly_index, coordinates in self.uvs[label].items():
                    for loop, uv in zip(mesh.polygons[poly_index].loop_indices, coordinates):
                        uv_layer.data[loop].uv = uv
            slots = {color: index for index, color in enumerate(dict.fromkeys(colors))}
            for color in slots:
                mesh.materials.append(MATERIALS[color])
            for polygon, color in zip(mesh.polygons, colors):
                polygon.material_index = slots[color]
                if label == "Relief" or self.name in {"poule", "cheval", "domestique", "roi", "garde", "intendant"}:
                    polygon.use_smooth = len(polygon.vertices) <= 4
            obj = bpy.data.objects.new(self.name + "_" + label, mesh)
            collection.objects.link(obj)
        bpy.ops.export_scene.gltf(
            filepath=str(ROOT / "assets" / (self.name + ".glb")),
            export_format="GLB", collection=collection.name, export_apply=True,
        )
        return collection


def ashlar(m, x, y, z, width, height, depth, mat, angle=0):
    """A bevelled block with worn corners and its visible faces proud of the mortar."""
    chamfer=min(.022, width*.16, height*.13)
    hx,hy=width/2,height/2
    ring=[(-hx+chamfer,-hy),(hx-chamfer,-hy),(hx,-hy+chamfer),(hx,hy-chamfer),
          (hx-chamfer,hy),(-hx+chamfer,hy),(-hx,hy-chamfer),(-hx,-hy+chamfer)]
    c,s=cos(angle),sin(angle)
    verts=[]
    for offset, scale in [(-depth/2,.965),(0,1),(depth/2,.965)]:
        for u,v in ring:
            ux=u*scale+RNG.uniform(-.0038,.0038)
            vy=v*scale+RNG.uniform(-.0032,.0032)
            verts.append(axis(x+c*ux+s*offset,y+vy,z-s*ux+c*offset))
    faces=[tuple(reversed(range(8))),tuple(range(16,24))]
    for row in range(2):
        lo,hi=row*8,(row+1)*8
        faces.extend((lo+i,lo+(i+1)%8,hi+(i+1)%8,hi+i) for i in range(8))
    m.add(verts,faces,mat,"Maconnerie")



STONE = ["Pierre", "Pierre ombre", "Pierre claire", "Pierre grise", "Pierre"]


def wall(m, x, z, length, height, rotate=False, top=True):
    def at(u):
        return (x, z+u) if rotate else (x+u, z)
    def block(u, y, width, h, depth, material):
        px, pz = at(u)
        m.box(px, y, pz, width, h, depth, material, pi/2 if rotate else 0)
    block(0, height/2, length, height, .9, "Mortier")
    rows = round(height/.333)
    step = height/rows
    for row in range(rows):
        start = -length/2
        while start < length/2-.01:
            width = min(length/2-start, (.43 if row%2 else .73) if start==-length/2
                        else RNG.uniform(.52,.94))
            if width>.034:
                px,pz=at(start+width/2)
                color="Pierre mousse" if row<3 and RNG.random()<.19 else RNG.choice(STONE)
                ashlar(m,px,(row+.5)*step,pz,max(.032,width-.018),step-.019,
                       RNG.uniform(.982,1.043),color,pi/2 if rotate else 0)

            start += width
    if top:
        block(0, height+.07, length, .21, 1.24, "Pierre claire")
        for index in range(int(length/1.6)):
            u = -length/2 + .8 + index*1.6
            block(u, height+.46, .84, .63, 1.03, "Pierre")
            block(u, height+.81, .91, .1, 1.12, "Pierre claire")


def tower(m, x, z, radius, height, roof):
    m.cone(x, height/2, z, radius, radius*.96, height, "Mortier", 16)
    rows=round(height/.326)
    step=height/rows
    for row in range(rows):
        for i in range(23):
            a=tau*(i+(row%2)*.5)/23
            m.box(x+radius*.967*cos(a),(row+.5)*step,z+radius*.967*sin(a),
                  radius*.268-.014,step-.019,RNG.uniform(.196,.241),
                  RNG.choice(STONE),-a-pi/2,part="Maconnerie")
    for y, r, h in [(.22, radius*1.06, .4), (height-.72, radius*1.045, .17), (height-.25, radius*1.07, .20)]:
        m.cone(x, y, z, r, r, h, "Pierre claire", 16)
    for i in range(8):
        a = tau*i/8
        m.box(x+radius*.9*cos(a), height+.23, z+radius*.9*sin(a),
              .7, .67, .47, "Pierre", -a-pi/2)
    if roof:
        m.cone(x, height+1.56, z, radius*1.07, .1, 3.3, "Ardoise", 12)
        m.cone(x, height+.03, z, radius*1.1, radius*1.1, .16, "Ardoise claire", 12)
        m.cone(x, height+3.36, z, .105, .025, .46, "Or", 8)
    for angle in (0, pi/2, pi, -pi/2):
        m.box(x+radius*.995*sin(angle), height*.69, z+radius*.995*cos(angle), .15, .88, .12,
              "Fer", angle)


def gable(m, x, z, width, depth, base, rise):
    vertices = [axis(x-width/2, base, z-depth/2), axis(x+width/2, base, z-depth/2),
                axis(x, base+rise, z-depth/2), axis(x-width/2, base, z+depth/2),
                axis(x+width/2, base, z+depth/2), axis(x, base+rise, z+depth/2)]
    m.add(vertices, [(2,1,0), (3,4,5), (0,1,4,3), (0,3,5,2), (1,2,5,4)], "Ardoise", "Maillage")
    for end in (z-depth/2, z+depth/2):
        for sign in (-1, 1):
            m.beam((x+sign*width/2, base, end), (x, base+rise, end), .08, .07, "Ardoise claire", 6)
    m.beam((x, base+rise, z-depth/2), (x, base+rise, z+depth/2), .085, .085, "Ardoise claire", 8)
    DETAILS["tile_roof"](m, RNG, x, z, width, depth, base, rise)


def banner(m, x, y, z, w=.9, height=1.6):
    m.beam((x-w*.63, y, z), (x+w*.63, y, z), .044, .044, "Chêne", 8)
    v = [axis(x-w/2, y, z), axis(x+w/2, y, z), axis(x+w/2, y-height*.76, z+.035),
         axis(x, y-height, z+.075), axis(x-w/2, y-height*.76, z+.035)]
    m.add(v, [(0,1,2,3,4)], "Bordeaux", "Maillage")
    for dx in (-.25, .25):
        m.box(x+w*dx, y-height*.38, z+.055, .028, height*.65, .018, "Or")
    m.box(x, y-height*.41, z+.074, w*.25, .07, .02, "Or")
    m.box(x, y-height*.40, z+.076, .07, .27, .024, "Or")


def barrel(m, x, z, size=1, y=0):
    m.cone(x, y+size*.24, z, size*.31, size*.38, size*.48, "Chêne clair")
    m.cone(x, y+size*.65, z, size*.38, size*.30, size*.34, "Chêne clair")
    for h, r in [(.12,.34), (.42,.38), (.72,.334)]:
        m.cone(x, y+h*size, z, r*size, r*size, .055*size, "Fer")


def arch(m, x, z, center_y, inner, thick, depth):
    for index in range(17):
        a, b = pi*index/17+.005, pi*(index+1)/17-.005
        v = [axis(x+cos(t)*r, center_y+sin(t)*r, z+side*depth/2)
             for side in (-1, 1) for r, t in [(inner,a), (inner+thick,a), (inner+thick,b), (inner,b)]]
        m.add(v, [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],
              "Pierre claire" if index == 8 else RNG.choice(STONE), "Maillage")


def fence(m, x1, z1, x2, z2):
    length = ((x2-x1)**2+(z2-z1)**2)**.5
    count = max(1, round(length/1.8))
    for i in range(count+1):
        t = i/count
        x, z = x1+(x2-x1)*t, z1+(z2-z1)*t
        m.box(x, .54, z, .18, 1.08, .18, "Chêne clair")
        m.cone(x, 1.12, z, .133, .03, .16, "Chêne", 4)
    for y in (.4, .8):
        m.beam((x1, y, z1), (x2, y, z2), .07, .07, "Chêne", 4)


def house(m, x, z, w, d, h):
    m.box(x, h/2, z, w, h, d, "Crépi")
    DETAILS["timber_house"](m, x, z, w, d, h)
    gable(m, x, z, w+1, d+1, h, w*.41)


def castle():
    m = Model("chateau")
    wall(m, 0, -22, 44, 5.2)
    for x in (-22, 22):
        wall(m, x, 0, 44, 5.2, True)
        wall(m, x*.56, 22, 19.4, 5.2)
        for z in (-22, 22):
            tower(m, x, z, 2.6, 7.8, True)
    for x in (-4.35, 4.35):
        tower(m, x, 22, 1.92, 7.9, False)
        banner(m, x, 6.7, 24.05, .95, 2.05)
        banner(m, x, 6.7, 19.95, .95, 2.05)
    m.box(0, 6.43, 22, 7.0, 1.27, 1.45, "Pierre")
    for x in (-2.5, 2.5):
        m.box(x, 1.65, 22, .61, 3.3, 1.48, "Pierre claire")
    arch(m, 0, 22, 3.22, 2.20, .64, 1.58)
    banner(m, 0, 7.01, 22.82, 1.2, 1.36)
    m.box(0, .04, 0, 43.0, .08, 43, "Cour")
    PATHS["court_paths"](m, RNG)
    # Le logis and its open audience hall.
    wall(m, 0, -19.4, 16.6, 5.6, top=False)
    for x in (-8, 8):
        wall(m, x, -16.2, 6.0, 5.6, True, top=False)
    m.box(0,.12,-16,16.5,.23,7.3,"Pierre claire")
    m.box(0,.252,-16,4.1,.025,6.5,"Bordeaux")
    for x in (-2.0,2.0):
        m.box(x,.27,-16,.058,.018,6.5,"Or")
    for x in (-6.0, 6.0):
        tower(m, x, -20, 1.75, 8.7, True)
    m.box(0, 6.3, -19.3, 8.6, 2.2, 3.6, "Pierre")
    gable(m, 0, -19.3, 9.7, 4.1, 7.25, 2.8)
    for x in (-5,0,5):
        banner(m, x, 5.23, -18.83, 1.24, 2.55)
    for x in (-7.3, 7.3):
        m.box(x, 2.44, -13.45, .8, 4.86, .8, "Pierre")
        m.box(x, .18, -13.45, 1.13, .36, 1.04, "Pierre claire")
        m.box(x, 4.76, -13.45, 1.1, .3, .98, "Pierre claire")
    DETAILS["hall"](m)
    # Throne, platform and council table.
    m.box(0,.36,-17.67,3.8,.27,2.8,"Pierre claire")
    m.box(0,.57,-18.05,2.9,.20,1.9,"Pierre")
    DETAILS["throne"](m)
    m.box(-3.9, 1.02, -13.65, 3.0, .13, 1.17, "Chêne")
    for x in (-5.1,-2.7):
        m.box(x,.55,-13.65,.2,.95,.85,"Chêne clair")
    for x in (-4.75,-3.9,-3.05):
        m.cone(x,1.12,-13.58,.17,.21,.07,"Lin",10)
    # Well, with canopy.
    for i in range(14):
        a = tau*i/14
        for j in range(3):
            b = a+(j%2)*pi/14
            m.box(cos(b)*.81,.15+j*.23,3+sin(b)*.81,.36,.21,.32,RNG.choice(STONE),-b-pi/2)
    m.cone(0,.22,3,.65,.65,.04,"Eau")
    for x in (-.97,.97):
        m.box(x,1.45,3,.14,2.9,.17,"Chêne")
    gable(m,0,3,2.55,2.15,2.58,.73)
    m.beam((-.95,1.91,3),(.95,1.91,3),.07,.07,"Chêne clair")
    m.beam((0,1.91,3),(0,.78,3),.019,.019,"Lin")
    barrel(m,.22,3.14,.36,.57)
    # Kitchen, store and stalls.
    house(m,-13,-15.0,5.4,4.1,3.7)
    house(m, 13,-16.2,5.7,4.5,3.6)
    banner(m,13,3.25,-13.87,.62,1.18)
    for x in (-16,-10):
        m.box(x,1.36,-11.94,.17,2.68,.18,"Chêne")
    m.box(-13,2.63,-11.94,6.3,.14,2.14,"Ardoise claire")
    for x in (-15.2,-14.4,-12.2):
        barrel(m,x,-12.27,.75)
    m.box(-12.5,.81,-12.05,2.2,.13,.65,"Chêne")
    for x in (-13.31,-11.69):
        m.box(x,.42,-12.05,.15,.83,.50,"Chêne")
    for x in (-12.87,-12.28,-11.98):
        m.oval(x, .98, -12.05, .34,.24,.28, "Foin", 10)
    for x in (-14.8,-14.4,-14,-13.6,-13.2):
        m.beam((x,.24,-5.15),(x,.24,-4.05),.17,.19,"Chêne clair",8)
    for x in (-14.6,-14.2,-13.8,-13.4):
        m.beam((x,.55,-5.1),(x,.55,-4.0),.15,.16,"Chêne",8)
    for x,z in ((11.6,13.9),(12.6,14.1),(10.7,14.3),(19,10),(19.8,10.4)):
        barrel(m,x,z,RNG.uniform(.69,1.0))
    for x,z in ((12,12.5),(12.6,12.72),(11.5,12.94)):
        m.oval(x,.38,z,.73,.69,.68,"Lin",10)
        m.cone(x,.73,z,.12,.10,.12,"Chêne clair",8)
    for x,z in ((14,-2.0),(14.94,-2.3),(15.64,-2.6)):
        m.box(x,.37,z,.88,.59,.82,"Foin",.13)
        for dx in (-.21,.21):
            m.box(x+dx,.675,z,.045,.035,.80,"Chêne clair")
    for x in (13.2,19.6):
        for z in (-10.5,-5.4):
            m.box(x,1.57,z,.23,3.14,.23,"Chêne")
    m.box(16.4,3.07,-8,7.1,.19,6.1,"Ardoise")
    m.box(16.4,2.88,-8,7.4,.22,5.9,"Chêne")
    fence(m,13.2,-10.5,19.6,-10.5)
    fence(m,19.6,-10.5,19.6,-5.4)
    m.box(18.8,.51,-8.36,.62,.39,2.25,"Chêne")
    m.box(18.8,.71,-8.36,.48,.04,2.11,"Foin")
    house(m,18.8,5.15,2.6,2.1,1.58)
    fence(m,13.0,2.0,19.9,2.0)
    fence(m,19.9,2.0,19.9,8.5)
    fence(m,19.9,8.5,13.0,8.5)
    fence(m,13.0,8.5,13.0,6.4)
    m.box(16.2,.20,5.37,1.18,.22,.48,"Chêne")
    m.box(16.2,.322,5.37,1.03,.04,.32,"Foin")
    # Kitchen garden beds and clipped hedge borders.
    for x in (-17,-14,-11):
        m.box(x,.15,5.15,1.65,.16,5.3,"Terre")
        for dx in (-.83,.83):
            m.box(x+dx,.24,5.15,.14,.25,5.45,"Chêne")
        for j in range(8):
            for dx in (-.36,.37):
                z = 2.9+j*.63
                DETAILS["vegetables"](m, RNG, x+dx, z, 0 if x == -14 else 1)
    for x in (-20,20):
        for i in range(5):
            m.oval(x,.46,11+i*1.56,1.52,.91,1.62,"Feuille sombre",9)
    lantern(m, -13.5, 2.4, -11.83)
    lantern(m, -5.5, 3.0, -18.57)
    lantern(m, 5.5, 3.0, -18.57)
    for x in (-2.46, 2.46):
        lantern(m, x, 2.5, 21.16)
    for x, z in ((-19.4, -12), (19.1, 12), (-18, -10), (-13, 11.7)):
        barrel(m, x, z, RNG.uniform(.66, .95))
    for x in (-8.5, 8.5):
        for z in (-3.3, 11.5):
            DETAILS["bench"](m, x, z)
    for x,z in ((-17.1,-12.8),(-17.4,-13.3),(10.8,13.7),(19.6,11.3),(14.8,-13.1),(19.6,-13.7)):
        DETAILS["crate"](m, x, z, RNG.uniform(.72,.98))
    for part in ("Maconnerie", "Chemins_cour", "Couvertures_ardoise"):
        m.partition(part, 14)
    return m


def lantern(m, x, y, z):
    m.beam((x,y+.31,z-.18),(x,y+.31,z),.036,.036,"Fer",8)
    m.beam((x,y+.30,z),(x,y+.19,z),.025,.025,"Fer",8)
    for h, radius, crown in [(-.15,.164,.163),(.17,.168,.168),(.23,.178,.036)]:
        m.cone(x,y+h,z,radius,crown,.094 if h==.23 else .062,"Fer",8)
    for i in range(8):
        angle = i*tau/8
        m.beam((x+.151*cos(angle),y-.15,z+.151*sin(angle)),
               (x+.151*cos(angle),y+.19,z+.151*sin(angle)),.013,.013,"Fer",6)
    m.oval(x,y-.031,z,.133,.226,.135,"Flamme",10)
    m.cone(x,y-.10,z,.083,.065,.098,"Lin",10)


def highlands(m):
    # Continuous, irregular slopes outside the playable field and below the path.
    width, depth, step = 440, 420, 5
    cols, rows = width//step + 1, depth//step + 1
    hills = [(-48,-37,20,14),(-35,-46,14,19),(42,-50,21,24),(74,-54,16,22),
             (-75,62,18,23),(75,70,23,25),(-43,101,23,24),(46,112,29,31),
             (-126,0,28,40),(123,18,28,37),(-102,115,28,37),(109,130,32,45),
             (-110,-100,36,45),(20,-120,37,45),(99,-119,42,47)]
    vertices = []
    for row in range(rows):
        z = row*step-depth/2+21
        for col in range(cols):
            x = col*step-width/2
            height = -.52
            for cx,cz,r,h in hills:
                distance = ((x-cx)**2 + (z-cz)**2)**.5
                if distance < r*1.28:
                    distance /= r*1.28
                    falloff = (exp(-5.8*distance**2)-exp(-5.8))/(1-exp(-5.8))
                    height += h*falloff
            if height > -.40:
                height += (sin(x*.36)*cos(z*.22)+sin(z*.73)*.33)*min(.83,max(0,height*.18))
            vertices.append(axis(x,height,z))
    faces = [(row*cols+col,(row+1)*cols+col,(row+1)*cols+col+1,row*cols+col+1)
             for row in range(rows-1) for col in range(cols-1)]
    m.add(vertices,faces,"Roche","Relief")


def valley():
    m = Model("vallee")
    highlands(m)
    m.box(0,-.22,17,294,.44,280,"Herbe")
    for _ in range(550):
        x,z = RNG.uniform(-70,70),RNG.uniform(-40,88)
        if (abs(x)<24 and -24<z<24) or 26<z<34 or (abs(x)<5 and 22<z<86) or (abs(z-47)<4 and abs(x)<30):
            continue
        m.oval(x,-.015,z,RNG.uniform(.4,3.0),.044,RNG.uniform(.35,2.35),
               RNG.choice(["Herbe claire","Herbe ombre","Herbe"]),7)
    # Gravel road, river and oak bridge.
    PATHS["valley_paths"](m, RNG)
    m.box(0,.085,29.9,155,.15,7.4,"Eau")
    for i in range(21):
        m.box(0,.163,25+i*.49,4.18,.13,.477,RNG.choice(["Chêne","Chêne clair","Chêne clair"]))
    for x in (-1.96,1.96):
        m.box(x,.73,29.9,.135,.12,10.4,"Chêne")
        for i in range(6):
            m.box(x,.51,25+i*1.98,.20,.85,.20,"Chêne clair")
    DETAILS["bridge"](m)
    for x,z,w,d,h in ((-19,52,6.0,4.8,3.3),(-28,46,5.6,4.3,3),(-15,42.5,4.9,4.1,3),
                      (-25,56.5,4.1,3.7,2.75)):
        house(m,x,z,w,d,h)
        barrel(m,x+w*.39,z+d*.66,.74)
        DETAILS["crate"](m,x-w*.35,z+d*.68,.94)
    fence(m,-30,50,-23,50)
    fence(m,-29,40,-21,40)
    for x,z in ((17.3,51),(24.4,51)):
        tower(m,x,z,1.28,4.15,False)
    wall(m,20.85,53,7.1,3.55,top=False)
    arch(m,20.85,50.9,2.25,2.2,.43,.65)
    for x in (18.35,23.35):
        m.box(x,1.10,50.9,.61,2.2,.73,"Pierre")
    for _ in range(43):
        x,z=RNG.uniform(14,29),RNG.uniform(47,55)
        m.box(x,.18,z,RNG.uniform(.3,.7),RNG.uniform(.18,.39),.47,RNG.choice(STONE),RNG.random())
    return m


def gate():
    m=Model("herse")
    for i in range(-6,7):
        x=i*.342
        m.box(x,2.07,0,.11,4.15,.14,"Fer")
        m.cone(x,.10,0,.01,.096,.20,"Fer",6)
    for y in (.69,1.73,2.74,3.78):
        m.box(0,y,0,4.45,.14,.19,"Fer")
        for i in range(-6,7):
            m.oval(i*.342,y,.104,.092,.092,.067,"Or",8)
    return m


def chicken():
    m=Model("poule")
    m.oval(0,.36,0,.40,.44,.59,"Lin")
    m.oval(0,.59,.20,.26,.40,.30,"Lin")
    m.oval(0,.76,.26,.235,.24,.26,"Lin")
    m.beam((0,.725,.34),(0,.702,.49),.084,.012,"Foin",6)
    for i in range(5):
        m.oval(0,.843+.03*sin(i*pi/4),.16+.033*i,.053,.100+.038*sin(i*pi/4),.047,"Bordeaux",10)
    for side in (-1,1):
        for row in range(3):
            for i in range(5):
                m.beam((side*(.16+.016*row),.46-row*.066,.13-i*.053),
                       (side*(.20-.017*row),.37-row*.049,-.031-i*.064),
                       .043,.020,"Lin" if (row+i)%3 else "Pierre claire",9)
        for z in (.071,.103,.13):
            m.beam((side*.115,.047,.027),(side*.115+(z-.10)*.88,.034,z),
                   .012,.007,"Légume",8)
    m.oval(0,.654,.342,.076,.138,.07,"Bordeaux",8)
    for x in (-.118,.118):
        m.oval(x,.789,.293,.047,.055,.057,"Fer",8)
        m.oval(x*1.47,.39,-.055,.13,.25,.38,"Pierre claire",9)
        m.beam((x,.26,0),(x,.058,.016),.026,.024,"Légume",7)
        m.beam((x,.051,.012),(x,.037,.131),.025,.018,"Légume",7)
    for x,z in ((-.08,-.44),(0,-.53),(.08,-.47)):
        m.beam((x,.35,-.16),(x,.68,z),.095,.018,"Lin",7)
    return m


def horse():
    m=Model("cheval")
    m.oval(0,1.16,-.11,.71,.86,1.82,"Marron")
    m.oval(0,1.20,-.77,.76,.89,.66,"Marron")
    m.oval(0,1.24,.54,.60,.87,.57,"Marron")
    m.beam((0,1.32,.47),(0,1.99,.82),.37,.19,"Marron",10)
    m.oval(0,1.96,1.00,.38,.50,.61,"Marron")
    m.oval(0,1.78,1.31,.34,.29,.43,"Crinière")
    m.oval(0,1.81,1.459,.217,.145,.160,"Peau ombre",14)
    m.beam((0,2.041,1.16),(0,1.932,1.40),.048,.026,"Lin",12)
    for side in (-1,1):
        m.oval(side*.094,1.822,1.499,.058,.047,.035,"Crinière",12)
        m.beam((side*.169,2.013,1.03),(side*.177,1.764,1.34),.021,.018,"Cuir sombre",9)
        m.oval(side*.184,1.758,1.374,.038,.051,.039,"Or mat",10)
        m.beam((side*.193,1.756,1.368),(side*.36,1.54,.38),.016,.014,"Cuir",8)
    for index in range(12):
        t=index/11
        m.beam((.013*cos(index),2.22-.72*t,.76-.57*t),
               (.14+.076*cos(index*1.7),2.02-.67*t,.71-.56*t),
               .045,.014,"Crinière",8)
        m.beam((.036*cos(index),1.36,-1.00),(.124*sin(index),.52+.19*t,-1.30-.13*cos(index)),
               .047,.018,"Crinière",8)
    m.beam((-.178,1.783,1.30),(.178,1.783,1.30),.023,.023,"Cuir sombre",10)
    m.beam((0,1.53,.36),(0,2.12,.75),.17,.12,"Crinière",8)
    m.beam((0,1.34,-.99),(0,.62,-1.29),.16,.09,"Crinière",8)
    for x in (-.21,.21):
        for z in (-.76,.55):
            m.beam((x,1.15,z),(x,.48,z-.052),.135,.074,"Marron",9)
            m.beam((x,.48,z-.052),(x,.105,z+.04),.075,.06,"Marron",8)
            m.cone(x,.09,z+.055,.091,.077,.16,"Crinière",8)
        m.oval(x*.79,2.022,1.118,.066,.069,.076,"Crinière",8)
        m.beam((x*.60,2.13,.93),(x*.78,2.37,.95),.076,.008,"Marron",8)
    return m


def oak():
    m = Model("chene")
    crown_colors = ("Chêne feuillage", "Chêne feuillage", "Chêne ombre",
                    "Chêne pousses", "Chêne pousses", "Chêne or")
    m.beam((0,0,0),(.05,1.45,-.09),.43,.26,"Écorce",10)
    m.beam((.05,1.44,-.09),(-.10,3.08,.10),.27,.14,"Écorce",10)
    m.beam((-.10,3.07,.10),(.21,4.83,.17),.15,.065,"Écorce",9)
    m.beam((.21,4.79,.17),(.06,5.77,-.25),.066,.008,"Écorce",8)
    for i in range(7):
        t=tau*i/7+.31
        m.beam((cos(t)*.68,.014,sin(t)*.68),(0,.34,0),.035,.22,"Écorce",8)
    centers = [(.08,5.63,-.24,1.42),(-.84,5.20,.71,1.08),(.95,5.19,-.48,1.11)]
    for i in range(8):
        angle=tau*i/8+RNG.uniform(-.28,.28)
        start_y=RNG.uniform(2.05,3.94)
        height=RNG.uniform(3.92,5.38)
        reach=RNG.uniform(1.4,2.18)
        dx,dz=cos(angle),sin(angle)
        mid=(dx*reach*.57,height-.37,dz*reach*.57)
        end=(dx*reach,height,dz*reach)
        m.beam((0,start_y,0),mid,.126,.063,"Écorce",8)
        m.beam(mid,end,.065,.012,"Écorce",8)
        for spread in (-.72,.49):
            a=angle+spread
            tip=(end[0]+cos(a)*.46,height+.28,end[2]+sin(a)*.48)
            m.beam(mid,tip,.043,.008,"Écorce",7)
        centers.append((*end,RNG.uniform(.92,1.32)))
    for x,y,z,r in centers:
        for _ in range(345):
            while True:
                dx,dy,dz=(RNG.uniform(-1,1) for _ in range(3))
                if dx*dx+dy*dy+dz*dz <= 1:
                    break
            px,py,pz=x+dx*r,y+dy*r*.66,z+dz*r
            length=RNG.uniform(.105,.230)
            width=length*RNG.uniform(.34,.56)
            a=RNG.uniform(0,tau)
            pitch=RNG.uniform(-.92,.92)
            along=(cos(a)*length*cos(pitch),length*sin(pitch),sin(a)*length*cos(pitch))
            cross=(-sin(a)*width,width*RNG.uniform(-.66,.66),cos(a)*width)
            verts=[axis(px-along[0],py-along[1],pz-along[2]),
                   axis(px+cross[0],py+cross[1],pz+cross[2]),
                   axis(px+along[0],py+along[1],pz+along[2]),
                   axis(px-cross[0],py-cross[1],pz-cross[2]),
                   axis(px,py+.015,pz)]
            m.add(verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],RNG.choice(crown_colors),"Maillage")
    return m



def cargo():
    m = Model("charge")
    m.oval(0,.006,0,.36,.42,.30,"Lin",16,"grain")
    m.cone(0,.20,0,.053,.066,.07,"Chêne clair",10,"grain")
    m.box(0,0,0,.48,.28,.34,"Foin",part="foin")
    for x in (-.13,.13):
        m.box(x,0,0,.026,.29,.35,"Chêne clair",part="foin")
    for i in range(34):
        x,z = RNG.uniform(-.23,.23), RNG.uniform(-.167,.167)
        m.beam((x,.14,z),(x+RNG.uniform(-.052,.052),.17,z),.005,.002,"Foin",5,"foin")
    m.cone(0,0,0,.116,.162,.28,"Chêne clair",14,"puits")
    for height,radius in [(-.115,.128),(.113,.163)]:
        m.cone(0,height,0,radius,radius,.023,"Fer",14,"puits")
    for index in range(9):
        a,b = pi*index/9,pi*(index+1)/9
        m.beam((cos(a)*.16,.11+sin(a)*.16,0),(cos(b)*.16,.11+sin(b)*.16,0),.012,.012,"Fer",6,"puits")
    for x,y in [(-.076,-.055),(.076,-.055),(0,.075)]:
        m.beam((x,y,-.20),(x,y,.20),.067,.059,"Chêne",10,"bois")
        m.beam((x,y,.200),(x,y,.204),.051,.051,"Chêne clair",10,"bois")
    m.oval(0,0,0,.41,.18,.27,"Foin",20,"pain")
    for x in (-.10,0,.10):
        m.box(x,.082,0,.017,.017,.115,"Chêne clair",.52,"pain")
    m.box(0,0,0,.21,.035,.28,"Lin",.12,"sceau")
    m.cone(.055,.023,.06,.056,.052,.025,"Bordeaux",14,"sceau")
    m.cone(.055,.041,.06,.030,.027,.009,"Or",12,"sceau")
    return m



def pack_preview_materials():
    """Keep the editable Blender file self-contained after exporting runtime meshes."""
    groups = [
        ("rock_surface", .68, ("Mortier","Pierre","Pierre claire","Pierre ombre","Pierre grise","Pierre mousse",
                               "Calcaire","Dalle sombre","Dalle claire","Dalle olive","Roche")),
        ("wood_planks_grey", .88, ("Chêne","Chêne clair")),
        ("roof_slates_03", .46, ("Ardoise","Ardoise claire","Ardoise patine")),
        ("white_rough_plaster", .64, ("Crépi",)),
        ("stony_dirt_path", .43, ("Cour","Pavé","Chemin vallée","Chemin traverse")),
        ("grass_ground", .42, ("Herbe","Herbe claire","Herbe ombre")),
        ("pine_bark", 1.1, ("Écorce",)),
        ("valbrume_laine", 7.2, ("Lin","Tunique","Bordeaux","Velours","Gambison","Braies","Toile")),
        ("fabric_leather_01", 4.3, ("Cuir","Cuir sombre","Semelle")),
        ("valbrume_maille", 7.2, ("Maille",)),
    ]
    for texture, frequency, names in groups:
        diffuse = bpy.data.images.load(str(ROOT/"assets"/"textures"/(texture+"_albedo.jpg")),check_existing=True)
        diffuse.pack()
        for name in names:
            mat = MATERIALS[name]
            nodes, links = mat.node_tree.nodes, mat.node_tree.links
            shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
            coords = nodes.new("ShaderNodeTexCoord")
            coords.location = (-690,100)
            scale = nodes.new("ShaderNodeVectorMath")
            scale.operation = "SCALE"
            scale.inputs["Scale"].default_value = frequency
            scale.location = (-478,100)
            links.new(coords.outputs["Object"],scale.inputs[0])
            image = nodes.new("ShaderNodeTexImage")
            image.image = diffuse
            image.projection = "BOX"
            image.projection_blend = .18
            image.location = (-260,140)
            links.new(scale.outputs["Vector"],image.inputs["Vector"])
            blend = nodes.new("ShaderNodeMixRGB")
            blend.blend_type = "MULTIPLY"
            blend.inputs[0].default_value = 1
            tint_weight = .91 if texture in {"valbrume_laine","valbrume_maille"} else .51
            blend.inputs[2].default_value = tuple(1-tint_weight+tint_weight*c for c in mat.diffuse_color[:3])+(1,)
            blend.location = (10,130)
            shader.location = (235,120)
            links.new(image.outputs["Color"],blend.inputs[1])
            links.new(blend.outputs["Color"],shader.inputs["Base Color"])



def main():
    global MATERIALS
    old = bpy.context.window.scene
    previous = bpy.data.scenes.get("Valbrume · bibliothèque")
    if previous and previous == old:
        old = next(scene for scene in bpy.data.scenes if scene != previous)
        bpy.context.window.scene = old
    if previous and previous.get("valbrume_generated", False) and previous != old:
        for collection in list(previous.collection.children):
            for obj in list(collection.objects):
                mesh = obj.data
                bpy.data.objects.remove(obj, do_unlink=True)
                if mesh.users == 0:
                    bpy.data.meshes.remove(mesh)
            bpy.data.collections.remove(collection)
        bpy.data.scenes.remove(previous)
    library = bpy.data.scenes.new("Valbrume · bibliothèque")
    library["valbrume_generated"] = True
    bpy.context.window.scene = library
    for old_material in list(bpy.data.materials):
        if old_material.get("valbrume_generated", False) and old_material.users == 0:
            bpy.data.materials.remove(old_material)
    MATERIALS = {name: material(name, code) for name, code in PALETTE.items()}
    for mat in MATERIALS.values():
        mat["valbrume_generated"] = True
    for name, filename in (("Visage jeune","visage-jeune.jpg"), ("Visage mûr","visage-mur.jpg"),
                           ("Visage garde","visage-garde.jpg")):
        skin_mat = MATERIALS[name]
        nodes, links = skin_mat.node_tree.nodes, skin_mat.node_tree.links
        shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
        diffuse = nodes.new("ShaderNodeTexImage")
        diffuse.image = bpy.data.images.load(str(ROOT/"art"/"morphology"/filename),check_existing=True)
        diffuse.image.pack()
        links.new(diffuse.outputs["Color"], shader.inputs["Base Color"])
        shader.inputs["Roughness"].default_value = .67
    make_person = run_path(str(ROOT / "art" / "characters.py"))["make_person"]
    models = (castle(), valley(), gate(), chicken(), horse(), cargo(), oak(),
              make_person(Model, "domestique", "Tunique"), make_person(Model, "roi", "Velours", True),
              make_person(Model, "garde", "Gambison"), make_person(Model, "intendant", "Bordeaux"))
    collections = {model.name: model.finish(library) for model in models}
    staging = {
        "herse": (0, .13, 22), "charge": (12, 1.2, 12), "chene": (-19, .08, 15), "domestique": (0, .12, 13.7), "roi": (0, .50, -16.9),
        "poule": (16, .12, 4.7), "cheval": (17, .12, -7.8),
        "garde": (5.3, .12, 18), "intendant": (4.8, .24, -15),
    }
    for name, position in staging.items():
        for obj in collections[name].objects:
            obj.location = axis(*position)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.shading.color_type = "MATERIAL"
                area.spaces.active.region_3d.view_location = Vector((0,0,1))
                area.spaces.active.region_3d.view_distance = 55
                area.spaces.active.region_3d.view_rotation = Quaternion((.86,.49,.1,.18)).normalized()
    pack_preview_materials()
    # Save a separate editable library while preserving the original file.
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "art" / "Valbrume.blend"), copy=True)
    print(f"Valbrume : {len(models)} modèles GLB exportés.")


if __name__ == "__main__":
    main()
