"""
Elsewhere — asset generator.

Renders a cohesive set of grainy, film-like landscape stills for the app,
plus the app icon. Everything is generated locally so the project ships
with no third-party image dependencies.

Run:  python tool/generate_assets.py
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images"
OUT.mkdir(parents=True, exist_ok=True)

SS = 2  # supersampling factor


# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------

def hx(value: str) -> np.ndarray:
    value = value.lstrip("#")
    return np.array([int(value[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def vgrad(w: int, h: int, stops: list[tuple[float, str]]) -> np.ndarray:
    """Vertical multi-stop gradient as float RGB array (h, w, 3)."""
    ys = np.linspace(0.0, 1.0, h)
    pos = np.array([s[0] for s in stops], dtype=np.float64)
    colors = np.array([hx(s[1]) for s in stops], dtype=np.float64)
    out = np.zeros((h, w, 3), dtype=np.float64)
    for c in range(3):
        out[:, :, c] = np.interp(ys, pos, colors[:, c])[:, None]
    return out


def blend(base: np.ndarray, top: np.ndarray, alpha: np.ndarray | float) -> np.ndarray:
    if isinstance(alpha, (int, float)):
        alpha = np.full(base.shape[:2], float(alpha), dtype=np.float64)
    a = alpha[:, :, None]
    return base * (1.0 - a) + top * a


def screen(base: np.ndarray, layer: np.ndarray, alpha: np.ndarray | float = 1.0) -> np.ndarray:
    if isinstance(alpha, (int, float)):
        alpha = np.full(base.shape[:2], float(alpha), dtype=np.float64)
    a = alpha[:, :, None]
    screened = 255.0 - (255.0 - base) * (255.0 - layer) / 255.0
    return base * (1.0 - a) + screened * a


def radial_glow(w: int, h: int, cx: float, cy: float, radius: float,
                color: str, power: float = 2.2) -> np.ndarray:
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx / w) - cx) ** 2 + ((yy / h) - cy) ** 2)
    r = radius
    falloff = np.clip(1.0 - d / r, 0.0, 1.0) ** power
    layer = np.zeros((h, w, 3), dtype=np.float64)
    layer[:] = hx(color)
    return layer, (falloff * 255.0).astype(np.float64)


def add_glow(img: np.ndarray, cx: float, cy: float, radius: float, color: str,
             strength: float = 1.0, power: float = 2.2) -> np.ndarray:
    layer, mask = radial_glow(img.shape[1], img.shape[0], cx, cy, radius, color, power)
    return screen(img, layer, np.clip(mask / 255.0 * strength, 0.0, 1.0))


def fbm1d(n: int, rng: random.Random, octaves: int = 5, gain: float = 0.55) -> np.ndarray:
    x = np.linspace(0.0, 1.0, n)
    total = np.zeros(n)
    amp = 1.0
    freq = 1.0
    norm = 0.0
    for _ in range(octaves):
        phase = rng.uniform(0, math.tau)
        shape = rng.choice([np.sin, np.cos])
        total += amp * shape(math.tau * freq * x * rng.uniform(1.2, 2.2) + phase)
        norm += amp
        amp *= gain
        freq *= rng.uniform(1.7, 2.4)
    return total / norm


def smooth1d(values: np.ndarray, sigma: float) -> np.ndarray:
    """Gaussian smoothing for a 1-D profile without external deps."""
    radius = max(1, int(sigma * 3))
    x = np.arange(-radius, radius + 1)
    kernel = np.exp(-0.5 * (x / sigma) ** 2)
    kernel /= kernel.sum()
    return np.convolve(np.pad(values, (radius, radius), mode="edge"), kernel, mode="valid")


def ridge_curve(n: int, rng: random.Random, jagged: bool = False) -> np.ndarray:
    """Organic mountain profile, normalised 0..1 (1 = tallest)."""
    x = np.linspace(0.0, 1.0, n)
    base = 0.16 + 0.10 * (fbm1d(n, rng, octaves=4, gain=0.55) + 1) / 2

    peaks = rng.randint(4, 8) if jagged else rng.randint(3, 6)
    envelope = np.zeros(n)
    for _ in range(peaks):
        c = rng.uniform(-0.08, 1.08)
        wl = rng.uniform(0.07, 0.30)
        wr = rng.uniform(0.07, 0.30)
        h = rng.uniform(0.35, 1.0)
        p = rng.uniform(1.0, 1.8) if jagged else rng.uniform(1.8, 2.8)
        side = np.where(x < c,
                        np.exp(-(np.abs((x - c) / wl) ** p)),
                        np.exp(-(np.abs((x - c) / wr) ** p)))
        envelope = np.maximum(envelope, h * side)

    # erosion: larger shapes get broken up by mid-frequency noise
    erosion = 0.82 + 0.22 * (fbm1d(n, rng, octaves=5, gain=0.5) + 1) / 2
    curve = envelope * erosion
    curve += base * 0.4
    curve += (0.018 if jagged else 0.012) * fbm1d(n, rng, octaves=7, gain=0.55)
    curve = smooth1d(curve, sigma=2.0 if jagged else 4.5)
    curve -= curve.min()
    curve /= max(curve.max(), 1e-5)
    return curve ** (1.05 if jagged else 1.3)


def paste_ridge(img: np.ndarray, w: int, h: int, curve: np.ndarray,
                base_y: float, amp: float, color: str, haze_color: str,
                alpha: float = 1.0, blur: float = 0.0,
                rim: float = 0.0, snow: str | None = None) -> np.ndarray:
    """Fill a mountain silhouette with a soft vertical grade and a lit rim."""
    points = curve_polygon(curve, w, h, base_y, amp)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.polygon(points, fill=int(255 * alpha))
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask, dtype=np.float64) / 255.0

    top_y = max(0.0, (base_y - amp) * h)
    t = np.clip((np.arange(h) - top_y) / max(1.0, h - top_y), 0, 1)
    shade = np.array(hx(color), dtype=np.float64)
    light = shade * 0.72 + np.array(hx(haze_color), dtype=np.float64) * 0.28
    grad = np.zeros((h, w, 3), dtype=np.float64)
    for c in range(3):
        grad[:, :, c] = (light[c] * (1 - t) + shade[c] * t)[:, None]

    # soft directional light from the right
    yy, xx = np.mgrid[0:h, 0:w]
    directional = 0.05 * np.clip((xx / w - 0.15) / 0.85, 0, 1)
    img = img * (1 - m[:, :, None]) + grad * m[:, :, None]
    img = screen(img, np.full_like(img, hx(haze_color)), m * directional)

    if rim > 0:
        down = np.roll(m, max(2, int(2 * SS)), axis=0)
        edge = np.clip(m - down, 0, 1)
        edge = np.asarray(Image.fromarray(np.uint8(edge * 255))
                          .filter(ImageFilter.GaussianBlur(1.5 * SS)),
                          dtype=np.float64) / 255.0
        img = screen(img, np.full_like(img, hx(haze_color)), edge * rim)

    if snow:
        depth = max(4, int(0.055 * h))
        band = np.clip(m - np.roll(m, depth, axis=0), 0, 1)
        noise = np.random.default_rng(int(m.sum())).normal(0.5, 0.22, (max(1, h // 8), max(1, w // 8)))
        noise = np.asarray(Image.fromarray(np.uint8(np.clip(noise, 0, 1) * 255))
                           .resize((w, h), Image.Resampling.BICUBIC)
                           .filter(ImageFilter.GaussianBlur(2.0 * SS)),
                           dtype=np.float64) / 255.0
        patches = band * np.clip((noise - 0.42) * 5.0, 0, 1)
        patches = np.asarray(Image.fromarray(np.uint8(patches * 255))
                             .filter(ImageFilter.GaussianBlur(0.8 * SS)),
                             dtype=np.float64) / 255.0
        img = blend(img, np.full_like(img, hx(snow)), np.clip(patches, 0, 0.85))
    return img


def curve_polygon(curve: np.ndarray, w: int, h: int, base_y: float,
                  amp: float) -> list[tuple[float, float]]:
    xs = np.linspace(0, w, len(curve))
    ys = base_y * h - curve * amp * h
    points = list(zip(xs.tolist(), ys.tolist()))
    points += [(w, h), (0, h)]
    return points


def paste_shape(img: np.ndarray, points: list[tuple[float, float]], color: str,
                alpha: float = 1.0, blur: float = 0.0) -> np.ndarray:
    h, w = img.shape[:2]
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.polygon(points, fill=int(255 * alpha))
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    layer = np.zeros_like(img)
    layer[:] = hx(color)
    return blend(img, layer, m)


def paste_soft_ellipse(img: np.ndarray, cx: float, cy: float, rx: float, ry: float,
                       color: str, alpha: float, blur: float = 0.0) -> np.ndarray:
    h, w = img.shape[:2]
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([(cx - rx) * w, (cy - ry) * h, (cx + rx) * w, (cy + ry) * h],
              fill=int(255 * alpha))
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    layer = np.zeros_like(img)
    layer[:] = hx(color)
    return blend(img, layer, m)


def haze_band(img: np.ndarray, y: float, height: float, color: str,
              strength: float = 0.5) -> np.ndarray:
    h, w = img.shape[:2]
    yy = np.linspace(0, 1, h)
    mask = np.exp(-0.5 * ((yy - y) / max(height, 1e-4)) ** 2) * strength
    return blend(img, np.full_like(img, hx(color)), mask[:, None])


def add_paper_grain(img: np.ndarray, rng: np.random.Generator, amount: float = 5.0) -> np.ndarray:
    h, w = img.shape[:2]
    grain = rng.normal(0.0, amount, (h, w, 1))
    grain = grain + rng.normal(0.0, amount * 0.45, (h, w, 3))
    fine = rng.normal(0.0, amount * 0.6, (h // 2, w // 2, 1))
    fine = np.asarray(Image.fromarray(np.uint8(np.clip(fine[:, :, 0] + 128, 0, 255)))
                      .resize((w, h), Image.Resampling.NEAREST), dtype=np.float64)[:, :, None] - 128.0
    return img + grain + fine * 0.5


def vignette(img: np.ndarray, strength: float = 0.35, softness: float = 1.5) -> np.ndarray:
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    nx = (xx / w - 0.5) * 2
    ny = (yy / h - 0.5) * 2
    d = np.sqrt(nx ** 2 + ny ** 2) / 1.414
    mask = 1.0 - strength * np.clip(d, 0, 1) ** softness
    return img * mask[:, :, None]


def light_leak(img: np.ndarray, cx: float, cy: float, radius: float,
               color: str, strength: float) -> np.ndarray:
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx / w - cx) ** 2 + (yy / h - cy) ** 2) / radius
    falloff = np.clip(1.0 - d, 0, 1) ** 3
    layer = np.zeros_like(img)
    layer[:] = hx(color)
    return screen(img, layer, falloff * strength)


def chromatic_aberration(img: np.ndarray, shift: int = 1) -> np.ndarray:
    out = img.copy()
    out[:, shift:, 0] = img[:, :-shift, 0]
    out[:, :-shift, 2] = img[:, shift:, 2]
    return out


def finish(img: np.ndarray, seed: int, warmth: float = 1.0,
           grain: float = 4.6, leak: tuple[float, float, str, float] | None = None) -> Image.Image:
    h, w = img.shape[:2]
    img = np.clip(img, 0, 255)
    img = add_paper_grain(img, np.random.default_rng(seed), grain)
    img = vignette(img, strength=0.34, softness=1.6)
    if leak:
        cx, cy, color, strength = leak
        img = light_leak(img, cx, cy, 0.55, color, strength)
    # gentle warm grade
    img[:, :, 0] *= 1.0 + 0.035 * warmth
    img[:, :, 2] *= 1.0 - 0.045 * warmth
    img[:, :, 1] *= 1.0 + 0.008 * warmth
    img = chromatic_aberration(img, shift=1)
    img = np.clip(img, 0, 255).astype(np.uint8)
    out = Image.fromarray(img, "RGB")
    return out


def prepare(w: int, h: int) -> tuple[int, int]:
    return w * SS, h * SS


def downsample(img: np.ndarray, w: int, h: int, post_blur: float = 0.6) -> Image.Image:
    arr = np.clip(img, 0, 255).astype(np.uint8)
    im = Image.fromarray(arr, "RGB").resize((w, h), Image.Resampling.LANCZOS)
    if post_blur:
        im = im.filter(ImageFilter.GaussianBlur(post_blur))
    return im


# ----------------------------------------------------------------------------
# palettes
# ----------------------------------------------------------------------------

PALETTES = {
    "lofoten": {
        "sky": [(0.0, "#101f30"), (0.32, "#29465c"), (0.5, "#7f97a4"), (0.62, "#d9a97f")],
        "sun": "#ffdcae", "haze": "#d8c3ad", "accent": "#e7b183",
        "far": "#647f8f", "mid": "#385467", "near": "#1a2f3d", "deep": "#0b1721",
        "water1": "#2a4b5d", "water2": "#0a151e",
    },
    "oaxaca": {
        "sky": [(0.0, "#4c2323"), (0.3, "#98452f"), (0.5, "#d87b45"), (0.62, "#f2b268")],
        "sun": "#ffe3a6", "haze": "#efb37c", "accent": "#e09a44",
        "far": "#93513a", "mid": "#6a3527", "near": "#3c211a", "deep": "#24120f",
        "dune1": "#c97e4c", "dune2": "#a55e38", "dune3": "#7a4029", "dune4": "#4e281e",
    },
    "kyoto": {
        "sky": [(0.0, "#1b2721"), (0.3, "#3f5144"), (0.55, "#8b9782"), (0.66, "#d8cfb4")],
        "sun": "#f4e8c8", "haze": "#b8c0a8", "accent": "#9d3f32",
        "far": "#72806b", "mid": "#415440", "near": "#223128", "deep": "#101a14",
        "stalk1": "#2d3d31", "stalk2": "#17251b", "stalk3": "#3f523f",
    },
    "faroe": {
        "sky": [(0.0, "#49595e"), (0.35, "#738384"), (0.55, "#a7b1ac"), (0.64, "#d9d4c2")],
        "sun": "#f7ecd6", "haze": "#cfd5ca", "accent": "#c2ad76",
        "far": "#82928d", "mid": "#516761", "near": "#31463f", "deep": "#1a2a26",
        "water1": "#466468", "water2": "#182b2d",
    },
    "merzouga": {
        "sky": [(0.0, "#1d3341"), (0.35, "#4d6b73"), (0.56, "#c79b76"), (0.64, "#f2c894")],
        "sun": "#ffdda6", "haze": "#e6bb91", "accent": "#2f7370",
        "wall": "#b86545", "wall_light": "#cf835b", "wall_shadow": "#7d392a",
        "deep": "#4a1f1a", "floor": "#8b4a34",
        "dune1": "#c98a5b", "dune2": "#b06e46", "dune3": "#854a33", "dune4": "#572e24",
        "far": "#8a4f3a",
    },
    "patagonia": {
        "sky": [(0.0, "#152535"), (0.3, "#3f5b6e"), (0.52, "#98a8ac"), (0.62, "#e0cdb0")],
        "sun": "#ffe5ba", "haze": "#d6c8b3", "accent": "#c6a76c",
        "far": "#8b9b9f", "mid": "#5a6f76", "near": "#2c3f47", "deep": "#13262e",
        "snow": "#e5e8e4", "rock": "#4d6067",
        "water1": "#365764", "water2": "#0f222a",
    },
    "hoian": {
        "sky": [(0.0, "#0b1420"), (0.35, "#15283c"), (0.58, "#3e3b42"), (0.66, "#7b4f40")],
        "sun": "#ffcf95", "haze": "#8d5b48", "accent": "#e4a154",
        "deep": "#070e16", "water1": "#122334", "water2": "#070d14",
    },
    "sicily": {
        "sky": [(0.0, "#4e6f7d"), (0.35, "#80999a"), (0.55, "#cfc7a8"), (0.64, "#f0d9a9")],
        "sun": "#fff0c8", "haze": "#e7d6bb", "accent": "#d98d4d",
        "far": "#849184", "mid": "#6b7a62", "near": "#3f4a38", "deep": "#232b21",
        "water1": "#557f7d", "water2": "#23494c",
        "cliff": "#c4b18a", "cliff_shadow": "#8f7755",
    },
}


# ----------------------------------------------------------------------------
# scenes
# ----------------------------------------------------------------------------

def scene_ridges(w: int, h: int, pal: dict, rng: random.Random,
                 jagged: bool = False, horizon: float = 0.62,
                 sun: tuple[float, float] = (0.72, 0.58), detail: str | None = None,
                 snow: bool = False, **_) -> np.ndarray:
    img = vgrad(w, h, pal["sky"])
    # sun and its halo
    img = add_glow(img, sun[0], sun[1], 0.62, pal["sun"], strength=0.55, power=2.6)
    img = add_glow(img, sun[0], sun[1], 0.085, pal["sun"], strength=0.95, power=1.5)
    img = haze_band(img, horizon - 0.015, 0.05, pal["haze"], 0.55)

    # distant ridge layers
    layers = [
        (pal["far"], horizon + 0.02, 0.26, 0.60, 6.0, 0.18),
        (pal["far"], horizon + 0.035, 0.22, 0.72, 3.2, 0.22),
        (pal["mid"], horizon + 0.06, 0.30, 0.88, 1.6, 0.26),
        (pal["near"], horizon + 0.10, 0.36, 1.0, 0.5, 0.30),
    ]
    for i, (color, base, amp, alpha, blur, rim) in enumerate(layers):
        curve = ridge_curve(w, rng, jagged=jagged and i < 4)
        img = paste_ridge(img, w, h, curve, base, amp, color, pal["haze"],
                          alpha=alpha, blur=blur * SS, rim=rim,
                          snow=pal.get("snow") if snow and i >= 2 else None)
        img = haze_band(img, horizon - 0.02, 0.05 + 0.008 * i, pal["haze"],
                        0.30 - i * 0.055)

    # water
    water_y = int(horizon * h)
    above = img[:water_y]
    water_grad = vgrad(w, h - water_y,
                       [(0.0, pal["water1"]), (0.45, pal["water1"]), (1.0, pal["water2"])])
    refl = np.asarray(Image.fromarray(np.uint8(np.clip(above, 0, 255)))
                      .transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                      .resize((w, h - water_y), Image.Resampling.BILINEAR),
                      dtype=np.float64)
    # stretch & fade the reflection
    fade = np.linspace(0.62, 0.06, h - water_y)[:, None, None]
    water = water_grad * (1 - fade) + refl * fade * 0.9
    # ripples ? push the reflection around so it never mirrors perfectly
    rows = np.arange(h - water_y)
    ripple = ((np.sin(rows * 0.055) * 7.0 + np.sin(rows * 0.19 + 1.7) * 2.5) * SS).astype(int)
    for r in range(h - water_y):
        shift = int(ripple[r] + rng.uniform(-1.5, 1.5) * SS)
        water[r] = np.roll(water[r], shift, axis=0)
        if r % 3 == 0:
            water[r] = (water[r] * 0.7
                        + np.roll(water[r], 2 * SS, axis=0) * 0.15
                        + np.roll(water[r], -2 * SS, axis=0) * 0.15)
    water = np.asarray(Image.fromarray(np.uint8(np.clip(water, 0, 255)))
                       .filter(ImageFilter.GaussianBlur(2.0 * SS)), dtype=np.float64)
    # deepen the water toward the foreground
    depth = np.linspace(0.08, 0.55, h - water_y)[:, None, None]
    water = water * (1 - depth) + np.array(hx(pal["water2"])) * depth
    img = img.copy()
    img[water_y:] = water
    # horizon seam, soft and slightly uneven
    img = haze_band(img, horizon, 0.015, pal["haze"], 0.30)

    # foreground shore / bottom anchor
    curve = ridge_curve(w, rng)
    pts = curve_polygon(curve, w, h, 1.02, 0.11)
    img = paste_shape(img, pts, pal["deep"], alpha=0.9, blur=1.2 * SS)

    # moonlight path on water
    img = add_glow(img, sun[0], min(1.02, horizon + 0.18), 0.28, pal["sun"],
                   strength=0.16, power=2.0)

    if detail in ("boat", "cabins"):
        add_boat(img, 0.63 * w, (horizon + 0.13) * h, 0.018 * w,
                 pal["deep"], pal["sun"], SS)
    if detail == "cabins":
        add_cabins(img, 0.19 * w, (horizon + 0.012) * h, 0.047 * w, SS)
    elif detail == "tent":
        add_tent(img, 0.75 * w, (horizon + 0.045) * h, 0.022 * w,
                 pal["deep"], pal["sun"], SS)
    return img


def add_boat(img: np.ndarray, x: float, y: float, size: float,
             color: str, light: str, ss: float = 1.0) -> None:
    """A tiny fishing boat with a warm lantern, plus its reflection."""
    h, w = img.shape[:2]
    overlay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(overlay)
    hull = [(x - size, y), (x + size, y),
            (x + size * 0.62, y + size * 0.34), (x - size * 0.7, y + size * 0.34)]
    d.polygon(hull, fill=235)
    d.line([(x, y), (x, y - size * 2.1)], fill=220, width=max(1, int(1.2 * ss)))
    d.line([(x - size * 0.9, y - size * 1.7), (x + size * 0.9, y - size * 1.7)],
           fill=60, width=1)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.4 * ss))
    m = np.asarray(overlay, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(color)), m)
    # lantern + glow
    glow = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([x - size * 0.5, y - size * 1.95, x + size * 0.5, y - size * 1.35], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.9))
    gm = np.asarray(glow, dtype=np.float64) / 255.0
    img[:] = screen(img, np.full_like(img, hx(light)), gm * 0.85)
    # reflection streak
    streak = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(streak)
    sd.ellipse([x - size * 0.45, y + size * 0.4, x + size * 0.45, y + size * 2.4],
               fill=70)
    streak = streak.filter(ImageFilter.GaussianBlur(size * 0.8))
    sm = np.asarray(streak, dtype=np.float64) / 255.0
    img[:] = screen(img, np.full_like(img, hx(light)), sm * 0.25)


def add_tent(img: np.ndarray, x: float, y: float, size: float,
             color: str, light: str, ss: float = 1.0) -> None:
    h, w = img.shape[:2]
    overlay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(overlay)
    d.polygon([(x - size, y), (x + size, y), (x, y - size * 0.95)], fill=240)
    d.polygon([(x - size * 0.32, y), (x + size * 0.32, y), (x, y - size * 0.5)], fill=100)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.5 * ss))
    m = np.asarray(overlay, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(color)), m)
    glow = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([x - size * 0.26, y - size * 0.4, x + size * 0.26, y - size * 0.05], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.7))
    gm = np.asarray(glow, dtype=np.float64) / 255.0
    img[:] = screen(img, np.full_like(img, hx(light)), gm * 0.9)


def _paste_rgba(img: np.ndarray, sprite: Image.Image, x: int, y: int,
                opacity: float = 1.0) -> None:
    pil = Image.fromarray(np.uint8(np.clip(img, 0, 255))).convert("RGBA")
    if opacity < 1.0:
        sprite = sprite.copy()
        alpha = sprite.getchannel("A").point(lambda v: int(v * opacity))
        sprite.putalpha(alpha)
    pil.alpha_composite(sprite, (int(x), int(y)))
    img[:] = np.asarray(pil.convert("RGB"), dtype=np.float64)


def _cabin_sprite(width: int) -> Image.Image:
    width = max(10, int(width))
    height = max(10, int(width * 0.96))
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    line = max(1, int(width * 0.012))

    for fx in (0.27, 0.42, 0.58, 0.73):
        d.line([(fx * width, 0.76 * height), (fx * width, height)],
               fill=(38, 23, 18, 255), width=line)

    d.rectangle([0.17 * width, 0.38 * height, 0.83 * width, 0.80 * height],
                fill=(148, 65, 46, 255))
    for fy in (0.52, 0.62, 0.72):
        d.line([(0.18 * width, fy * height), (0.82 * width, fy * height)],
               fill=(112, 46, 33, 230), width=1)

    d.polygon(
        [(0.06 * width, 0.41 * height), (0.5 * width, 0.07 * height),
         (0.94 * width, 0.41 * height)],
        fill=(54, 32, 26, 255),
    )
    d.line([(0.06 * width, 0.41 * height), (0.94 * width, 0.41 * height)],
           fill=(232, 212, 185, 235), width=max(1, int(width * 0.014)))
    d.line([(0.5 * width, 0.07 * height), (0.5 * width, 0.41 * height)],
           fill=(90, 40, 30, 200), width=max(1, int(width * 0.008)))

    for fx in (0.27, 0.58):
        x0, y0 = fx * width, 0.47 * height
        x1, y1 = (fx + 0.16) * width, 0.64 * height
        d.rectangle([x0, y0, x1, y1], fill=(255, 198, 126, 255))
        d.rectangle([x0, y0, x1, y1], outline=(71, 37, 29, 255), width=1)
        d.line([((x0 + x1) / 2, y0), ((x0 + x1) / 2, y1)],
               fill=(120, 60, 38, 220), width=1)

    d.rectangle([0.45 * width, 0.56 * height, 0.56 * width, 0.80 * height],
                fill=(61, 34, 28, 255))
    d.rectangle([0.46 * width, 0.58 * height, 0.55 * width, 0.76 * height],
                outline=(126, 76, 50, 180), width=1)
    return im


def add_cabins(img: np.ndarray, x: float, y: float, size: float,
               ss: float = 1.0) -> None:
    """A cluster of red rorbuer at the waterline, with warm windows."""
    widths = [size, size * 0.82, size * 0.66]
    offsets = [0.0, size * 0.72, size * 1.38]
    for i, (width, offset) in enumerate(zip(widths, offsets)):
        cabin = _cabin_sprite(width)
        left = int(x + offset)
        top = int(y - cabin.height)
        _paste_rgba(img, cabin, left, top)
        reflection = cabin.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        _paste_rgba(img, reflection, left, int(y + 2), opacity=0.16 - i * 0.02)


def _town_sprite(width: int) -> Image.Image:
    width = max(20, int(width))
    height = max(14, int(width * 0.34))
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    silhouette = (58, 29, 21, 255)
    silhouette_soft = (72, 37, 26, 255)
    warm = (255, 186, 111, 255)

    d.rectangle([0.0, 0.60 * height, 0.20 * width, height], fill=silhouette_soft)
    d.rectangle([0.12 * width, 0.48 * height, 0.28 * width, height], fill=silhouette)
    d.rectangle([0.28 * width, 0.58 * height, 0.38 * width, height], fill=silhouette_soft)
    d.rectangle([0.64 * width, 0.54 * height, 0.82 * width, height], fill=silhouette)
    d.rectangle([0.78 * width, 0.62 * height, 1.0 * width, height], fill=silhouette_soft)

    # the church tower, with a low pediment and a small cross
    d.rectangle([0.38 * width, 0.16 * height, 0.62 * width, height], fill=silhouette)
    d.polygon(
        [(0.34 * width, 0.18 * height), (0.50 * width, 0.02 * height),
         (0.66 * width, 0.18 * height)],
        fill=silhouette,
    )
    d.line([(0.50 * width, 0.02 * height), (0.50 * width, -0.06 * height)],
           fill=silhouette, width=max(1, int(width * 0.006)))
    d.line([(0.47 * width, -0.015 * height), (0.53 * width, -0.015 * height)],
           fill=silhouette, width=max(1, int(width * 0.006)))

    # a couple of side towers
    for cx in (0.22, 0.78):
        d.rectangle([(cx - 0.055) * width, 0.28 * height,
                     (cx + 0.055) * width, 0.58 * height], fill=silhouette)
        d.polygon(
            [((cx - 0.075) * width, 0.30 * height),
             (cx * width, 0.17 * height),
             ((cx + 0.075) * width, 0.30 * height)],
            fill=silhouette,
        )

    # lit windows
    for fx, fy in [
        (0.44, 0.28), (0.53, 0.38), (0.45, 0.52),
        (0.22, 0.36), (0.75, 0.40), (0.16, 0.70),
        (0.33, 0.74), (0.68, 0.67), (0.86, 0.76),
    ]:
        d.rectangle(
            [fx * width, fy * height, (fx + 0.025) * width, (fy + 0.06) * height],
            fill=warm,
        )
    return im


def add_town(img: np.ndarray, x: float, y: float, width: float) -> None:
    """A small Oaxacan town on the horizon: low roofs and a church tower."""
    town = _town_sprite(width)
    _paste_rgba(img, town, int(x - town.width / 2), int(y - town.height))


def scene_dunes(w: int, h: int, pal: dict, rng: random.Random,
                horizon: float = 0.55, detail: str | None = None, **_) -> np.ndarray:
    img = vgrad(w, h, pal["sky"])
    sun = (rng.uniform(0.58, 0.78), horizon - 0.04)
    img = add_glow(img, sun[0], sun[1], 0.7, pal["sun"], 0.5, 2.4)
    img = add_glow(img, sun[0], sun[1], 0.1, pal["sun"], 0.9, 1.3)

    # distant mesa
    n = w
    curve = np.zeros(n)
    x = np.linspace(0, 1, n)
    for _ in range(3):
        c = rng.uniform(0, 1)
        width = rng.uniform(0.16, 0.35)
        height = rng.uniform(0.25, 0.55)
        block = np.clip(1.0 - np.abs(x - c) / width, 0, 1) ** 0.35
        curve = np.maximum(curve, block * height)
    curve += 0.02 * fbm1d(n, rng)
    pts = curve_polygon(curve, w, h, horizon + 0.02, 0.11)
    img = paste_shape(img, pts, pal["far"], 0.8, 1.5 * SS)

    if detail == "town":
        add_town(img, 0.60 * w, (horizon + 0.025) * h, 0.20 * w)

    # dunes
    dune_colors = [pal["dune1"], pal["dune2"], pal["dune3"], pal["dune4"]]
    bases = [0.63, 0.72, 0.83, 0.98]
    for i, (color, base) in enumerate(zip(dune_colors, bases)):
        xs = np.linspace(0, 1, w)
        y = (np.sin(xs * math.tau * rng.uniform(0.8, 1.6) + rng.uniform(0, 6.28)) * 0.035
             + np.sin(xs * math.tau * rng.uniform(2.0, 3.3) + rng.uniform(0, 6.28)) * 0.012)
        y = y + base
        yy = (y * h).astype(int)
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        poly = [(0, h)] + [(int(x * w), int(yy[j])) for j, x in enumerate(xs)] + [(w, h)]
        d.polygon(poly, fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(1.0 * SS))
        m = np.asarray(mask, dtype=np.float64) / 255.0
        layer = np.zeros_like(img)
        layer[:] = hx(color)
        img = blend(img, layer, m)
        # sunlit rim along the crest
        rim = Image.new("L", (w, h), 0)
        rd = ImageDraw.Draw(rim)
        rd.line([(int(x * w), int(yy[j])) for j, x in enumerate(xs)],
                fill=110, width=max(2, int(2.5 * SS)))
        rim = rim.filter(ImageFilter.GaussianBlur(1.5 * SS))
        rm = np.asarray(rim, dtype=np.float64) / 255.0
        warm = np.zeros_like(img)
        warm[:] = hx(pal["sun"])
        img = blend(img, warm, rm * (0.32 - i * 0.05))

    img = haze_band(img, horizon, 0.08, pal["haze"], 0.35)
    # heat shimmer at horizon
    img = add_glow(img, 0.5, horizon, 0.35, pal["sun"], 0.15, 2.0)

    if detail in ("agave", "town"):
        add_agave(img, 0.78 * w, 0.86 * h, 0.065 * w, pal["deep"], SS)
    if detail == "tent":
        add_tent(img, 0.32 * w, 0.73 * h, 0.022 * w, pal["deep"], pal["sun"], SS)
    return img


def scene_forest(w: int, h: int, pal: dict, rng: random.Random, **_) -> np.ndarray:
    img = vgrad(w, h, [(0.0, pal["sky"][0][1]), (0.45, pal["sky"][1][1]),
                      (1.0, pal["sky"][3][1])])
    # soft light shaft
    shaft = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(shaft)
    outer = [(0.3 * w, 0), (0.58 * w, 0), (0.92 * w, h), (0.55 * w, h)]
    d.polygon(outer, fill=38)
    shaft = shaft.filter(ImageFilter.GaussianBlur(40 * SS))
    sm = np.asarray(shaft, dtype=np.float64) / 255.0
    warm = np.zeros_like(img)
    warm[:] = hx(pal["sun"])
    img = blend(img, warm, sm * 0.75)

    # far layer of trunks
    def trunks(layer_img, count, alpha, width_range, color, blur, y0=0.0, y1=1.0):
        for _ in range(count):
            x = rng.uniform(-0.05, 1.05) * w
            wd = rng.uniform(*width_range) * w
            lean = rng.uniform(-0.02, 0.02) * w
            mask = Image.new("L", (w, h), 0)
            dd = ImageDraw.Draw(mask)
            dd.polygon([(x, y0 * h), (x + wd, y0 * h),
                        (x + wd + lean, y1 * h), (x + lean, y1 * h)],
                       fill=int(255 * alpha))
            if blur:
                mask = mask.filter(ImageFilter.GaussianBlur(blur * SS))
            m = np.asarray(mask, dtype=np.float64) / 255.0
            col = np.zeros_like(layer_img)
            col[:] = hx(color)
            layer_img = blend(layer_img, col, m)
        return layer_img

    img = trunks(img, 26, 0.28, (0.006, 0.022), pal["far"], 3.0)
    img = haze_band(img, 0.55, 0.18, pal["haze"], 0.55)
    img = trunks(img, 13, 0.7, (0.012, 0.035), pal["stalk1"], 1.4)
    img = haze_band(img, 0.8, 0.2, pal["haze"], 0.28)
    img = trunks(img, 5, 0.92, (0.03, 0.075), pal["stalk2"], 0.5, y0=-0.02, y1=1.02)

    # bamboo nodes on the foreground stalks (approximation)
    node_mask = Image.new("L", (w, h), 0)
    nd = ImageDraw.Draw(node_mask)
    for _ in range(28):
        x = rng.uniform(0.05, 0.95) * w
        y = rng.uniform(0.2, 0.95) * h
        wd = rng.uniform(0.03, 0.08) * w
        nd.arc([x - wd, y - 4 * SS, x + wd, y + 4 * SS], 190, 350, fill=40, width=SS)
    node_mask = node_mask.filter(ImageFilter.GaussianBlur(2.0 * SS))
    nm = np.asarray(node_mask, dtype=np.float64) / 255.0
    warm = np.zeros_like(img)
    warm[:] = hx(pal["haze"])
    img = blend(img, warm, nm * 0.5)

    # a single red maple accent, softly out of focus
    img = paste_soft_ellipse(img, rng.uniform(0.68, 0.84), rng.uniform(0.18, 0.32),
                             0.035, 0.025, pal["accent"], 0.72, blur=10 * SS)
    img = paste_soft_ellipse(img, rng.uniform(0.12, 0.24), rng.uniform(0.72, 0.9),
                             0.05, 0.035, pal["accent"], 0.35, blur=22 * SS)
    img = add_glow(img, 0.5, 0.1, 0.8, pal["sun"], 0.12, 2.0)
    return img


def scene_cliffs(w: int, h: int, pal: dict, rng: random.Random,
                 horizon: float = 0.5, **_) -> np.ndarray:
    img = vgrad(w, h, pal["sky"])
    sun = (rng.uniform(0.6, 0.8), horizon - 0.1)
    img = add_glow(img, sun[0], sun[1], 0.55, pal["sun"], 0.35, 2.4)
    img = add_glow(img, sun[0], sun[1], 0.07, pal["sun"], 0.7, 1.6)

    # sea
    sea_y = int(h * horizon)
    sea = vgrad(w, h - sea_y, [(0.0, pal["haze"]), (0.25, pal["water1"]),
                                           (1.0, pal["water2"])])
    # sun path
    sea = screen(sea, np.full_like(sea, hx(pal["sun"])),
                 np.linspace(0.35, 0.0, sea.shape[0])[:, None] ** 1.2 * 0.5)
    img[sea_y:] = sea

    # distant headland, left
    n = w
    xs = np.linspace(0, 1, n)
    y = (horizon - 0.06
         - 0.10 * np.exp(-((xs - 0.02) / 0.16) ** 2)
         - 0.035 * np.exp(-((xs - 0.42) / 0.12) ** 2))
    yy = (y * h).astype(int)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.polygon([(0, h)] + [(int(x * w), int(yy[j])) for j, x in enumerate(xs)] + [(w, h)],
              fill=255)
    # only keep headland above sea
    mask_arr = np.asarray(mask, dtype=np.float64) / 255.0
    mask_arr[int(h * horizon):] = 0
    mask = Image.fromarray(np.uint8(mask_arr * 255)).filter(ImageFilter.GaussianBlur(2.0 * SS))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    col = np.zeros_like(img)
    col[:] = hx(pal["far"])
    img = blend(img, col, m * 0.85)
    img = haze_band(img, horizon - 0.03, 0.06, pal["haze"], 0.6)

    # mid headland right
    y2 = (horizon - 0.02
          - 0.16 * np.exp(-((xs - 1.02) / 0.28) ** 2)
          - 0.05 * np.exp(-((xs - 0.72) / 0.12) ** 2))
    yy2 = (y2 * h).astype(int)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.polygon([(w, h)] + [(int(x * w), int(yy2[j])) for j, x in enumerate(xs)] + [(0, h)],
              fill=255)
    mask_arr = np.asarray(mask, dtype=np.float64) / 255.0
    mask_arr[int(h * horizon) + 2 * SS:] = 0
    mask = Image.fromarray(np.uint8(mask_arr * 255)).filter(ImageFilter.GaussianBlur(2.5 * SS))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    col = np.zeros_like(img)
    col[:] = hx(pal["mid"])
    img = blend(img, col, m * 0.9)
    img = haze_band(img, horizon - 0.01, 0.04, pal["haze"], 0.45)

    # foreground cliff, bottom left
    cliff_noise = fbm1d(w, rng, octaves=4) * 0.16
    cliff_pts = [(0, h), (0, int(h * 0.62))]
    for j, x in enumerate(np.linspace(0, 0.6, w)):
        cy = 0.72 + cliff_noise[j] - 0.28 * np.exp(-((x - 0.02) / 0.4) ** 2)
        cliff_pts.append((int(x * w), int(cy * h)))
    cliff_pts += [(int(0.6 * w), h)]
    img = paste_shape(img, cliff_pts, pal["near"], alpha=0.97, blur=1.6 * SS)

    # grass rim light on the cliff
    img = paste_soft_ellipse(img, 0.1, 0.68, 0.16, 0.01, pal["accent"], 0.16, blur=8 * SS)

    # birds
    for _ in range(rng.randint(2, 5)):
        bx, by = rng.uniform(0.3, 0.9), rng.uniform(0.16, 0.35)
        size = rng.uniform(0.004, 0.009)
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        d.arc([(bx - size) * w, (by - size) * h, (bx + size) * w, (by + size) * h],
              200, 340, fill=120, width=SS)
        mask = mask.filter(ImageFilter.GaussianBlur(0.6 * SS))
        m = np.asarray(mask, dtype=np.float64) / 255.0
        col = np.zeros_like(img)
        col[:] = hx(pal["deep"])
        img = blend(img, col, m * 0.7)
    return img


def scene_lanterns(w: int, h: int, pal: dict, rng: random.Random,
                   horizon: float = 0.66, **_) -> np.ndarray:
    img = vgrad(w, h, pal["sky"])
    # distant dark bank
    y = horizon - 0.015
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    points = [(0, h)]
    xs = np.linspace(0, 1, w)
    for j, x in enumerate(xs):
        top = y - 0.022 * math.sin(x * 9 + 1.2) - 0.012 * math.sin(x * 23)
        points.append((int(x * w), int(top * h)))
    points.append((w, h))
    d.polygon(points, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.2 * SS))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    col = np.zeros_like(img)
    col[:] = hx(pal["deep"])
    img = blend(img, col, m)

    # lantern bokeh
    lantern_colors = ["#f4b663", "#f08a45", "#ffd9a0", "#e26f3b", "#f7c978"]
    orbs = []
    for _ in range(16):
        cx, cy = rng.uniform(0.03, 0.97), rng.uniform(0.03, horizon - 0.04)
        r = rng.uniform(0.012, 0.055)
        color = rng.choice(lantern_colors)
        strength = rng.uniform(0.35, 0.95)
        blur_amt = rng.choice([0, 0, 1, 2, 4])
        orbs.append((cx, cy, r, color, strength, blur_amt))
    # larger out-of-focus foreground orbs
    for _ in range(4):
        cx, cy = rng.uniform(0.0, 1.0), rng.uniform(0.05, horizon)
        r = rng.uniform(0.05, 0.11)
        color = rng.choice(lantern_colors)
        orbs.append((cx, cy, r, color, rng.uniform(0.12, 0.28), 14))
    for cx, cy, r, color, strength, blur_amt in orbs:
        layer = np.zeros_like(img)
        layer[:] = hx(color)
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        d.ellipse([(cx - r) * w, (cy - r * 0.8) * h, (cx + r) * w, (cy + r * 0.8) * h],
                  fill=255)
        if blur_amt:
            mask = mask.filter(ImageFilter.GaussianBlur(blur_amt * SS))
        m = np.asarray(mask, dtype=np.float64) / 255.0
        # soft inner falloff
        yy, xx = np.mgrid[0:h, 0:w]
        dist = np.sqrt(((xx / w - cx) / r) ** 2 + ((yy / h - cy) / (r * 0.8)) ** 2)
        m = m * np.clip(1.2 - dist, 0, 1) ** 1.2
        img = screen(img, layer, m * strength)

    # reflections
    water_y = int(horizon * h)
    for cx, cy, r, color, strength, _ in orbs[:16]:
        rw = r * rng.uniform(0.4, 0.9)
        rh = rng.uniform(0.04, 0.14)
        for k in range(5):
            yy0 = cy + 0.01 + k * rh * 0.55
            if yy0 > horizon + 0.3:
                break
            fade = 1.0 - k / 5
            mask = Image.new("L", (w, h), 0)
            d = ImageDraw.Draw(mask)
            d.ellipse([(cx - rw) * w, (yy0 - rh * 0.15) * h,
                       (cx + rw) * w, (yy0 + rh * 0.15) * h], fill=255)
            mask = mask.filter(ImageFilter.GaussianBlur(3.5 * SS))
            m = np.asarray(mask, dtype=np.float64) / 255.0
            m[:water_y] = 0
            layer = np.zeros_like(img)
            layer[:] = hx(color)
            img = screen(img, layer, m * strength * 0.18 * fade)

    # shimmer on the water
    img = add_glow(img, 0.5, horizon + 0.1, 0.6, pal["sun"], 0.12, 2.2)
    return img


def scene_arches(w: int, h: int, pal: dict, rng: random.Random, **_) -> np.ndarray:
    # sky seen through arches
    sky = vgrad(w, h, pal["sky"])
    sky = add_glow(sky, 0.74, 0.5, 0.3, pal["sun"], 0.5, 2.2)
    img = sky

    # warm wall
    wall = vgrad(w, h, [(0.0, pal["wall_light"]), (0.5, pal["wall"]), (1.0, pal["wall_shadow"])])
    wall = add_paper_grain(wall, np.random.default_rng(7), 3.0)
    wall_mask = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(wall_mask)

    # three keyhole arch openings
    arch_specs = [(0.26, 0.16, 0.34, 0.66, 0.34), (0.58, 0.10, 0.42, 0.78, 0.30),
                  (0.86, 0.22, 0.26, 0.58, 0.30)]
    for cx, top, width, bottom, _ in arch_specs:
        x0, x1 = (cx - width / 2) * w, (cx + width / 2) * w
        y0 = top * h
        y1 = bottom * h
        r = (x1 - x0) / 2
        d.rectangle([x0, y0 + r, x1, y1], fill=0)
        d.ellipse([x0, y0, x1, y0 + 2 * r], fill=0)
        # pointed tip
        d.polygon([(x0, y0 + r), (cx * w, y0 - 0.05 * h), (x1, y0 + r)], fill=0)
    wall_mask = wall_mask.filter(ImageFilter.GaussianBlur(0.8 * SS))
    m = np.asarray(wall_mask, dtype=np.float64)[:, :, None] / 255.0
    img = sky * (1 - m) + wall * m

    # inner shadow around the arch openings
    edge = Image.new("L", (w, h), 0)
    ed = ImageDraw.Draw(edge)
    for cx, top, width, bottom, _ in arch_specs:
        x0, x1 = (cx - width / 2) * w, (cx + width / 2) * w
        y0, y1 = top * h, bottom * h
        r = (x1 - x0) / 2
        ed.rectangle([x0, y0 + r, x1, y1], outline=255, width=int(2 * SS))
        ed.ellipse([x0, y0, x1, y0 + 2 * r], outline=255, width=int(2 * SS))
    edge = edge.filter(ImageFilter.GaussianBlur(5 * SS))
    em = np.asarray(edge, dtype=np.float64) / 255.0
    dark = np.zeros_like(img)
    dark[:] = hx(pal["deep"])
    img = blend(img, dark, em * 0.55)

    # sunlight falling on the floor
    floor_mask = Image.new("L", (w, h), 0)
    fd = ImageDraw.Draw(floor_mask)
    fd.polygon([(0.1 * w, h), (0.55 * w, 0.72 * h), (0.82 * w, 0.72 * h), (0.75 * w, h)],
               fill=255)
    floor_mask = floor_mask.filter(ImageFilter.GaussianBlur(30 * SS))
    fm = np.asarray(floor_mask, dtype=np.float64) / 255.0
    warm = np.zeros_like(img)
    warm[:] = hx(pal["sun"])
    img = screen(img, warm, fm * 0.18)

    # a small teal door for a jolt of colour
    x0, x1 = 0.44 * w, 0.52 * w
    y0, y1 = 0.70 * h, 0.9 * h
    door = Image.new("L", (w, h), 0)
    dd = ImageDraw.Draw(door)
    dd.rectangle([x0, y0, x1, y1], fill=255)
    dd.ellipse([x0, y0 - (x1 - x0) / 2, x1, y0 + (x1 - x0) / 2], fill=255)
    door = door.filter(ImageFilter.GaussianBlur(0.6 * SS))
    dm = np.asarray(door, dtype=np.float64) / 255.0
    teal = np.zeros_like(img)
    teal[:] = hx(pal["accent"])
    img = blend(img, teal, dm * 0.9)
    # wall stains
    for _ in range(9):
        img = paste_soft_ellipse(img, rng.uniform(0.02, 0.98), rng.uniform(0.05, 0.95),
                                 rng.uniform(0.03, 0.12), rng.uniform(0.02, 0.1),
                                 pal["wall_shadow"], 0.05, blur=16 * SS)
    return img



def add_treeline(img: np.ndarray, w: int, h: int, base_y: float, height: float,
                 color: str, alpha: float, blur: float, rng: random.Random) -> None:
    """A soft, lumpy canopy line — reads as distant trees in fog."""
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    step = max(2, int(0.006 * w))
    for x in range(-step, w + step, step):
        hh = height * (0.35 + 0.65 * rng.random())
        top = (base_y - hh) * h
        ww = step * rng.uniform(1.2, 2.2)
        d.ellipse([x - ww, top, x + ww, base_y * h + height * h], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(color)), m * alpha)


def scene_torii(w: int, h: int, pal: dict, rng: random.Random,
                horizon: float = 0.64, sun: tuple[float, float] = (0.62, 0.56), **_) -> np.ndarray:
    """A vermilion gate standing in still water, wrapped in morning fog."""
    img = vgrad(w, h, pal["sky"])
    img = add_glow(img, sun[0], sun[1], 0.5, pal["sun"], 0.30, 2.4)
    img = add_glow(img, sun[0], sun[1], 0.07, pal["sun"], 0.45, 1.7)

    # layered, misty forest
    add_treeline(img, w, h, horizon + 0.005, 0.055, pal["far"], 0.55, 5.0 * SS, rng)
    img = haze_band(img, horizon - 0.01, 0.05, pal["haze"], 0.45)
    add_treeline(img, w, h, horizon + 0.022, 0.075, pal["mid"], 0.8, 2.0 * SS, rng)
    img = haze_band(img, horizon, 0.035, pal["haze"], 0.35)
    add_treeline(img, w, h, horizon + 0.038, 0.10, pal["near"], 0.9, 0.6 * SS, rng)

    # gate
    gate = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(gate)
    cx, base = 0.52 * w, horizon * h
    pillar_h = 0.30 * h
    top = base - pillar_h
    inner_bottom, outer_bottom = 0.135 * w, 0.185 * w
    inner_top, outer_top = 0.115 * w, 0.158 * w
    pw = 0.026 * w
    # pillars lean slightly inward
    gd.polygon([(cx - outer_bottom, base), (cx - inner_bottom, base),
                (cx - inner_top, top), (cx - outer_top, top)], fill=255)
    gd.polygon([(cx + inner_bottom, base), (cx + outer_bottom, base),
                (cx + outer_top, top), (cx + inner_top, top)], fill=255)
    # top beam (kasagi) ? gently upturned ends
    ts = np.linspace(-1.0, 1.0, 80)
    bx = cx + ts * 0.245 * w
    by = top + 0.012 * h * ts ** 2
    beam_t = 0.030 * h
    upper = [(float(x), float(y)) for x, y in zip(bx, by)]
    lower = [(float(x), float(y + beam_t)) for x, y in zip(bx[::-1], by[::-1])]
    gd.polygon(upper + lower, fill=255)
    # second beam (nuki)
    ny = top + 0.075 * h
    gd.rectangle([cx - 0.19 * w, ny, cx + 0.19 * w, ny + 0.020 * h], fill=255)
    # centre strut
    gd.rectangle([cx - 0.010 * w, top + 0.030 * h, cx + 0.010 * w, ny], fill=255)
    gate = gate.filter(ImageFilter.GaussianBlur(0.5 * SS))
    gm = np.asarray(gate, dtype=np.float64) / 255.0
    gate_col = np.zeros_like(img)
    gate_col[:] = hx(pal["accent"])
    img = blend(img, gate_col, gm * 0.96)
    # darker right side of the pillars for volume
    shade = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(shade)
    sd.polygon([(cx - outer_bottom * 0.55, base), (cx - inner_bottom * 0.35, base),
                (cx - inner_top * 0.35, top), (cx - outer_top * 0.55, top)], fill=0)
    sd.polygon([(cx + inner_bottom * 0.55, base), (cx + outer_bottom * 0.85, base),
                (cx + outer_top * 0.85, top), (cx + inner_top * 0.55, top)], fill=140)
    sd.rectangle([cx + 0.09 * w, top + 0.012 * h, cx + 0.245 * w, top + 0.042 * h], fill=90)
    shade = shade.filter(ImageFilter.GaussianBlur(2.0 * SS))
    sm = np.asarray(shade, dtype=np.float64) / 255.0
    img = blend(img, np.zeros_like(img) + hx(pal["deep"]), sm * 0.35)

    # water, reflecting everything above
    water_y = int(horizon * h)
    above = img[:water_y].copy()
    water = vgrad(w, h - water_y, [(0.0, pal["far"]), (0.18, pal["mid"]), (1.0, pal["deep"])])
    refl = np.asarray(Image.fromarray(np.uint8(np.clip(above, 0, 255)))
                      .transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                      .resize((w, h - water_y), Image.Resampling.BILINEAR),
                      dtype=np.float64)
    fade = np.linspace(0.42, 0.02, h - water_y)[:, None, None]
    water = water * (1 - fade) + refl * fade * 0.8
    rows = np.arange(h - water_y)
    for r in range(h - water_y):
        shift = int((np.sin(r * 0.035) * 7.0 + np.sin(r * 0.13 + 2.0) * 2.0) * SS)
        water[r] = np.roll(water[r], shift, axis=0)
    water = np.asarray(Image.fromarray(np.uint8(np.clip(water, 0, 255)))
                       .filter(ImageFilter.GaussianBlur(1.6 * SS)), dtype=np.float64)
    img = img.copy()
    img[water_y:] = water
    img = haze_band(img, horizon, 0.02, pal["haze"], 0.35)
    # light rain rings on the water
    for _ in range(5):
        rx = rng.uniform(0.15, 0.9) * w
        ry = rng.uniform(horizon + 0.05, 0.95) * h
        rw = rng.uniform(0.02, 0.06) * w
        ring = Image.new("L", (w, h), 0)
        rd = ImageDraw.Draw(ring)
        rd.ellipse([rx - rw, ry - rw * 0.18, rx + rw, ry + rw * 0.18], outline=50,
                   width=max(1, int(SS)))
        ring = ring.filter(ImageFilter.GaussianBlur(1.5 * SS))
        rm = np.asarray(ring, dtype=np.float64) / 255.0
        img = screen(img, np.full_like(img, hx(pal["haze"])), rm * 0.4)
    return img


def scene_stacks(w: int, h: int, pal: dict, rng: random.Random,
                 horizon: float = 0.55, detail: str | None = None,
                 sun: tuple[float, float] = (0.68, 0.45), **_) -> np.ndarray:
    """Sea stacks in fog ? a quiet, wide coastal still."""
    img = vgrad(w, h, pal["sky"])
    img = add_glow(img, sun[0], sun[1], 0.5, pal["sun"], 0.35, 2.4)
    img = add_glow(img, sun[0], sun[1], 0.07, pal["sun"], 0.55, 1.7)
    img = haze_band(img, horizon, 0.12, pal["haze"], 0.55)

    # distant, almost-dissolved headland
    curve = ridge_curve(w, rng, jagged=False)
    img = paste_ridge(img, w, h, curve, horizon + 0.01, 0.035, pal["far"], pal["haze"],
                      alpha=0.55, blur=6.0 * SS, rim=0.05)
    img = haze_band(img, horizon, 0.035, pal["haze"], 0.55)

    # sea
    sea_y = int(horizon * h)
    sea = vgrad(w, h - sea_y, [(0.0, pal["haze"]), (0.22, pal["water1"]),
                              (1.0, pal["water2"])])
    sea = screen(sea, np.full_like(sea, hx(pal["sun"])),
                 np.linspace(0.30, 0.0, sea.shape[0])[:, None] ** 1.3 * 0.45)
    img[sea_y:] = sea

    # sea stacks (all sizes normalised so aspect ratio cannot distort them)
    stacks = []
    for i in range(3):
        cx = rng.uniform(0.18, 0.82)
        sh = rng.uniform(0.12, 0.22)  # fraction of image height
        sw = (sh * h / w) * rng.uniform(0.24, 0.40)  # fraction of image width
        if i == 0:
            cx, sh = rng.uniform(0.2, 0.32), 0.21
            sw = (sh * h / w) * 0.30
        stacks.append((cx, sh, sw))

    for i, (cx, sh, sw) in enumerate(stacks):
        n = 110
        u = np.linspace(0, 1, n)
        # columnar rock: steep sides, eroded crown, occasional notch
        crown = np.clip(1 - np.abs(2 * u - 1) ** 7, 0, 1) ** 0.25
        crown *= 0.88 + 0.20 * (fbm1d(n, rng, octaves=5, gain=0.5) + 1) / 2
        if i in (0, 1):
            notch_c = rng.uniform(0.32, 0.68)
            crown *= 1 - 0.28 * np.exp(-((u - notch_c) / rng.uniform(0.05, 0.09)) ** 2)
        crown[0] = crown[-1] = 0.0
        lean = rng.uniform(-0.015, 0.015) * (u - 0.5) * 2
        xs = (cx - sw / 2) + u * sw + lean * sw
        ys = (horizon - sh * crown) * h
        pts = [(float(xs[0] * w), float(sea_y))]
        pts += [(float(x * w), float(y)) for x, y in zip(xs, ys)]
        pts += [(float(xs[-1] * w), float(sea_y))]
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        d.polygon(pts, fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(1.0 * SS))
        m = np.asarray(mask, dtype=np.float64) / 255.0
        m[sea_y + 2 * SS:] = 0
        color = pal["deep"] if i == 0 else pal["near"]
        layer = vgrad(w, h, [(max(0.0, horizon - sh), pal["near"]),
                             (horizon, color)])
        img = img * (1 - m[:, :, None]) + layer * m[:, :, None]
        # rim light
        down = np.roll(m, 2 * SS, axis=0)
        edge = np.clip(m - down, 0, 1)
        edge = np.asarray(Image.fromarray(np.uint8(edge * 255))
                          .filter(ImageFilter.GaussianBlur(1.0 * SS)),
                          dtype=np.float64) / 255.0
        img = screen(img, np.full_like(img, hx(pal["haze"])), edge * 0.30)

    # warm ambient on the water
    img = add_glow(img, sun[0], horizon + 0.1, 0.25, pal["sun"], 0.08, 2.0)

    # mist around the stacks
    img = haze_band(img, horizon - 0.01, 0.06, pal["haze"], 0.4)

    # reflections
    above = img[:sea_y].copy()
    refl = np.asarray(Image.fromarray(np.uint8(np.clip(above, 0, 255)))
                      .transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                      .resize((w, h - sea_y), Image.Resampling.BILINEAR),
                      dtype=np.float64)
    fade = np.linspace(0.34, 0.02, h - sea_y)[:, None, None]
    water = img[sea_y:] * (1 - fade) + refl * fade
    rows = np.arange(h - sea_y)
    for r in range(h - sea_y):
        shift = int((np.sin(r * 0.07) * 4.0 + np.sin(r * 0.23 + 1.0) * 1.5) * SS)
        water[r] = np.roll(water[r], shift, axis=0)
    water = np.asarray(Image.fromarray(np.uint8(np.clip(water, 0, 255)))
                       .filter(ImageFilter.GaussianBlur(1.5 * SS)), dtype=np.float64)
    img = img.copy()
    img[sea_y:] = water

    # birds
    for _ in range(rng.randint(2, 5)):
        bx, by = rng.uniform(0.25, 0.85), rng.uniform(0.12, 0.4)
        size = rng.uniform(0.004, 0.009)
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        d.arc([(bx - size) * w, (by - size) * h, (bx + size) * w, (by + size) * h],
              200, 340, fill=120, width=max(1, int(SS)))
        mask = mask.filter(ImageFilter.GaussianBlur(0.6 * SS))
        m = np.asarray(mask, dtype=np.float64) / 255.0
        img = blend(img, np.full_like(img, hx(pal["deep"])), m * 0.7)

    if detail == "sailboat":
        add_sailboat(img, 0.64 * w, (horizon + 0.12) * h, 0.022 * w,
                     pal["deep"], pal["haze"], SS)
    return img


def add_sailboat(img: np.ndarray, x: float, y: float, size: float,
                 hull: str, sail: str, ss: float = 1.0) -> None:
    h, w = img.shape[:2]
    overlay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(overlay)
    d.polygon([(x - size, y), (x + size, y), (x + size * 0.55, y + size * 0.25),
               (x - size * 0.6, y + size * 0.25)], fill=235)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.4 * ss))
    m = np.asarray(overlay, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(hull)), m)
    smoke = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(smoke)
    sd.line([(x, y - size * 0.1), (x, y - size * 2.8)], fill=230, width=max(1, int(ss)))
    sd.polygon([(x, y - size * 2.7), (x + size * 1.15, y - size * 0.8),
                (x, y - size * 0.6)], fill=210)
    smoke = smoke.filter(ImageFilter.GaussianBlur(0.5 * ss))
    sm = np.asarray(smoke, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(sail)), sm * 0.92)


def _clamp_box(x0: float, y0: float, x1: float, y1: float, w: int, h: int):
    return (
        max(0, int(math.floor(x0))),
        max(0, int(math.floor(y0))),
        min(w, int(math.ceil(x1))),
        min(h, int(math.ceil(y1))),
    )


def _paint_mask(img, box, draw, blur, color, strength, use_screen):
    """Paint a soft shape inside a small ROI instead of the whole canvas."""
    h, w = img.shape[:2]
    x0, y0, x1, y1 = _clamp_box(*box, w, h)
    if x1 <= x0 or y1 <= y0:
        return
    mask = Image.new("L", (x1 - x0, y1 - y0), 0)
    draw(ImageDraw.Draw(mask), x0, y0)
    if blur > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask, dtype=np.float64) / 255.0
    region = img[y0:y1, x0:x1]
    layer = np.full_like(region, hx(color))
    alpha = np.clip(m * strength, 0.0, 1.0)
    img[y0:y1, x0:x1] = screen(region, layer, alpha) if use_screen else blend(region, layer, alpha)


def _soft_screen(img, box, ellipse, color, sigma, strength, scale=4):
    """A very soft, out-of-focus glow. Drawn at reduced resolution, then upscaled."""
    h, w = img.shape[:2]
    x0, y0, x1, y1 = _clamp_box(*box, w, h)
    if x1 <= x0 or y1 <= y0:
        return
    sw = max(2, (x1 - x0) // scale)
    sh = max(2, (y1 - y0) // scale)
    sx = sw / (x1 - x0)
    sy = sh / (y1 - y0)
    mask = Image.new("L", (sw, sh), 0)
    d = ImageDraw.Draw(mask)
    ex, ey, erx, ery = ellipse
    d.ellipse(
        [
            (ex - erx - x0) * sx,
            (ey - ery - y0) * sy,
            (ex + erx - x0) * sx,
            (ey + ery - y0) * sy,
        ],
        fill=255,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(max(0.6, sigma * (sx + sy) * 0.5)))
    mask = mask.resize((x1 - x0, y1 - y0), Image.Resampling.BILINEAR)
    m = np.asarray(mask, dtype=np.float64) / 255.0
    region = img[y0:y1, x0:x1]
    img[y0:y1, x0:x1] = screen(
        region,
        np.full_like(region, hx(color)),
        np.clip(m * strength, 0.0, 1.0),
    )


def draw_lantern(img: np.ndarray, cx: float, cy: float, rx: float, ry: float,
                 color: str, strength: float = 0.9) -> None:
    h, w = img.shape[:2]
    px, py = cx * w, cy * h
    prx, pry = rx * w, ry * h

    # Outer glow, kept inside a local box around the lantern.
    glow_sigma = max(2.0, prx * 0.55)
    pad = glow_sigma * 3 + 2
    _paint_mask(
        img,
        (px - prx * 2.4 - pad, py - pry * 2.2 - pad,
         px + prx * 2.4 + pad, py + pry * 2.2 + pad),
        lambda d, ox, oy: d.ellipse(
            [px - prx * 2.4 - ox, py - pry * 2.2 - oy,
             px + prx * 2.4 - ox, py + pry * 2.2 - oy],
            fill=255,
        ),
        glow_sigma, color, strength * 0.38, True,
    )

    # Paper body.
    _paint_mask(
        img,
        (px - prx - 5, py - pry - 5, px + prx + 5, py + pry + 5),
        lambda d, ox, oy: d.ellipse(
            [px - prx - ox, py - pry - oy, px + prx - ox, py + pry - oy],
            fill=255,
        ),
        0.8, color, 0.8, False,
    )

    # Hot centre.
    core_sigma = max(1.0, prx * 0.18)
    core_pad = core_sigma * 3 + 2
    _paint_mask(
        img,
        (px - prx * 0.62 - core_pad, py - pry * 0.72 - core_pad,
         px + prx * 0.62 + core_pad, py + pry * 0.5 + core_pad),
        lambda d, ox, oy: d.ellipse(
            [px - prx * 0.62 - ox, py - pry * 0.72 - oy,
             px + prx * 0.62 - ox, py + pry * 0.5 - oy],
            fill=255,
        ),
        core_sigma, "#ffe6b8", 0.38, True,
    )

    # Caps and tassel.
    def caps(d: ImageDraw.ImageDraw, ox: float, oy: float) -> None:
        d.rectangle(
            [px - prx * 0.55 - ox, py - pry * 1.02 - oy,
             px + prx * 0.55 - ox, py - pry * 0.78 - oy],
            fill=210,
        )
        d.rectangle(
            [px - prx * 0.5 - ox, py + pry * 0.8 - oy,
             px + prx * 0.5 - ox, py + pry * 1.0 - oy],
            fill=210,
        )
        d.line(
            [(px - ox, py + pry - oy), (px - ox, py + pry * 1.25 - oy)],
            fill=150,
            width=max(1, int(w * 0.001)),
        )

    _paint_mask(
        img,
        (px - prx * 0.55 - 5, py - pry * 1.02 - 5,
         px + prx * 0.55 + 5, py + pry * 1.25 + 5),
        caps, 0.6, "#3a2015", 0.75, False,
    )


def scene_lanterns(w: int, h: int, pal: dict, rng: random.Random,
                   horizon: float = 0.62, **_) -> np.ndarray:
    """A river of lanterns at night: strings, glow, and long reflections."""
    img = vgrad(w, h, pal["sky"])
    # faint stars, drawn small and blurred once
    stars = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(stars)
    for _ in range(60):
        sx, sy = rng.uniform(0, 1) * w, rng.uniform(0, horizon - 0.12) * h
        r = rng.uniform(0.4, 1.1) * SS
        sd.ellipse([sx - r, sy - r, sx + r, sy + r], fill=int(rng.uniform(60, 150)))
    stars = stars.filter(ImageFilter.GaussianBlur(0.8 * SS))
    sm = np.asarray(stars, dtype=np.float64) / 255.0
    img = screen(img, np.full_like(img, hx("#ffe7c2")), sm * 0.4)
    img = add_glow(img, 0.5, horizon, 0.6, pal["haze"], 0.12, 2.0)

    # far bank
    bank = fbm1d(w, rng, octaves=3) * 0.015
    pts = [(0, h)]
    for j, x in enumerate(np.linspace(0, 1, w)):
        pts.append((int(x * w), int((horizon - 0.012 + bank[j]) * h)))
    pts.append((w, h))
    img = paste_shape(img, pts, pal["deep"], alpha=0.98, blur=1.0 * SS)
    # a few lit windows on the bank
    for _ in range(12):
        bx, by = rng.uniform(0.02, 0.98) * w, rng.uniform(horizon - 0.02, horizon + 0.005) * h
        dot = Image.new("L", (w, h), 0)
        dd = ImageDraw.Draw(dot)
        r = rng.uniform(0.002, 0.005) * w
        dd.ellipse([bx - r, by - r, bx + r, by + r], fill=255)
        dot = dot.filter(ImageFilter.GaussianBlur(r * 1.5))
        dm = np.asarray(dot, dtype=np.float64) / 255.0
        img = screen(img, np.full_like(img, hx("#ffbf74")), dm * 0.6)

    water_y = int(horizon * h)

    water_grad = vgrad(w, h - water_y, [(0.0, pal["haze"]), (0.12, pal["water1"]),
                                        (0.5, pal["water1"]), (1.0, pal["water2"])])
    water_grad = screen(water_grad, np.full_like(water_grad, hx(pal["sun"])),
                        np.linspace(0.08, 0.0, water_grad.shape[0])[:, None] ** 1.4)
    above = img[:water_y]
    refl = np.asarray(Image.fromarray(np.uint8(np.clip(above, 0, 255)))
                      .transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                      .resize((w, h - water_y), Image.Resampling.BILINEAR),
                      dtype=np.float64)
    fade = np.linspace(0.35, 0.02, h - water_y)[:, None, None]
    water = water_grad * (1 - fade) + refl * fade
    rows = np.arange(h - water_y)
    for r in range(h - water_y):
        shift = int((np.sin(r * 0.08) * 5.0 + np.sin(r * 0.27) * 2.0) * SS)
        water[r] = np.roll(water[r], shift, axis=0)
    water = np.asarray(Image.fromarray(np.uint8(np.clip(water, 0, 255)))
                       .filter(ImageFilter.GaussianBlur(1.4 * SS)), dtype=np.float64)
    img[water_y:] = water

    # strings + lanterns
    lanterns = []
    for row, y0 in enumerate([0.10, 0.17, 0.25]):
        count = [7, 6, 5][row]
        sag = 0.035 + row * 0.012
        xs = np.linspace(-0.05, 1.05, 120)
        ys = y0 - sag * (1 - (2 * xs - 1) ** 2)
        line = Image.new("L", (w, h), 0)
        ld = ImageDraw.Draw(line)
        for j in range(len(xs) - 1):
            ld.line([(xs[j] * w, ys[j] * h), (xs[j + 1] * w, ys[j + 1] * h)],
                    fill=150, width=max(1, int(0.8 * SS)))
        lm = np.asarray(line.filter(ImageFilter.GaussianBlur(0.5 * SS)),
                        dtype=np.float64) / 255.0
        img = blend(img, np.full_like(img, hx("#21140f")), lm * 0.55)
        for k in range(count):
            t = (k + rng.uniform(0.45, 0.95)) / (count + 0.4)
            lx = t * w
            ly = (y0 - sag * (1 - (2 * t - 1) ** 2)) * h + rng.uniform(0.005, 0.08) * h
            rx = rng.uniform(0.014, 0.038) * w * (1.0 + row * 0.16)
            ry = rx * rng.uniform(1.15, 1.45)
            color = rng.choice(["#f6b25e", "#ef8a43", "#ffd39a", "#e46f36"])
            hang = Image.new("L", (w, h), 0)
            hd = ImageDraw.Draw(hang)
            hd.line([(lx, ly - ry * 1.6), (lx, ly - ry * 0.9)],
                    fill=100, width=max(1, int(0.7 * SS)))
            hm = np.asarray(hang.filter(ImageFilter.GaussianBlur(0.4 * SS)),
                            dtype=np.float64) / 255.0
            img = blend(img, np.full_like(img, hx("#2a1a12")), hm * 0.6)
            draw_lantern(img, lx / w, ly / h, rx / w, ry / h, color, 0.85)
            lanterns.append((lx, ly, rx, ry, color))

    # reflections of the lanterns
    for lx, ly, rx, ry, color in lanterns:
        if ly / h > horizon:
            continue
        for k in range(6):
            yy = (horizon + 0.015 + k * (ry / h) * 0.8) * h
            if yy > h:
                break
            rr = rx * (1.0 - k * 0.08)
            sx = lx + math.sin(k * 1.7) * rx * 0.5
            sigma = max(1.0, ry * 0.6)
            pad = sigma * 3 + 2
            _soft_screen(
                img,
                (sx - rr - pad, yy - ry * 0.13 - pad,
                 sx + rr + pad, yy + ry * 0.13 + pad),
                (sx, yy, rr, ry * 0.13),
                color, sigma, 0.85 - k * 0.09, scale=4,
            )

    # out-of-focus foreground lanterns
    for _ in range(2):
        fx, fy = rng.uniform(0.0, 1.0), rng.uniform(0.08, 0.4)
        r = rng.uniform(0.05, 0.09) * w
        sigma = max(1.0, r * 0.55)
        pad = sigma * 3 + 2
        _soft_screen(
            img,
            (fx * w - r - pad, fy * h - r - pad,
             fx * w + r + pad, fy * h + r + pad),
            (fx * w, fy * h, r, r),
            rng.choice(["#f4a95d", "#e98a49"]),
            sigma, 0.10, scale=8,
        )

    # small boat
    bx, by = 0.22 * w, (horizon + 0.17) * h
    add_boat(img, bx, by, 0.03 * w, pal["deep"], "#ffbf74", SS)
    return img


def add_agave(img: np.ndarray, x: float, y: float, size: float,
              color: str, ss: float = 1.0) -> None:
    h, w = img.shape[:2]
    overlay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(overlay)
    for angle in np.linspace(-150, -30, 9):
        a = math.radians(angle)
        tipx = x + math.cos(a) * size
        tipy = y + math.sin(a) * size
        wd = size * 0.075
        d.polygon([(x - wd, y), (x + wd, y),
                   (tipx + math.cos(a + 1.57) * 1.5, tipy),
                   (tipx - math.cos(a + 1.57) * 1.5, tipy)], fill=230)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.5 * ss))
    m = np.asarray(overlay, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(color)), m * 0.95)
    # a second, smaller plant
    overlay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(overlay)
    x2, y2, s2 = x - size * 0.8, y + size * 0.05, size * 0.45
    for angle in np.linspace(-160, -20, 7):
        a = math.radians(angle)
        d.polygon([(x2 - s2 * 0.08, y2), (x2 + s2 * 0.08, y2),
                   (x2 + math.cos(a) * s2, y2 + math.sin(a) * s2)], fill=210)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.5 * ss))
    m = np.asarray(overlay, dtype=np.float64) / 255.0
    img[:] = blend(img, np.full_like(img, hx(color)), m * 0.9)


SCENES = {
    "ridges": scene_ridges,
    "dunes": scene_dunes,
    "torii": scene_torii,
    "stacks": scene_stacks,
    "lanterns": scene_lanterns,
}

DESTINATIONS = [
    # id, scene, seed, special kwargs
    ("lofoten", "ridges", 11, {"jagged": True, "horizon": 0.62, "sun": (0.7, 0.56),
                               "detail": "cabins", "snow": True}),
    ("oaxaca", "dunes", 21, {"horizon": 0.56, "detail": "town"}),
    ("kyoto", "torii", 31, {"horizon": 0.64, "sun": (0.62, 0.55)}),
    ("faroe", "stacks", 41, {"horizon": 0.55, "sun": (0.72, 0.46)}),
    ("merzouga", "dunes", 51, {"horizon": 0.54, "detail": "tent"}),
    ("patagonia", "ridges", 61, {"jagged": True, "horizon": 0.64,
                                 "sun": (0.32, 0.5), "detail": "tent", "snow": True}),
    ("hoian", "lanterns", 71, {"horizon": 0.62}),
    ("sicily", "stacks", 81, {"horizon": 0.55, "sun": (0.64, 0.47),
                              "detail": "sailboat"}),
]

# image variants: (suffix, w, h, seed offset, kwargs)
VARIANTS = [
    ("01", 1200, 1600, 0, {"sun": (0.72, 0.55)}),
    ("02", 1800, 1200, 5, {"sun": (0.58, 0.5)}),
    ("03", 1200, 1200, 9, {"sun": (0.35, 0.52)}),
]


def render_destination(dest_id: str, scene_name: str, seed: int, kwargs: dict):
    pal = PALETTES[dest_id]
    scene_fn = SCENES[scene_name]
    for suffix, w, h, seed_off, overrides in VARIANTS:
        rng = random.Random(seed + seed_off * 17)
        ss_w, ss_h = prepare(w, h)
        kw = dict(kwargs)
        kw.update(overrides)
        # portrait composition gets a little more sky
        if suffix == "01" and "horizon" in kw:
            kw["horizon"] = min(0.72, kw["horizon"] + 0.04)
        img = scene_fn(ss_w, ss_h, pal, rng, **kw)
        leak = (rng.choice([0.02, 0.98]), rng.choice([0.02, 0.9]),
                pal.get("sun", "#ffd9a0"), rng.uniform(0.08, 0.18))
        out = finish(img, seed=seed * 100 + int(suffix), leak=leak)
        out = downsample(out, w, h, post_blur=0.45)
        path = OUT / f"{dest_id}_{suffix}.jpg"
        out.save(path, "JPEG", quality=88, optimize=True, progressive=True)
        print(f"  {path.name}  {w}x{h}")


def make_icon():
    size = 1024
    bg = "#b9502f"
    im = Image.new("RGB", (size, size), bg)
    d = ImageDraw.Draw(im)
    # large soft sun arc
    glow = Image.new("RGB", (size, size), bg)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-size * 0.15, -size * 0.1, size * 1.05, size * 1.15], fill="#c9633c")
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    im = Image.blend(im, glow, 0.7)
    # serif e
    font = ImageFont.truetype(str(ROOT / "assets/fonts/DMSerifDisplay-Regular.ttf"), 700)
    d = ImageDraw.Draw(im)
    text = "e"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - 30
    d.text((x, y), text, font=font, fill="#f4ecdd")
    # thin horizon line
    d.line([(size * 0.22, size * 0.8), (size * 0.78, size * 0.8)], fill="#e3b48d", width=5)
    im.save(ROOT / "assets" / "icon.png")
    print("  icon.png")


def make_grain():
    rng = np.random.default_rng(2)
    size = 256
    noise = rng.normal(0, 16, (size, size, 3))
    noise = np.clip(noise + 128, 0, 255).astype(np.uint8)
    Image.fromarray(noise, "RGB").save(ROOT / "assets" / "grain.png")
    print("  grain.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Render the Elsewhere stills.")
    parser.add_argument(
        "--only",
        nargs="+",
        default=None,
        help="Render only these destination ids (e.g. --only hoian sicily).",
    )
    parser.add_argument(
        "--no-media",
        action="store_true",
        help="Skip icon and grain generation.",
    )
    args = parser.parse_args()

    targets = DESTINATIONS
    if args.only:
        wanted = set(args.only)
        targets = [d for d in DESTINATIONS if d[0] in wanted]

    print("Rendering Elsewhere stills…", flush=True)
    for dest_id, scene_name, seed, kwargs in targets:
        print(f" {dest_id} ({scene_name})", flush=True)
        render_destination(dest_id, scene_name, seed, kwargs)
    if not args.no_media:
        make_icon()
        make_grain()
    print("Done.", flush=True)
