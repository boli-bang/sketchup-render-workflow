#!/usr/bin/env python3
"""Create a labeled contact sheet for a folder of images."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a contact sheet from images in a folder.")
    parser.add_argument("folder", type=Path, help="Folder containing images.")
    parser.add_argument("--output", type=Path, help="Output JPG/PNG path. Defaults inside the folder.")
    parser.add_argument("--sort", choices=["mtime", "name"], default="mtime", help="Sort order.")
    parser.add_argument("--cols", type=int, default=3, help="Number of columns.")
    parser.add_argument("--thumb-width", type=int, default=320)
    parser.add_argument("--thumb-height", type=int, default=180)
    return parser.parse_args()


def image_files(folder: Path, sort: str) -> list[Path]:
    files = [p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTS]
    if sort == "name":
        return sorted(files, key=lambda p: p.name)
    return sorted(files, key=lambda p: (p.stat().st_mtime, p.name))


def main() -> None:
    args = parse_args()
    folder = args.folder.expanduser().resolve()
    files = image_files(folder, args.sort)
    if not files:
        raise SystemExit(f"No images found in {folder}")

    cols = max(1, args.cols)
    thumb_w = max(80, args.thumb_width)
    thumb_h = max(80, args.thumb_height)
    label_h = 42
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + label_h)), "white")
    draw = ImageDraw.Draw(sheet)

    for i, path in enumerate(files, 1):
        image = Image.open(path).convert("RGB")
        image.thumbnail((thumb_w, thumb_h))
        cell_x = ((i - 1) % cols) * thumb_w
        cell_y = ((i - 1) // cols) * (thumb_h + label_h)
        x = cell_x + (thumb_w - image.width) // 2
        y = cell_y
        sheet.paste(image, (x, y))
        label = f"{i:02d} {path.name}"
        draw.text((cell_x + 6, cell_y + thumb_h + 4), label, fill=(0, 0, 0))

    output = args.output or folder / "_contact_sheet.jpg"
    output = output.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=90)
    print(output)
    for i, path in enumerate(files, 1):
        print(f"{i:02d}\t{path.name}\t{path.stat().st_size}")


if __name__ == "__main__":
    main()
