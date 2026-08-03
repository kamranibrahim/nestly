#!/usr/bin/env python3
"""Compose Nestly Google Play feature graphic — 1024 × 500px."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path('/Users/kamran/StudioProjects/nestly')
OUT = ROOT / 'store' / 'play'
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1024, 500
FONT_DIR = Path('/Users/kamran/Library/Fonts')

INK = (28, 28, 30, 255)
INK_SOFT = (90, 90, 95, 255)
MINT = (212, 231, 179)
LAVENDER = (178, 178, 230)
PEACH = (255, 216, 168)
TEAL = (197, 232, 224)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient_bg() -> Image.Image:
    img = Image.new('RGB', (W, H))
    px = img.load()
    c1 = (236, 242, 230)  # mint wash
    c2 = (250, 249, 246)  # warm white
    c3 = (236, 234, 248)  # lavender wash
    for y in range(H):
        for x in range(W):
            tx = x / (W - 1)
            ty = y / (H - 1)
            mid = lerp(c1, c3, tx)
            color = lerp(mid, c2, 0.35 + 0.35 * (1 - abs(ty - 0.45)))
            # soft center glow
            dx = (x - W * 0.42) / (W * 0.55)
            dy = (y - H * 0.5) / (H * 0.7)
            r = math.sqrt(dx * dx + dy * dy)
            wash = max(0.0, 1.0 - r)
            color = lerp(color, (255, 255, 255), wash * 0.32)
            px[x, y] = color
    return img


def soft_blob(canvas: Image.Image, xy, size, color, alpha=70):
    blob = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(blob)
    x, y = xy
    d.ellipse((x, y, x + size, y + size), fill=(*color, alpha))
    blob = blob.filter(ImageFilter.GaussianBlur(70))
    return Image.alpha_composite(canvas.convert('RGBA'), blob)


def rounded_mask(size, radius) -> Image.Image:
    m = Image.new('L', size, 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return m


def drop_shadow(size, radius=36, blur=28, opacity=60) -> Image.Image:
    pad = blur * 3
    shadow = Image.new('RGBA', (size[0] + pad * 2, size[1] + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    d.rounded_rectangle(
        (pad, pad + 10, pad + size[0], pad + size[1]),
        radius=radius,
        fill=(20, 20, 24, opacity),
    )
    return shadow.filter(ImageFilter.GaussianBlur(blur))


def place_icon(canvas: Image.Image, path: Path, xy, size=118):
    icon = Image.open(path).convert('RGBA').resize((size, size), Image.Resampling.LANCZOS)
    icon.putalpha(rounded_mask((size, size), radius=int(size * 0.22)))
    shadow = drop_shadow((size, size), radius=int(size * 0.22), blur=22, opacity=55)
    sx = xy[0] - (shadow.width - size) // 2
    sy = xy[1] - (shadow.height - size) // 2 + 4
    canvas.paste(shadow, (sx, sy), shadow)
    canvas.paste(icon, xy, icon)


def place_phone(canvas: Image.Image, shot_path: Path):
    """Right-side phone mockup with clear inset from canvas edges."""
    shot = Image.open(shot_path).convert('RGB')
    margin_right = 64
    margin_bottom = 48
    margin_top = 40

    bezel = 8
    max_frame_h = H - margin_top - margin_bottom
    phone_h = max_frame_h - bezel * 2
    phone_w = int(phone_h * (shot.width / shot.height))
    # Keep room for left copy — don't let phone crowd past mid canvas
    max_phone_w = 300
    if phone_w > max_phone_w:
        phone_w = max_phone_w
        phone_h = int(phone_w * (shot.height / shot.width))
    phone = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)

    frame_w, frame_h = phone_w + bezel * 2, phone_h + bezel * 2
    radius = 40
    screen_radius = 32

    frame = Image.new('RGBA', (frame_w, frame_h), (22, 22, 24, 255))
    frame.putalpha(rounded_mask((frame_w, frame_h), radius))
    screen = phone.convert('RGBA')
    screen.putalpha(rounded_mask((phone_w, phone_h), screen_radius))
    frame.paste(screen, (bezel, bezel), screen)

    # Dynamic Island
    idraw = ImageDraw.Draw(frame)
    iw, ih = int(frame_w * 0.28), 13
    ix = (frame_w - iw) // 2
    idraw.rounded_rectangle((ix, 13, ix + iw, 13 + ih), radius=6, fill=(22, 22, 24, 255))

    fx = W - frame_w - margin_right
    fy = margin_top + (H - margin_top - margin_bottom - frame_h) // 2

    shadow = drop_shadow((frame_w, frame_h), radius=radius, blur=26, opacity=50)
    # Keep shadow inside canvas so it doesn't look clipped at the edges
    sx = fx - (shadow.width - frame_w) // 2
    sy = fy + 8
    canvas.paste(shadow, (sx, sy), shadow)
    canvas.paste(frame, (fx, fy), frame)


def draw_chip(canvas: Image.Image, text: str, xy, fill):
    draw = ImageDraw.Draw(canvas)
    fnt = font('Poppins-SemiBold.ttf', 18)
    pad_x, pad_y = 16, 8
    tw = draw.textlength(text, font=fnt)
    w, h = int(tw + pad_x * 2), 34
    chip = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chip)
    cd.rounded_rectangle((0, 0, w - 1, h - 1), radius=17, fill=(*fill, 220))
    cd.text((pad_x, pad_y - 1), text, font=fnt, fill=INK)
    canvas.paste(chip, xy, chip)
    return w


def compose():
    canvas = soft_blob(
        soft_blob(
            soft_blob(gradient_bg().convert('RGBA'), (-120, -80), 360, MINT, 80),
            (W - 280, -100),
            420,
            LAVENDER,
            70,
        ),
        (80, H - 200),
        320,
        PEACH,
        45,
    )

    # Product phone on the right
    sim = Path(
        '/Users/kamran/.cursor/projects/Users-kamran-StudioProjects-nestly/assets/'
        'Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.02-944d3dfd-5e15-4844-a814-184b18bee8e3.png'
    )
    if not sim.exists():
        sim = ROOT / 'store' / 'screenshots' / 'iphone-1242x2688' / '01-home.png'
    place_phone(canvas, sim)

    # Soft fade so text stays readable over phone overlap
    fade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fade)
    for x in range(420, 620):
        a = int(90 * (1 - (x - 420) / 200))
        fd.line([(x, 0), (x, H)], fill=(250, 249, 246, max(0, a)))
    canvas = Image.alpha_composite(canvas, fade)

    # Icon + brand
    icon = ROOT / 'assets' / 'brand' / 'logos' / 'nestly-app-icon.png'
    place_icon(canvas, icon, (72, 78), size=108)

    draw = ImageDraw.Draw(canvas)
    word = font('Poppins-ExtraBold.ttf', 72)
    draw.text((204, 88), 'Nestly', font=word, fill=INK)

    tag = font('Poppins-Medium.ttf', 26)
    tagline = 'the operating system for modern families'
    draw.text((72, 214), tagline, font=tag, fill=INK_SOFT)

    # Feature chips
    x = 72
    y = 278
    for label, color in (
        ('Calendar', MINT),
        ('Tasks', LAVENDER),
        ('Groceries', TEAL),
        ('Vault', PEACH),
    ):
        w = draw_chip(canvas, label, (x, y), color)
        x += w + 10

    # Supporting line
    sub = font('Poppins-Regular.ttf', 20)
    draw.text(
        (72, 340),
        'Shared calendar, chores, bills, meals & docs — one nest.',
        font=sub,
        fill=INK_SOFT,
    )

    out = OUT / 'feature-graphic.png'
    canvas.convert('RGB').save(out, 'PNG', optimize=True)
    # Play also accepts JPG
    jpg = OUT / 'feature-graphic.jpg'
    canvas.convert('RGB').save(jpg, 'JPEG', quality=92, optimize=True)
    print(f'{out}  {out.stat().st_size // 1024}KB  {W}×{H}')
    print(f'{jpg}  {jpg.stat().st_size // 1024}KB')
    return out


if __name__ == '__main__':
    compose()
