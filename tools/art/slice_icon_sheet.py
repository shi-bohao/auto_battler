#!/usr/bin/env python3
"""Clean grid lines, slice an icon sheet, and center each icon."""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path


BLANK_ALPHA_THRESHOLD = 8
SUBJECT_ALPHA_THRESHOLD = 16


@dataclass
class LineScanStats:
    axis: str
    boundary_index: int
    position: int
    total_pixels: int
    nontransparent_pixels: int = 0
    line_like_pixels: int = 0
    dominant_bucket: str = ""
    dominant_count: int = 0
    should_erase: bool = False

    def ratios(self) -> tuple[float, float, float, float]:
        nontransparent_ratio = (
            self.nontransparent_pixels / self.total_pixels if self.total_pixels else 0.0
        )
        line_like_ratio = self.line_like_pixels / self.total_pixels if self.total_pixels else 0.0
        dominant_total_ratio = self.dominant_count / self.total_pixels if self.total_pixels else 0.0
        dominant_line_like_ratio = (
            self.dominant_count / self.line_like_pixels if self.line_like_pixels else 0.0
        )
        return (
            nontransparent_ratio,
            line_like_ratio,
            dominant_total_ratio,
            dominant_line_like_ratio,
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove sheet separator lines, slice cells, and center subjects."
    )
    parser.add_argument("--input", required=True, help="Transparent source sheet.")
    parser.add_argument("--output-dir", required=True, help="Directory for sliced icons.")
    parser.add_argument("--cols", type=int, default=4, help="Sheet columns. Default: 4")
    parser.add_argument("--rows", type=int, default=4, help="Sheet rows. Default: 4")
    parser.add_argument(
        "--names-file",
        help="UTF-8 text file containing one output name per line. Extension is optional.",
    )
    parser.add_argument(
        "--prefix",
        default="icon",
        help="Fallback output filename prefix when names-file is omitted. Default: icon",
    )
    parser.add_argument(
        "--start-index",
        type=int,
        default=1,
        help="Fallback numbering start when names-file is omitted. Default: 1",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        help="Maximum number of cells to output. Default: cols * rows",
    )
    parser.add_argument(
        "--cleaned-output",
        help="Optional path to save the full cleaned transparent sheet.",
    )
    parser.add_argument(
        "--manifest-output",
        help="Optional CSV manifest path. Default: <output-dir>/icon_manifest.csv",
    )
    parser.add_argument(
        "--grid-scan-output",
        help="Optional CSV grid scan path. Default: <output-dir>/grid_scan.csv",
    )
    parser.add_argument(
        "--scan-radius",
        type=int,
        default=16,
        help="Pixels scanned around each expected grid boundary. Default: 16",
    )
    parser.add_argument(
        "--cut-search-radius",
        type=int,
        default=24,
        help="Pixels searched around each expected cut boundary. Default: 24",
    )
    parser.add_argument(
        "--clear-neighbor-radius",
        type=int,
        default=1,
        help="Also clear this many neighboring rows/columns around detected grid lines. Default: 1",
    )
    parser.add_argument(
        "--output-size",
        help="Optional final square or WxH canvas, for example 96 or 128x128.",
    )
    parser.add_argument(
        "--no-center",
        action="store_true",
        help="Disable subject centering after slicing.",
    )
    return parser.parse_args()


