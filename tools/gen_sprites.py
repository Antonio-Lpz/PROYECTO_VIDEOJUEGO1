"""Genera sprites pixel-art 2D para "Ecos de la Noche" como PNG.

Se dibujan a mano con ImageDraw (sin suavizado) para conservar el aspecto
pixel-art. Ejecutar:  python tools/gen_sprites.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

SIZE = 32


def new():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def mirror(points):
    return [(SIZE - 1 - x, y) for (x, y) in points]


def poly(d, pts, fill, outline=None):
    d.polygon(pts, fill=fill)
    if outline:
        d.line(pts + [pts[0]], fill=outline, width=1)


def ellipse(d, box, fill, outline=None):
    d.ellipse(box, fill=fill, outline=outline)


def line(d, pts, fill, width=1):
    d.line(pts, fill=fill, width=width)


# --- Paleta ---
OUTLINE = (24, 17, 34, 255)
BODY = (104, 78, 138, 255)
BODY_D = (66, 48, 92, 255)
WING = (78, 58, 104, 255)
WING_D = (56, 41, 74, 255)
WHITE = (242, 242, 250, 255)
PUPIL = (18, 12, 26, 255)
FANG = (245, 245, 250, 255)
BROWN = (126, 90, 58, 255)
BROWN_D = (86, 60, 40, 255)
BROWN_L = (168, 128, 84, 255)
YELLOW = (245, 205, 70, 255)
ORANGE = (235, 140, 45, 255)
RED = (198, 52, 58, 255)
GREEN = (76, 158, 82, 255)
GREEN_D = (46, 108, 58, 255)
GRAY = (150, 150, 160, 255)
GRAY_D = (90, 90, 100, 255)
PURPLE = (96, 78, 150, 255)
CYAN = (120, 220, 235, 255)


def draw_bat(wing_mode):
    img, d = new()
    if wing_mode == "mid":
        left = [(11, 15), (3, 12), (2, 19), (11, 22)]
    elif wing_mode == "up":
        left = [(11, 15), (4, 6), (1, 15), (11, 20)]
    else:  # down
        left = [(11, 18), (2, 25), (4, 31), (11, 23)]
    poly(d, left, WING, OUTLINE)
    poly(d, mirror(left), WING, OUTLINE)
    # nervaduras del ala
    line(d, [left[0], left[1]], WING_D, 1)
    line(d, [left[1], left[2]], WING_D, 1)

    # orejas
    poly(d, [(12, 12), (11, 5), (15, 11)], BODY, OUTLINE)
    poly(d, [(20, 15), (21, 8), (16, 12)][:0] or [(20, 15), (21, 6), (16, 15)], WING_D)
    poly(d, [(21, 15), (26, 6), (20, 6)], BODY, OUTLINE)
    poly(d, [(12, 15), (7, 6), (6, 6)], BODY, OUTLINE)

    # Cuerpo
    ellipse(d, (11, 12, 21, 25), BODY, OUTLINE)
    ellipse(d, (13, 15, 19, 23), BODY_D)

    # Orejas rojas internas
    poly(d, [(13, 8), (15, 13), (11, 13)], (150, 90, 130, 255))
    poly(d, [(19, 13), (17, 8), (21, 10)], (150, 90, 130, 255))

    # Ojos
    ellipse(d, (12, 16, 15, 19), WHITE)
    ellipse(d, (17, 16, 20, 19), WHITE)
    ellipse(d, (13, 17, 15, 19), PUPIL)
    ellipse(d, (18, 17, 20, 19), PUPIL)

    # Colmillos
    line(d, [(14, 22), (14, 25)], FANG, 1)
    line(d, [(18, 22), (18, 25)], FANG, 1)
    return img


def draw_owl(big=False):
    img, d = new()
    feather = (118, 84, 52, 255) if not big else (92, 64, 44, 255)
    feather_d = (78, 55, 34, 255)
    # alas
    poly(d, [(11, 15), (2, 20), (4, 27), (12, 22)], feather_d)
    poly(d, mirror([(11, 15), (2, 20), (4, 27), (12, 22)]), feather_d)
    # cuerpo
    ellipse(d, (8, 8, 24, 28), feather, OUTLINE)
    ellipse(d, (11, 12, 21, 26), feather_d)
    # penachos
    poly(d, [(9, 9), (6, 3), (13, 8)], feather, OUTLINE)
    poly(d, [(23, 9), (26, 3), (19, 8)], feather, OUTLINE)
    # ojos
    ellipse(d, (10, 12, 16, 18), YELLOW, OUTLINE)
    ellipse(d, (16, 12, 22, 18), YELLOW, OUTLINE)
    ellipse(d, (12, 14, 15, 17), PUPIL)
    ellipse(d, (17, 14, 20, 17), PUPIL)
    # pico
    poly(d, [(14, 18), (18, 18), (16, 22)], ORANGE, OUTLINE)
    # pecho
    for y in (22, 25):
        line(d, [(12, y), (20, y)], feather_d, 1)
    return img


def draw_spider():
    img, d = new()
    body = (34, 28, 42, 255)
    body_d = (20, 16, 26, 255)
    # patas
    legs = [
        [(14, 16), (4, 10)], [(13, 18), (2, 17)], [(13, 20), (3, 25)], [(15, 21), (6, 29)],
    ]
    for p in legs:
        line(d, p, (26, 20, 32, 255), 2)
        line(d, mirror(p), (26, 20, 32, 255), 2)
    # cuerpo
    ellipse(d, (10, 14, 22, 26), (20, 15, 28, 255), OUTLINE)
    ellipse(d, (13, 10, 19, 17), BODY_D, OUTLINE)
    # ojos rojos
    ellipse(d, (13, 13, 15, 15), RED)
    ellipse(d, (17, 13, 19, 15), RED)
    ellipse(d, (14, 11, 15, 13), RED)
    ellipse(d, (17, 11, 18, 13), RED)
    return img


def draw_snake():
    img, d = new()
    # cuerpo ondulado
    pts = [(4, 26), (7, 22), (11, 26), (15, 22), (19, 26), (23, 22), (27, 24)]
    line(d, pts, GREEN_D, 7)
    line(d, pts, GREEN, 5)
    # manchas
    for p in [(7, 22), (13, 23), (19, 24)]:
        d.rectangle((p[0] - 1, p[1] - 1, p[0] + 1, p[1] + 1), fill=GREEN_D)
    # cabeza
    ellipse(d, (22, 14, 31, 23), GREEN, OUTLINE)
    # lengua
    line(d, [(30, 20), (31, 20)], (210, 60, 70, 255), 1)
    # ojo
    ellipse(d, (26, 17, 28, 19), YELLOW)
    ellipse(d, (26, 17, 27, 18), PUPIL)
    return img


def draw_guardian():
    img, d = new()
    body = (58, 48, 92, 255)
    body_d = (38, 30, 62, 255)
    # alas oscuras
    poly(d, [(12, 14), (1, 8), (2, 26), (12, 22)], body_d)
    poly(d, mirror([(12, 14), (1, 8), (2, 26), (12, 22)]), body_d)
    # cuerpo
    ellipse(d, (8, 8, 24, 28), body, OUTLINE)
    ellipse(d, (11, 12, 21, 26), body_d)
    # cuernos
    poly(d, [(9, 9), (3, 1), (13, 7)], body_d, OUTLINE)
    poly(d, [(23, 9), (29, 1), (19, 7)], body_d, OUTLINE)
    # ojos brillantes
    ellipse(d, (10, 13, 15, 18), CYAN)
    ellipse(d, (17, 13, 22, 18), CYAN)
    ellipse(d, (11, 14, 13, 16), PUPIL)
    ellipse(d, (19, 14, 21, 16), PUPIL)
    # boca
    line(d, [(13, 22), (19, 22)], (20, 14, 26, 255), 2)
    for x in (14, 17, 20):
        line(d, [(x, 22), (x, 24)], WHITE, 1)
    return img


def draw_apple():
    img, d = new()
    # tallo
    line(d, [(16, 9), (17, 3)], BROWN_D, 2)
    # hoja
    poly(d, [(17, 5), (23, 3), (18, 9)], GREEN_D, GREEN)
    # cuerpo
    ellipse(d, (8, 8, 24, 26), RED, OUTLINE)
    # brillo
    ellipse(d, (11, 11, 15, 15), (240, 150, 150, 255))
    ellipse(d, (19, 18, 22, 22), (150, 30, 40, 255))
    return img


def draw_bug():
    img, d = new()
    # patas
    for x in (10, 16, 22):
        line(d, [(x, 20), (x - 2, 25)], GRAY_D, 1)
        line(d, [(x, 20), (x + 2, 25)], GRAY_D, 1)
    # alas
    ellipse(d, (4, 10, 15, 18), (255, 255, 255, 120))
    ellipse(d, (17, 10, 28, 18), (255, 255, 255, 120))
    # cuerpo
    ellipse(d, (11, 12, 21, 24), YELLOW, OUTLINE)
    line(d, [(16, 12), (16, 24)], (200, 150, 30, 255), 1)
    # cabeza
    ellipse(d, (13, 7, 19, 13), (230, 180, 50, 255), OUTLINE)
    # ojos
    ellipse(d, (14, 9, 16, 11), PUPIL)
    ellipse(d, (16, 9, 18, 11), PUPIL)
    # antenas
    line(d, [(14, 7), (11, 3)], OUTLINE, 1)
    line(d, [(18, 7), (21, 3)], OUTLINE, 1)
    return img


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path)
    print("sprite:", name)


save(draw_bat("mid"), "bat_a.png")
save(draw_bat("up"), "bat_b.png")
save(draw_bat("down"), "bat_c.png")
save(draw_owl(False), "owl.png")
save(draw_owl(True), "owl_boss.png")
save(draw_spider(), "spider.png")
save(draw_snake(), "snake.png")
save(draw_guardian(), "guardian.png")
save(draw_apple(), "apple.png")
save(draw_bug(), "bug.png")

print("Listo. Sprites en:", os.path.abspath(OUT))
