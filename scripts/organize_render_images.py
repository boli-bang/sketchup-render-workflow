#!/usr/bin/env python3
"""Rename selected render images and move duplicates to a backup folder."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff"}


def parse_range_list(value: str) -> list[int]:
    result: list[int] = []
    if not value:
        return result
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start_s, end_s = part.split("-", 1)
            start, end = int(start_s), int(end_s)
            if start > end:
                raise argparse.ArgumentTypeError(f"Invalid range: {part}")
            result.extend(range(start, end + 1))
        else:
            result.append(int(part))
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Organize downloaded render images.")
    parser.add_argument("folder", type=Path, help="Folder containing downloaded images.")
    parser.add_argument("--prefix", default="AI效果图", help="Output filename prefix.")
    parser.add_argument("--keep", required=True, type=parse_range_list, help="1-based indices to keep, e.g. 1-13 or 1-11,14,13.")
    parser.add_argument("--duplicates", default="", type=parse_range_list, help="1-based indices to move to _重复备份.")
    parser.add_argument("--sort", choices=["mtime", "name"], default="mtime", help="Sort order before indexing.")
    parser.add_argument("--copy-to", type=Path, help="Optional folder to copy final renamed files into.")
    return parser.parse_args()


def image_files(folder: Path, sort: str) -> list[Path]:
    files = [p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTS]
    if sort == "name":
        return sorted(files, key=lambda p: p.name)
    return sorted(files, key=lambda p: (p.stat().st_mtime, p.name))


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    for i in range(1, 1000):
        candidate = path.with_name(f"{path.stem}_{i}{path.suffix}")
        if not candidate.exists():
            return candidate
    raise RuntimeError(f"Could not find unique path for {path}")


def main() -> None:
    args = parse_args()
    folder = args.folder.expanduser().resolve()
    files = image_files(folder, args.sort)
    if not files:
        raise SystemExit(f"No images found in {folder}")

    max_index = len(files)
    for idx in args.keep + args.duplicates:
        if idx < 1 or idx > max_index:
            raise SystemExit(f"Index {idx} is out of range 1-{max_index}")

    duplicate_set = set(args.duplicates)
    keep_indices = args.keep
    overlap = set(keep_indices) & duplicate_set
    if overlap:
        raise SystemExit(f"Indices cannot be both kept and duplicate: {sorted(overlap)}")

    backup = folder / "_重复备份"
    backup.mkdir(exist_ok=True)
    for idx in args.duplicates:
        src = files[idx - 1]
        if src.exists():
            src.rename(unique_path(backup / src.name))

    temp_paths: list[Path] = []
    for out_num, idx in enumerate(keep_indices, 1):
        src = files[idx - 1]
        if not src.exists():
            raise SystemExit(f"Missing source after duplicate move: {src}")
        tmp = unique_path(folder / f"__tmp_render_rename_{out_num:02d}{src.suffix.lower()}")
        src.rename(tmp)
        temp_paths.append(tmp)

    final_paths: list[Path] = []
    for out_num, tmp in enumerate(temp_paths, 1):
        dst = folder / f"{args.prefix}_{out_num:02d}.png"
        if dst.exists():
            dst.rename(unique_path(folder / f"__old_{dst.name}"))
        tmp.rename(dst)
        final_paths.append(dst)

    if args.copy_to:
        copy_to = args.copy_to.expanduser().resolve()
        copy_to.mkdir(parents=True, exist_ok=True)
        for path in final_paths:
            shutil.copy2(path, copy_to / path.name)

    print("renamed:")
    for path in final_paths:
        print(path)
    if args.duplicates:
        print("duplicates moved to:")
        print(backup)


if __name__ == "__main__":
    main()
