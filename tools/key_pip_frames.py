"""Chroma-key Pip mascot frames onto a shared transparent canvas."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

SESSION = Path(
    r"C:\Users\Administrator\.grok\sessions"
    r"\E%3A%5CAI%20Work%5CAppPiPi\01a02c64-5a28-7653-94ca-cacc2f7eeb9e\images"
)
OUT = Path(r"E:\AI Work\AppPiPi\AppPiPi\Pip\iOS\Resources\Assets.xcassets\PipFrames")
SHEET = Path(r"E:\AI Work\AppPiPi\AppPiPi\tools\pip_frame_sheet.png")

KEY = np.array([212.0, 59.0, 116.0])
CANVAS = 1024

# source jpg -> asset names (same pixels may be copied to more than one name)
MAPPING: list[tuple[str, list[str]]] = [
    ("1.jpg", ["idle", "release3"]),
    ("2.jpg", ["waiting"]),
    ("3.jpg", ["done"]),
    ("9.jpg", ["lift1"]),
    ("4.jpg", ["lift2"]),
    ("8.jpg", ["lift3", "lift"]),
    ("5.jpg", ["lift4"]),
    ("11.jpg", ["release1", "release"]),
    ("10.jpg", ["release2"]),
]


def _erode(mask: np.ndarray, radius: int = 1) -> np.ndarray:
    from numpy.lib.stride_tricks import sliding_window_view

    padded = np.pad(mask.astype(np.uint8), radius, mode="constant")
    size = radius * 2 + 1
    windows = sliding_window_view(padded, (size, size))
    return windows.min(axis=(2, 3)).astype(bool)


def key_rgba(path: Path) -> np.ndarray:
    rgb = np.array(Image.open(path).convert("RGB"), dtype=np.float32)
    dist = np.linalg.norm(rgb - KEY, axis=2)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    is_outline = luma < 78
    is_magenta = (r > g + 22) & (r > 130) & (g < 140) & (b > 50)

    alpha = np.clip((dist - 40.0) / 28.0, 0.0, 1.0)
    alpha = np.where(is_magenta & ~is_outline, 0.0, alpha)
    alpha = np.where(is_outline & (dist > 24), 1.0, alpha)
    alpha = _erode(alpha > 0.55, radius=1).astype(np.float32)
    # Soften the cut by a 1px average with the original mask.
    hard = alpha
    alpha = np.clip(hard * 0.82 + (1.0 - is_magenta.astype(np.float32)) * 0.18, 0.0, 1.0)
    alpha = np.where(is_magenta & ~is_outline, 0.0, alpha)

    out = rgb.copy()
    spill = np.clip(1.0 - dist / 90.0, 0.0, 1.0)
    out[:, :, 0] = np.clip(out[:, :, 0] - spill * 70.0, 0, 255)
    out[:, :, 2] = np.clip(out[:, :, 2] - spill * 28.0, 0, 255)
    # Pull remaining magenta-tinted outline toward ink.
    ink = np.array([31.0, 41.0, 43.0])
    outline_mix = np.clip((78.0 - luma) / 78.0, 0.0, 1.0) * is_outline.astype(np.float32)
    out = out * (1.0 - outline_mix)[..., None] + ink * outline_mix[..., None]

    rgba = np.dstack([out, alpha * 255.0]).astype(np.uint8)
    rgba[rgba[:, :, 3] < 12, 3] = 0
    return rgba


def write_imageset(name: str, image: Image.Image) -> None:
    folder = OUT / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    png_path = folder / f"{name}.png"
    image.save(png_path, "PNG", optimize=True)
    (folder / "Contents.json").write_text(
        """{
  "images" : [
    {
      "filename" : "%s.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
        % name,
        encoding="utf-8",
    )
    for leftover in ("idle.svg", "lift.svg", "release.svg", "done.svg"):
        old = folder / leftover
        if old.exists():
            old.unlink()


def main() -> None:
    keyed: dict[str, np.ndarray] = {}
    for src, names in MAPPING:
        rgba = key_rgba(SESSION / src)
        keyed[src] = rgba
        print(f"{src}: opaque={(rgba[:, :, 3] > 8).sum()} px")

    frames: dict[str, Image.Image] = {}
    for src, names in MAPPING:
        img = Image.fromarray(keyed[src], "RGBA")
        for name in names:
            frames[name] = img
            write_imageset(name, img)
            print(f"wrote {name}")

    order = ["idle", "lift1", "lift2", "lift3", "lift4", "release1", "release2", "release3", "waiting", "done"]
    thumb = 220
    sheet = Image.new("RGBA", (thumb * 5, thumb * 2), (40, 40, 40, 255))
    for i, name in enumerate(order):
        cell = frames[name].resize((thumb, thumb), Image.Resampling.LANCZOS)
        sheet.paste(cell, ((i % 5) * thumb, (i // 5) * thumb), cell)
    sheet.convert("RGB").save(SHEET)
    print("sheet", SHEET)


if __name__ == "__main__":
    main()