def is_line_like_pixel(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a < BLANK_ALPHA_THRESHOLD:
        return False
    max_value = max(r, g, b)
    min_value = min(r, g, b)
    if max_value <= 0:
        return True
    saturation = (max_value - min_value) / max_value
    return saturation <= 0.32


def quantize_line_pixel(pixel: tuple[int, int, int, int]) -> str:
    r, g, b, a = pixel
    return f"{a // 16}:{r // 24}:{g // 24}:{b // 24}"


def analyze_line(
    image: Image.Image,
    axis: str,
    boundary_index: int,
    position: int,
) -> LineScanStats:
    width, height = image.size
    pixels = image.load()
    total = height if axis == "column" else width
    stats = LineScanStats(axis, boundary_index, position, total)
    buckets: dict[str, int] = {}

    for i in range(total):
        pixel = pixels[position, i] if axis == "column" else pixels[i, position]
        if pixel[3] <= 0:
            continue
        stats.nontransparent_pixels += 1
        if not is_line_like_pixel(pixel):
            continue
        stats.line_like_pixels += 1
        key = quantize_line_pixel(pixel)
        buckets[key] = buckets.get(key, 0) + 1

    for key, value in buckets.items():
        if value > stats.dominant_count:
            stats.dominant_bucket = key
            stats.dominant_count = value

    stats.should_erase = should_erase_line(stats)
    return stats


def should_erase_line(stats: LineScanStats) -> bool:
    if stats.total_pixels <= 0:
        return False
    _, line_like_ratio, dominant_total_ratio, dominant_line_like_ratio = stats.ratios()
    if line_like_ratio >= 0.18 and dominant_total_ratio >= 0.035:
        return True
    if line_like_ratio >= 0.28 and dominant_line_like_ratio >= 0.12:
        return True
    if dominant_total_ratio >= 0.10:
        return True
    return False


def detect_grid_lines(
    image: Image.Image,
    axis: str,
    divisions: int,
    scan_radius: int,
) -> tuple[list[bool], list[LineScanStats]]:
    width, height = image.size
    limit = width if axis == "column" else height
    mask = [False] * limit
    scan_rows: list[LineScanStats] = []

    for boundary_index in range(divisions + 1):
        center = round(boundary_index * limit / divisions)
        start = max(0, center - scan_radius)
        end = min(limit - 1, center + scan_radius)
        for position in range(start, end + 1):
            stats = analyze_line(image, axis, boundary_index, position)
            scan_rows.append(stats)
            if stats.should_erase:
                mask[position] = True
    return mask, scan_rows


def is_marked_or_neighbor(mask: list[bool], index: int, radius: int) -> bool:
    for offset in range(-radius, radius + 1):
        i = index + offset
        if 0 <= i < len(mask) and mask[i]:
            return True
    return False


def clear_grid_lines(
    image: Image.Image,
    column_mask: list[bool],
    row_mask: list[bool],
    neighbor_radius: int,
) -> Image.Image:
    output = image.copy()
    pixels = output.load()
    width, height = output.size
    for y in range(height):
        row_marked = is_marked_or_neighbor(row_mask, y, neighbor_radius)
        for x in range(width):
            if row_marked or is_marked_or_neighbor(column_mask, x, neighbor_radius):
                pixels[x, y] = (0, 0, 0, 0)
    return output


def count_nonblank_pixels_on_line(image: Image.Image, axis: str, position: int) -> int:
    width, height = image.size
    pixels = image.load()
    total = height if axis == "column" else width
    count = 0
    for i in range(total):
        pixel = pixels[position, i] if axis == "column" else pixels[i, position]
        if pixel[3] >= BLANK_ALPHA_THRESHOLD:
            count += 1
    return count


def is_blank_line(image: Image.Image, axis: str, position: int) -> bool:
    return count_nonblank_pixels_on_line(image, axis, position) == 0


def is_boundary_candidate(mask: list[bool], position: int, mode: int) -> bool:
    if mode == 2:
        return True
    if 0 <= position < len(mask) and mask[position]:
        return True
    if mode == 1:
        return (
            (0 <= position - 1 < len(mask) and mask[position - 1])
            or (0 <= position + 1 < len(mask) and mask[position + 1])
        )
    return False


def find_blank_boundary(
    image: Image.Image,
    mask: list[bool],
    axis: str,
    expected: int,
    start: int,
    end: int,
    mode: int,
    search_radius: int,
) -> int | None:
    for offset in range(search_radius + 1):
        left = expected - offset
        if (
            start <= left <= end
            and is_boundary_candidate(mask, left, mode)
            and is_blank_line(image, axis, left)
        ):
            return left
        right = expected + offset
        if (
            right != left
            and start <= right <= end
            and is_boundary_candidate(mask, right, mode)
            and is_blank_line(image, axis, right)
        ):
            return right
    return None


def find_least_filled_boundary(
    image: Image.Image,
    mask: list[bool],
    axis: str,
    expected: int,
    start: int,
    end: int,
) -> int:
    best = expected
    best_key: tuple[int, int, int] | None = None
    for position in range(start, end + 1):
        if is_boundary_candidate(mask, position, 0):
            priority = 0
        elif is_boundary_candidate(mask, position, 1):
            priority = 1
        else:
            priority = 2
        count = count_nonblank_pixels_on_line(image, axis, position)
        key = (count, priority, abs(position - expected))
        if best_key is None or key < best_key:
            best = position
            best_key = key
    return best


def choose_cut_boundary(
    image: Image.Image,
    mask: list[bool],
    axis: str,
    expected: int,
    search_radius: int,
) -> int:
    limit = image.size[0] if axis == "column" else image.size[1]
    start = max(1, expected - search_radius)
    end = min(limit - 1, expected + search_radius)
    for mode in (0, 1, 2):
        boundary = find_blank_boundary(
            image, mask, axis, expected, start, end, mode, search_radius
        )
        if boundary is not None:
            return boundary
    return find_least_filled_boundary(image, mask, axis, expected, start, end)


def build_cut_boundaries(
    image: Image.Image,
    mask: list[bool],
    axis: str,
    divisions: int,
    search_radius: int,
) -> list[int]:
    limit = image.size[0] if axis == "column" else image.size[1]
    boundaries = [0] * (divisions + 1)
    boundaries[0] = 0
    boundaries[-1] = limit
    for i in range(1, divisions):
        expected = round(i * limit / divisions)
        boundaries[i] = choose_cut_boundary(image, mask, axis, expected, search_radius)
    for i in range(1, divisions):
        min_value = boundaries[i - 1] + 1
        max_value = limit - (divisions - i)
        boundaries[i] = max(min_value, min(max_value, boundaries[i]))
    return boundaries


def parse_output_size(value: str | None) -> tuple[int, int] | None:
    if not value:
        return None
    if "x" in value.lower():
        width_text, height_text = value.lower().split("x", 1)
        return (int(width_text), int(height_text))
    size = int(value)
    return (size, size)


def load_names(path_text: str | None, total: int, prefix: str, start_index: int) -> list[str]:
    if not path_text:
        return [f"{prefix}_{start_index + i}" for i in range(total)]
    names: list[str] = []
    with Path(path_text).open("r", encoding="utf-8-sig") as file:
        for line in file:
            name = line.strip()
            if name and not name.startswith("#"):
                names.append(Path(name).stem)
    if len(names) < total:
        raise SystemExit(f"Not enough names in {path_text}: need {total}, got {len(names)}")
    return names


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    pixels = image.load()
    width, height = image.size
    min_x, min_y = width, height
    max_x, max_y = -1, -1
    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] < SUBJECT_ALPHA_THRESHOLD:
                continue
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
    if max_x < min_x or max_y < min_y:
        return None
    return (min_x, min_y, max_x + 1, max_y + 1)


