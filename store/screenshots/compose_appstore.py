#!/usr/bin/env python3
"""Compose Nestly App Store screenshots at 1242 × 2688px."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

ROOT = Path('/Users/kamran/StudioProjects/nestly')
ASSETS = Path('/Users/kamran/.cursor/projects/Users-kamran-StudioProjects-nestly/assets')
OUT = ROOT / 'store' / 'screenshots' / 'iphone-1242x2688'
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1242, 2688
FONT_DIR = Path('/Users/kamran/Library/Fonts')
SYS_FONT = Path('/System/Library/Fonts/Supplemental')
FOOTER_ZONE = 88
TOP_SAFE = 72
# Breathing room: title ↔ subtitle ↔ phone
GAP_AFTER_CHIP = 52
GAP_TITLE_TO_SUB = 64
GAP_SUB_TO_PHONE = 132
MAX_PHONE_WIDTH = 1020

INK = (28, 28, 30, 255)
INK_SOFT = (90, 90, 95, 255)
MINT = (212, 231, 179)
LAVENDER = (178, 178, 230)
PEACH = (255, 216, 168)
PINK = (245, 198, 216)
TEAL = (197, 232, 224)
YELLOW = (245, 230, 168)


def font(name: str, size: int, *, system: bool = False) -> ImageFont.FreeTypeFont:
    base = SYS_FONT if system else FONT_DIR
    return ImageFont.truetype(str(base / name), size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient_bg(c1, c2, c3) -> Image.Image:
    img = Image.new('RGB', (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        if t < 0.4:
            color = lerp(c1, c2, t / 0.4)
        else:
            color = lerp(c2, c3, (t - 0.4) / 0.6)
        for x in range(W):
            dx = (x - W * 0.5) / (W * 0.55)
            dy = (y - H * 0.12) / (H * 0.55)
            r = math.sqrt(dx * dx + dy * dy)
            wash = max(0.0, 1.0 - r)
            c = lerp(color, (255, 255, 255), wash * 0.28)
            px[x, y] = c
    return img


def soft_blob(canvas: Image.Image, xy, size, color, alpha=70):
    blob = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(blob)
    x, y = xy
    d.ellipse((x, y, x + size, y + size), fill=(*color, alpha))
    blob = blob.filter(ImageFilter.GaussianBlur(90))
    return Image.alpha_composite(canvas.convert('RGBA'), blob)


def rounded_mask(size, radius) -> Image.Image:
    m = Image.new('L', size, 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return m


def drop_shadow(size, radius=72, blur=50, opacity=78) -> Image.Image:
    pad = blur * 3
    shadow = Image.new('RGBA', (size[0] + pad * 2, size[1] + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    d.rounded_rectangle(
        (pad, pad + 24, pad + size[0], pad + size[1]),
        radius=radius,
        fill=(20, 20, 24, opacity),
    )
    return shadow.filter(ImageFilter.GaussianBlur(blur))


def wrap_text(draw, text, fnt, max_width):
    # Explicit breaks win (use \n for intentional two-line titles).
    if '\n' in text:
        return [ln.strip() for ln in text.split('\n') if ln.strip()]
    words = text.split()
    lines, cur = [], ''
    for w in words:
        trial = (cur + ' ' + w).strip()
        if draw.textlength(trial, font=fnt) <= max_width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def fit_phone_size(shot: Image.Image, top: int):
    """Size the phone to fill nearly all vertical space under the header."""
    bezel = 12
    available_h = H - top - FOOTER_ZONE
    # Prefer filling height first
    phone_h = available_h - bezel * 2
    phone_w = int(phone_h * (shot.width / shot.height))
    if phone_w > MAX_PHONE_WIDTH:
        phone_w = MAX_PHONE_WIDTH
        phone_h = int(phone_w * (shot.height / shot.width))
    # Ensure we still use most of the vertical slot
    frame_h = phone_h + bezel * 2
    if frame_h < available_h * 0.97:
        phone_h = int(available_h * 0.99) - bezel * 2
        phone_w = int(phone_h * (shot.width / shot.height))
        if phone_w > W - 36:
            phone_w = W - 36
            phone_h = int(phone_w * (shot.height / shot.width))
    return phone_w, phone_h, bezel


def place_phone(canvas: Image.Image, shot: Image.Image, top: int):
    phone_w, phone_h, bezel = fit_phone_size(shot, top)
    phone = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    phone = ImageEnhance.Sharpness(phone).enhance(1.12)
    phone = ImageEnhance.Contrast(phone).enhance(1.04)

    frame_w, frame_h = phone_w + bezel * 2, phone_h + bezel * 2
    radius = max(52, int(min(frame_w, frame_h) * 0.08))
    screen_radius = max(44, radius - 8)

    frame = Image.new('RGBA', (frame_w, frame_h), (22, 22, 24, 255))
    frame.putalpha(rounded_mask((frame_w, frame_h), radius))

    screen = phone.convert('RGBA')
    screen.putalpha(rounded_mask((phone_w, phone_h), screen_radius))
    frame.paste(screen, (bezel, bezel), screen)

    island = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(island)
    iw, ih = max(130, int(frame_w * 0.17)), max(32, int(frame_h * 0.017))
    ix = (frame_w - iw) // 2
    iy = max(16, bezel + 4)
    idraw.rounded_rectangle(
        (ix, iy, ix + iw, iy + ih),
        radius=ih // 2,
        fill=(22, 22, 24, 255),
    )
    frame = Image.alpha_composite(frame, island)

    # Pin phone to the bottom (above footer) — no empty gap under the mockup
    phone_top = H - FOOTER_ZONE - frame_h
    if phone_top < top:
        # Header collision: shrink to fit exactly between header and footer
        available_h = H - top - FOOTER_ZONE
        phone_h = available_h - bezel * 2
        phone_w = int(phone_h * (shot.width / shot.height))
        if phone_w > W - 36:
            phone_w = W - 36
            phone_h = int(phone_w * (shot.height / shot.width))
        phone = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
        phone = ImageEnhance.Sharpness(phone).enhance(1.12)
        frame_w, frame_h = phone_w + bezel * 2, phone_h + bezel * 2
        radius = max(52, int(min(frame_w, frame_h) * 0.08))
        screen_radius = max(44, radius - 8)
        frame = Image.new('RGBA', (frame_w, frame_h), (22, 22, 24, 255))
        frame.putalpha(rounded_mask((frame_w, frame_h), radius))
        screen = phone.convert('RGBA')
        screen.putalpha(rounded_mask((phone_w, phone_h), screen_radius))
        frame.paste(screen, (bezel, bezel), screen)
        phone_top = top

    shadow = drop_shadow((frame_w, frame_h), radius=radius, blur=44, opacity=68)
    sx = (W - shadow.width) // 2
    canvas.paste(shadow, (sx, phone_top - 4), shadow)
    fx = (W - frame_w) // 2
    canvas.paste(frame, (fx, phone_top), frame)
    return frame_w, frame_h, phone_top


def draw_header(canvas, headline, subhead, accent_rgb):
    draw = ImageDraw.Draw(canvas)
    brand_font = font('Poppins-SemiBold.ttf', 30)
    head_font = font('Poppins-ExtraBold.ttf', 96)
    sub_font = font('Poppins-Medium.ttf', 36)
    head_line_h = 108

    brand = 'Nestly'
    chip_w = int(draw.textlength(brand, font=brand_font) + 52)
    chip_h = 54
    chip = Image.new('RGBA', (chip_w, chip_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chip)
    cd.rounded_rectangle((0, 0, chip_w - 1, chip_h - 1), radius=27, fill=(*accent_rgb, 230))
    cd.text(
        ((chip_w - draw.textlength(brand, font=brand_font)) / 2, 10),
        brand,
        font=brand_font,
        fill=INK,
    )
    canvas.paste(chip, ((W - chip_w) // 2, TOP_SAFE), chip)

    # Title — gap after brand chip (forced two lines via \n in copy)
    lines = wrap_text(draw, headline, head_font, W - 72)
    y = TOP_SAFE + chip_h + GAP_AFTER_CHIP
    for line in lines:
        tw = draw.textlength(line, font=head_font)
        draw.text(((W - tw) / 2, y), line, font=head_font, fill=INK)
        y += head_line_h

    # Subtitle — clear gap under title
    y += GAP_TITLE_TO_SUB
    slines = wrap_text(draw, subhead, sub_font, W - 100)
    for line in slines:
        tw = draw.textlength(line, font=sub_font)
        draw.text(((W - tw) / 2, y), line, font=sub_font, fill=INK_SOFT)
        y += 48

    # Space before phone mockup
    return y + GAP_SUB_TO_PHONE


def compose(name, source, bg, headline, subhead, accent, crop_box=None):
    shot = Image.open(ASSETS / source).convert('RGB')
    if crop_box:
        shot = shot.crop(crop_box)

    canvas = soft_blob(
        soft_blob(
            gradient_bg(*bg).convert('RGBA'),
            (-160, 60),
            560,
            accent,
            55,
        ),
        (W - 380, H - 820),
        640,
        bg[1],
        60,
    )

    top = draw_header(canvas, headline, subhead, accent)
    fw, fh, pty = place_phone(canvas, shot, top=top)

    draw = ImageDraw.Draw(canvas)
    foot = font('Poppins-Medium.ttf', 26)
    label = 'the operating system for modern families'
    tw = draw.textlength(label, font=foot)
    draw.text(((W - tw) / 2, H - 68), label, font=foot, fill=(110, 110, 116, 200))

    out = OUT / f'{name}.png'
    canvas.convert('RGB').save(out, 'PNG', optimize=True)
    gap = H - FOOTER_ZONE - (pty + fh)
    print(f'{out.name}  {out.stat().st_size // 1024}KB  phone={fw}x{fh}  header_end={top}  bottom_gap={gap}px')
    return out


# Use full-height source shots so the phone fills the canvas.
SCREENS = [
    dict(
        name='01-home',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.02-944d3dfd-5e15-4844-a814-184b18bee8e3.png',
        bg=((242, 240, 250), (236, 240, 226), (250, 249, 246)),
        headline='One nest for\nthe whole family',
        subhead='Today’s tasks, meals, bills, and plans — together.',
        accent=LAVENDER,
    ),
    dict(
        name='02-calendar',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.30-d4ca83f6-bfbc-4398-85ba-9aafd88404f8.png',
        bg=((230, 242, 228), (248, 248, 246), (240, 234, 248)),
        headline='Everyone’s day,\nin one place',
        subhead='School, sports, and family time — shared.',
        accent=MINT,
    ),
    dict(
        name='03-tasks',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.33-26e95f33-87a4-4b43-b659-c1e70f938585.png',
        bg=((250, 243, 232), (245, 244, 250), (232, 242, 236)),
        headline='Chores that\nactually get done',
        subhead='Assign, repeat, and check off as a family.',
        accent=PEACH,
    ),
    dict(
        name='04-groceries',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.37-1194e389-4086-4dc8-9cbb-560af0060934.png',
        bg=((230, 244, 238), (250, 249, 246), (245, 236, 228)),
        headline='The list that\nkeeps up',
        subhead='Shared groceries — always in sync.',
        accent=TEAL,
    ),
    dict(
        name='05-budget',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.58.08-a6a0dbcb-8dda-4ca9-8a8e-a1cb97a65d88.png',
        bg=((250, 246, 230), (245, 244, 250), (232, 238, 250)),
        headline='Money, finally\nclear',
        subhead='Spending and bills in one calm view.',
        accent=YELLOW,
    ),
    dict(
        name='06-vault',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.50-9e10c8b2-7ffd-4987-940f-259b4e991e48.png',
        bg=((250, 238, 242), (245, 244, 250), (232, 242, 238)),
        headline='Important docs,\nalways ready',
        subhead='Passports, insurance, school records — organized.',
        accent=PINK,
    ),
    dict(
        name='07-locator',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-31_at_18.10.30-1518b14c-f2f8-45aa-9ff5-dbd61f617b8f.png',
        bg=((232, 242, 236), (245, 244, 250), (236, 240, 250)),
        headline='Know where\nyour nest is',
        subhead='Share a last-known pin — never background tracking.',
        accent=MINT,
    ),
    dict(
        name='08-meals',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.55-aee3b8d1-8aa6-4fc8-b8a1-da3c0c739d88.png',
        bg=((232, 242, 240), (250, 249, 246), (245, 238, 230)),
        headline='Dinner, planned\nfor the week',
        subhead='Push ingredients straight to groceries.',
        accent=TEAL,
    ),
    dict(
        name='09-nest',
        source='Simulator_Screenshot_-_iPhone_16e_-_2026-07-29_at_16.57.41-699f3509-ca2b-41c7-8836-6cf2e6b51267.png',
        bg=((242, 238, 250), (250, 249, 246), (236, 242, 230)),
        headline='Your family,\nconnected',
        subhead='Invite the nest. Share the load.',
        accent=LAVENDER,
    ),
]


def main():
    for spec in SCREENS:
        compose(**spec)
    print(f'\nAll screenshots → {OUT} ({W}×{H})')


if __name__ == '__main__':
    main()
