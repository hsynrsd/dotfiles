#!/usr/bin/env python3
"""Render the images for the 'steel-net' Plymouth boot theme.
A tiny network: your PC (hp) -> routers -> fedora core -> switches -> net.
Links light up as boot progresses; packets fly along them (animated in the .script)."""
import os, json, socket
HOST = socket.gethostname().split(".")[0]
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "steel-net")
F = os.path.expanduser("~/.local/share/fonts/JetBrainsMonoNerdFont-")
font = lambda style, size: ImageFont.truetype(F + style + ".ttf", size)

BG      = (19, 21, 31)
DIM     = (38, 43, 63)
DIMNODE = (47, 53, 77)
BLUE    = (122, 162, 247)
TEAL    = (115, 184, 201)
TEXT    = (169, 177, 214)
MUTED   = (86, 95, 137)
B1, B2, B3 = (59, 66, 97), (47, 53, 77), (38, 43, 63)

W, H = 1200, 420                    # network canvas; centre = (600, 190)
CX, CY = 600, 190
NODES = [  # name, x, y, glyph, size
    (HOST,     -470,    0, "󰍹", 30),
    ("r1",     -235, -105, "󰑩", 26),
    ("r2",     -235,  105, "󰑩", 26),
    ("fedora",    0,    0, "󰣛", 44),
    ("sw1",     235, -105, "󰒍", 26),
    ("sw2",     235,  105, "󰒍", 26),
    ("net",     470,    0, "󰖟", 30),
]
LINKS = [(0,1),(0,2),(1,3),(2,3),(3,4),(3,5),(4,6),(5,6),(1,2),(4,5)]
# order the links light up in (left to right)
ORDER = [0,1,8,2,3,4,5,9,6,7]
R = {"fedora": 46}
rad = lambda n: R.get(n, 34)

def pos(i):
    _, x, y, *_ = NODES[i]; return CX + x, CY + y

def clip(a, b, ra, rb):
    (x1,y1),(x2,y2) = a,b; dx,dy = x2-x1, y2-y1; d=(dx*dx+dy*dy)**.5
    return (x1+dx*ra/d, y1+dy*ra/d), (x2-dx*rb/d, y2-dy*rb/d)

def node(draw, i, ring, fill, glyph_col, label_col):
    name, x, y, g, gs = NODES[i]; px, py = CX+x, CY+y; r = rad(name)
    draw.ellipse([px-r, py-r, px+r, py+r], fill=fill, outline=ring, width=3)
    f = font("Regular", gs)
    draw.text((px, py), g, font=f, fill=glyph_col, anchor="mm")
    ly = py - r - 20 if y < 0 else py + r + 22          # top-row labels go above the node
    draw.text((px, ly), name, font=font("Regular", 17), fill=label_col, anchor="mm")

def glow(img, radius=7, strength=2):
    g = img.filter(ImageFilter.GaussianBlur(radius))
    out = Image.new("RGBA", img.size)
    for _ in range(strength): out = Image.alpha_composite(out, g)
    return Image.alpha_composite(out, img)

os.makedirs(OUT, exist_ok=True)

# base: dim network
base = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(base)
for a, b in LINKS:
    p, q = clip(pos(a), pos(b), rad(NODES[a][0]), rad(NODES[b][0]))
    d.line([p, q], fill=DIM, width=3)
for i in range(len(NODES)):
    node(d, i, DIMNODE, (24, 27, 40), MUTED, MUTED)
base.save(f"{OUT}/net-base.png")

# one lit overlay per link (link + its two nodes), in lighting order
for k, li in enumerate(ORDER):
    a, b = LINKS[li]
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    p, q = clip(pos(a), pos(b), rad(NODES[a][0]), rad(NODES[b][0]))
    d.line([p, q], fill=BLUE + (220,), width=3)
    glow(im, 6, 2).save(f"{OUT}/link{k}.png")

