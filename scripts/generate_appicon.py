"""Generate 1024x1024 AppIcon variants for footstepeR (light, dark, tinted).

Run from repo root:
    python3 scripts/generate_appicon.py

Writes Stepper/Assets.xcassets/AppIcon.appiconset/AppIcon-{Light,Dark,Tinted}.png
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "Stepper" / "Assets.xcassets" / "AppIcon.appiconset"


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def diagonal_gradient(start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * SIZE - 2)
            px[x, y] = lerp(start, end, t)
    return img


def draw_grid(img: Image.Image, alpha: int, step: int = 64) -> None:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    color = (255, 255, 255, alpha)
    for x in range(0, SIZE, step):
        draw.line([(x, 0), (x, SIZE)], fill=color, width=1)
    for y in range(0, SIZE, step):
        draw.line([(0, y), (SIZE, y)], fill=color, width=1)
    img.alpha_composite(overlay)


def draw_footprint(img: Image.Image, body_color: tuple[int, int, int, int], glow_color: tuple[int, int, int, int]) -> None:
    """Stylized footprint silhouette in the center."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    cx, cy = SIZE // 2, SIZE // 2

    # Heel (large ellipse)
    heel_w, heel_h = 380, 320
    draw.ellipse(
        [cx - heel_w // 2, cy + 30, cx + heel_w // 2, cy + 30 + heel_h],
        fill=body_color,
    )

    # Ball of foot (smaller ellipse above)
    ball_w, ball_h = 320, 220
    draw.ellipse(
        [cx - ball_w // 2 + 30, cy - 270, cx + ball_w // 2 + 30, cy - 270 + ball_h],
        fill=body_color,
    )

    # Toes (5 small circles)
    toe_positions = [
        (cx - 100, cy - 320, 70),
        (cx - 25, cy - 360, 60),
        (cx + 50, cy - 380, 55),
        (cx + 120, cy - 365, 50),
        (cx + 185, cy - 340, 45),
    ]
    for tx, ty, r in toe_positions:
        draw.ellipse([tx - r, ty - r, tx + r, ty + r], fill=body_color)

    # Glow halo
    glow = layer.copy()
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    glow_draw.ellipse([cx - 480, cy - 480, cx + 480, cy + 480], fill=glow_color)
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=120))

    img.alpha_composite(glow_layer)
    img.alpha_composite(layer)


def add_corner_neon(img: Image.Image, color: tuple[int, int, int, int]) -> None:
    """Soft glow blobs in opposite corners."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse([-200, -200, 400, 400], fill=color)
    draw.ellipse([SIZE - 400, SIZE - 400, SIZE + 200, SIZE + 200], fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(radius=180))
    img.alpha_composite(layer)


def make_light() -> Image.Image:
    base = diagonal_gradient((22, 14, 60), (8, 50, 110)).convert("RGBA")
    add_corner_neon(base, (138, 43, 226, 110))   # purple
    add_corner_neon(base, (0, 200, 255, 80))     # cyan (cumulative)
    draw_grid(base, alpha=18)
    draw_footprint(
        base,
        body_color=(0, 220, 255, 255),
        glow_color=(0, 220, 255, 70),
    )
    return base


def make_dark() -> Image.Image:
    base = diagonal_gradient((4, 6, 18), (16, 8, 36)).convert("RGBA")
    add_corner_neon(base, (138, 43, 226, 130))
    add_corner_neon(base, (255, 64, 129, 60))
    draw_grid(base, alpha=22)
    draw_footprint(
        base,
        body_color=(160, 80, 255, 255),
        glow_color=(160, 80, 255, 90),
    )
    return base


def make_tinted() -> Image.Image:
    """Monochrome variant on transparent background.

    Apple Human Interface Guidelines: the tinted variant is a single-channel
    grayscale + alpha image; the system colorises it using the user's tint.
    Keep it RGBA — actool rejects a fully opaque tinted layer.
    """
    base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_footprint(
        base,
        body_color=(255, 255, 255, 255),
        glow_color=(255, 255, 255, 60),
    )
    return base


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, factory, mode in (
        ("AppIcon-Light", make_light, "RGB"),
        ("AppIcon-Dark", make_dark, "RGB"),
        ("AppIcon-Tinted", make_tinted, "RGBA"),
    ):
        img = factory()
        if mode == "RGB":
            # Light/Dark icons must be fully opaque.
            img = img.convert("RGB")
        else:
            img = img.convert("RGBA")
        path = OUT / f"{name}.png"
        img.save(path, "PNG", optimize=True)
        print(f"wrote {path} mode={img.mode}")


if __name__ == "__main__":
    main()