def paste_centered(source: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - source.size[0]) // 2
    y = (canvas_size[1] - source.size[1]) // 2
    canvas.alpha_composite(source, (x, y))
    return canvas


def center_subject(image: Image.Image) -> Image.Image:
    bbox = alpha_bbox(image)
    if bbox is None:
        return Image.new("RGBA", image.size, (0, 0, 0, 0))
    subject = image.crop(bbox)
    return paste_centered(subject, image.size)


def fit_to_canvas(image: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    if image.size[0] <= canvas_size[0] and image.size[1] <= canvas_size[1]:
        return paste_centered(image, canvas_size)
    scale = min(canvas_size[0] / image.size[0], canvas_size[1] / image.size[1])
    new_size = (max(1, round(image.size[0] * scale)), max(1, round(image.size[1] * scale)))
    resized = image.resize(new_size, Image.Resampling.LANCZOS)
    return paste_centered(resized, canvas_size)


def write_grid_scan(path: Path, rows: list[LineScanStats], source_name: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(
            [
                "sheet",
                "axis",
                "boundary_index",
                "position",
                "total_pixels",
                "nontransparent_pixels",
                "line_like_pixels",
                "dominant_bucket",
                "dominant_count",
                "nontransparent_ratio",
                "line_like_ratio",
                "dominant_total_ratio",
                "dominant_line_like_ratio",
                "erase",
            ]
        )
        for stats in rows:
            ratios = stats.ratios()
            writer.writerow(
                [
                    source_name,
                    stats.axis,
                    stats.boundary_index,
                    stats.position,
                    stats.total_pixels,
                    stats.nontransparent_pixels,
                    stats.line_like_pixels,
                    stats.dominant_bucket,
                    stats.dominant_count,
                    f"{ratios[0]:.4f}",
                    f"{ratios[1]:.4f}",
                    f"{ratios[2]:.4f}",
                    f"{ratios[3]:.4f}",
                    "true" if stats.should_erase else "false",
                ]
            )


def slice_sheet(args: argparse.Namespace) -> None:
    global Image
    try:
        from PIL import Image as PillowImage
    except ImportError as exc:  # pragma: no cover - helpful CLI failure path
        raise SystemExit(
            "Pillow is required. Install it with: python -m pip install Pillow"
        ) from exc

    Image = PillowImage
    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(input_path).convert("RGBA")
    column_mask, column_scans = detect_grid_lines(sheet, "column", args.cols, args.scan_radius)
    row_mask, row_scans = detect_grid_lines(sheet, "row", args.rows, args.scan_radius)
    cleaned = clear_grid_lines(sheet, column_mask, row_mask, args.clear_neighbor_radius)

    cleaned_output = Path(args.cleaned_output) if args.cleaned_output else None
    if cleaned_output:
        cleaned_output.parent.mkdir(parents=True, exist_ok=True)
        cleaned.save(cleaned_output)

    column_boundaries = build_cut_boundaries(
        cleaned, column_mask, "column", args.cols, args.cut_search_radius
    )
    row_boundaries = build_cut_boundaries(
        cleaned, row_mask, "row", args.rows, args.cut_search_radius
    )

    total_cells = args.cols * args.rows
    max_items = args.max_items if args.max_items is not None else total_cells
    max_items = min(max_items, total_cells)
    names = load_names(args.names_file, max_items, args.prefix, args.start_index)

    explicit_size = parse_output_size(args.output_size)
    if explicit_size:
        canvas_size = explicit_size
    else:
        max_width = max(column_boundaries[i + 1] - column_boundaries[i] for i in range(args.cols))
        max_height = max(row_boundaries[i + 1] - row_boundaries[i] for i in range(args.rows))
        canvas_size = (max_width, max_height)

    manifest_path = (
        Path(args.manifest_output) if args.manifest_output else output_dir / "icon_manifest.csv"
    )
    grid_scan_path = (
        Path(args.grid_scan_output) if args.grid_scan_output else output_dir / "grid_scan.csv"
    )

    manifest_rows: list[list[str | int]] = []
    for cell_index in range(max_items):
        col = cell_index % args.cols
        row = cell_index // args.cols
        x0, x1 = column_boundaries[col], column_boundaries[col + 1]
        y0, y1 = row_boundaries[row], row_boundaries[row + 1]
        icon = cleaned.crop((x0, y0, x1, y1))
        icon = fit_to_canvas(icon, canvas_size)
        if not args.no_center:
            icon = center_subject(icon)
        output_name = names[cell_index]
        output_path = output_dir / f"{output_name}.png"
        icon.save(output_path)
        manifest_rows.append(
            [
                cell_index + 1,
                output_name,
                input_path.name,
                col + 1,
                row + 1,
                x0,
                y0,
                x1,
                y1,
                output_path.as_posix(),
            ]
        )

    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with manifest_path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(
            [
                "index",
                "name",
                "source_sheet",
                "source_col",
                "source_row",
                "x0",
                "y0",
                "x1",
                "y1",
                "output",
            ]
        )
        writer.writerows(manifest_rows)

    write_grid_scan(grid_scan_path, column_scans + row_scans, input_path.name)
    print(f"Generated {len(manifest_rows)} icons in {output_dir}")
    print(f"Manifest: {manifest_path}")
    print(f"Grid scan: {grid_scan_path}")
    if cleaned_output:
        print(f"Cleaned sheet: {cleaned_output}")


def main() -> None:
    slice_sheet(parse_args())


if __name__ == "__main__":
    main()