# lit nodes (shown once any of their links is lit)
for i in range(len(NODES)):
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    node(d, i, BLUE, (30, 35, 54), BLUE if NODES[i][0] != "fedora" else (160, 190, 250), TEXT)
    glow(im, 8, 1).save(f"{OUT}/node{i}.png")

# packet: small teal dot with glow
pk = Image.new("RGBA", (40, 40)); d = ImageDraw.Draw(pk)
d.ellipse([14, 14, 26, 26], fill=TEAL + (255,))
glow(pk, 5, 3).save(f"{OUT}/packet.png")

def text_img(parts, path, pad=4):
    """parts: list of (text, style, size, colour)."""
    fs = [font(s, z) for _, s, z, _ in parts]
    widths = [f.getbbox(t)[2] for (t, *_), f in zip(parts, fs)]
    h = max(f.getbbox("Ag󰣛")[3] for f in fs) + pad * 2
    im = Image.new("RGBA", (sum(widths) + pad * 2, h)); d = ImageDraw.Draw(im); x = pad
    for (t, s, z, c), f, w in zip(parts, fs, widths):
        d.text((x, pad), t, font=f, fill=c); x += w
    im.save(path)

text_img([(f"hsynrsd@{HOST}", "SemiBold", 22, BLUE), ("  ─  ", "Light", 22, MUTED),
          ("bringing fedora online", "Light", 22, TEXT)], f"{OUT}/caption-boot.png")
text_img([(f"hsynrsd@{HOST}", "SemiBold", 22, BLUE), ("  ─  ", "Light", 22, MUTED),
          ("taking fedora offline", "Light", 22, TEXT)], f"{OUT}/caption-shutdown.png")
text_img([("all links up", "Light", 18, TEAL)], f"{OUT}/caption-done.png")
cur = Image.new("RGBA", (13, 26), BLUE + (255,)); cur.save(f"{OUT}/cursor.png")

# password prompt, styled like the starship prompt
def prompt():
    f = font("SemiBold", 22); fl = font("Light", 22)
    segs = [(" 󰌾  unlock ", B1, BLUE), ("  disk ", B2, TEAL), ("  luks ", B3, MUTED)]
    h = 40; pw = [int(f.getbbox(t)[2]) + 8 + (h // 2 if i else 0) for i, (t, *_) in enumerate(segs)]
    lead = int(fl.getbbox("╭─")[2]) + 6
    im = Image.new("RGBA", (lead + sum(pw) + 60, h * 2 + 6)); d = ImageDraw.Draw(im)
    d.text((0, h // 2), "╭─", font=fl, fill=MUTED, anchor="lm")
    x = lead
    d.ellipse([x - 2, 0, x + h - 2, h - 1], fill=B1); x += h // 2   # rounded left cap
    xs = []
    for (t, bg, fg), w in zip(segs, pw):
        d.rectangle([x, 0, x + w, h - 1], fill=bg); xs.append(x); x += w
    for (t, bg, fg), w, sx in zip(segs, pw, xs):                        # arrows on top
        e = sx + w
        d.polygon([(e, 0), (e + h // 2, h // 2), (e, h - 1)], fill=bg)
        d.line([(e, 0), (e + h // 2, h // 2), (e, h - 1)], fill=(19, 21, 31), width=2)
        d.text((sx + 4 + (h // 2 if sx != xs[0] else 0), h // 2), t, font=f, fill=fg, anchor="lm")
    d.text((0, h + 6 + h // 2), "╰─", font=fl, fill=MUTED, anchor="lm")
    d.text((lead, h + 6 + h // 2), "❯", font=font("Bold", 24), fill=BLUE, anchor="lm")
    im.save(f"{OUT}/prompt.png")
    return lead, h
lead, h = prompt()
b = Image.new("RGBA", (22, 22)); d = ImageDraw.Draw(b)
d.ellipse([5, 5, 17, 17], fill=TEXT + (255,)); b.save(f"{OUT}/bullet.png")



print("ok", sorted(os.listdir(OUT)))
