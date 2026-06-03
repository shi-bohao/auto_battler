#!/usr/bin/env python3
"""Remove a solid/background layer by comparing two aligned sheets.

The script expects two images with identical content and layout, rendered once
on a dark background and once on a light background. It estimates both
background colors, derives alpha from the per-pixel difference, and writes a
transparent PNG.
"""

from __future__ import annotations

import argparse
import statistics
from pathlib import Path
from typing import Iterable, Sequence


Rgb = tuple[float, float, float]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a transparent PNG from aligned dark/light background images."
    )
    parser.add_argument("--dark", required=True, help="Source image rendered on dark background.")
    parser.add_argument("--light", required=True, help="Source image rendered on light background.")
    parser.add_argument("--output", required=True, help="Output transparent PNG path.")
    parser.add_argument(
        "--corner-margin-ratio",
        type=float,
        default=0.025,
        help="Fallback corner sample size as a fraction of image size. Default: 0.025",
    )
    parser.add_argument(
        "--corner-inset",
        type=int,
        default=8,
        help="Fallback corner sample inset to avoid outer grid lines. Default: 8",
    )
    parser.add_argument(
        "--sample-step",
        type=int,
        default=2,
        help="Pixel step for fallback corner background sampling. Default: 2",
    )
    parser.add_argument(
        "--diff-bucket-size",
        type=int,
        default=4,
        help="Bucket size for full-image dark/light difference statistics. Default: 4",
    )
    parser.add_argument(
        "--min-background-diff",
        type=float,
        default=24.0,
        help="Ignore low average dark/light differences when searching background. Default: 24",
    )
    parser.add_argument(
        "--background-diff-tolerance",
        type=float,
        default=10.0,
        help="Per-channel tolerance for selecting background candidates. Default: 10",
    )
    parser.add_argument(
        "--min-background-candidate-ratio",
        type=float,
        default=0.001,
        help="Fallback to corner sampling if fewer candidate pixels are found. Default: 0.001",
    )
    parser.add_argument(
        "--solid-diff-threshold",
        type=float,
        default=14.0,
        help="Pixels with low dark/light difference are treated as opaque foreground. Default: 14",
    )
    parser.add_argument(
        "--opaque-alpha-threshold",
        type=float,
        default=0.965,
        help="Alpha values above this are snapped to 1.0. Default: 0.965",
    )
    parser.add_argument(
        "--transparent-alpha-threshold",
        type=float,
        default=0.045,
        help="Alpha values below this are snapped to 0.0. Default: 0.045",
    )
    return parser.parse_args()


def clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))


def clamp_byte(value: float) -> int:
    return int(round(clamp(value, 0.0, 255.0)))


def median(values: Sequence[int]) -> float:
    if not values:
        return 0.0
    return float(statistics.median(values))


def iter_corner_samples(
    image: Image.Image,
    margin_ratio: float,
    inset: int,
    step: int,
) -> Iterable[tuple[int, int, int]]:
    width, height = image.size
    margin_x = max(1, int(round(width * margin_ratio)))
    margin_y = max(1, int(round(height * margin_ratio)))
    step = max(1, step)

    boxes = [
        (inset, inset, inset + margin_x, inset + margin_y),
        (width - inset - margin_x, inset, width - inset, inset + margin_y),
        (inset, height - inset - margin_y, inset + margin_x, height - inset),
        (width - inset - margin_x, height - inset - margin_y, width - inset, height - inset),
    ]

    pixels = image.load()
    for x0, y0, x1, y1 in boxes:
        for y in range(max(0, y0), min(height, y1), step):
            for x in range(max(0, x0), min(width, x1), step):
                yield pixels[x, y][:3]


def estimate_background(
    image: Image.Image,
    margin_ratio: float,
    inset: int,
    step: int,
) -> Rgb:
    samples = list(iter_corner_samples(image, margin_ratio, inset, step))
    if not samples:
        return (0.0, 0.0, 0.0)
    return (
        median([sample[0] for sample in samples]),
        median([sample[1] for sample in samples]),
        median([sample[2] for sample in samples]),
    )


def quantize_diff(value: int, bucket_size: int) -> int:
    bucket_size = max(1, bucket_size)
    return int(round(value / bucket_size) * bucket_size)


def estimate_backgrounds_from_diff(
    dark_image: Image.Image,
    light_image: Image.Image,
    bucket_size: int,
    min_background_diff: float,
    diff_tolerance: float,
    min_candidate_ratio: float,
) -> tuple[Rgb, Rgb, tuple[float, float, float], int] | None:
    width, height = dark_image.size
    dark_pixels = dark_image.load()
    light_pixels = light_image.load()
    buckets: dict[tuple[int, int, int], int] = {}

    for y in range(height):
        for x in range(width):
            dark_rgb = dark_pixels[x, y][:3]
            light_rgb = light_pixels[x, y][:3]
            diff = (
                light_rgb[0] - dark_rgb[0],
                light_rgb[1] - dark_rgb[1],
                light_rgb[2] - dark_rgb[2],
            )
            average_diff = (diff[0] + diff[1] + diff[2]) / 3.0
            if average_diff < min_background_diff:
                continue

            key = (
                quantize_diff(diff[0], bucket_size),
                quantize_diff(diff[1], bucket_size),
                quantize_diff(diff[2], bucket_size),
            )
            buckets[key] = buckets.get(key, 0) + 1

    if not buckets:
        return None

    dominant_diff = max(buckets.items(), key=lambda item: item[1])[0]
    dark_samples: list[tuple[int, int, int]] = []
    light_samples: list[tuple[int, int, int]] = []
    exact_diffs: list[tuple[int, int, int]] = []

    for y in range(height):
        for x in range(width):
            dark_rgb = dark_pixels[x, y][:3]
            light_rgb = light_pixels[x, y][:3]
            diff = (
                light_rgb[0] - dark_rgb[0],
                light_rgb[1] - dark_rgb[1],
                light_rgb[2] - dark_rgb[2],
            )
            average_diff = (diff[0] + diff[1] + diff[2]) / 3.0
            if average_diff < min_background_diff:
                continue
            if (
                abs(diff[0] - dominant_diff[0]) > diff_tolerance
                or abs(diff[1] - dominant_diff[1]) > diff_tolerance
                or abs(diff[2] - dominant_diff[2]) > diff_tolerance
            ):
                continue
            dark_samples.append(dark_rgb)
            light_samples.append(light_rgb)
            exact_diffs.append(diff)

    min_candidates = max(16, int(round(width * height * min_candidate_ratio)))
    if len(dark_samples) < min_candidates:
        return None

    dark_bg = (
        median([sample[0] for sample in dark_samples]),
        median([sample[1] for sample in dark_samples]),
        median([sample[2] for sample in dark_samples]),
    )
    light_bg = (
        median([sample[0] for sample in light_samples]),
        median([sample[1] for sample in light_samples]),
        median([sample[2] for sample in light_samples]),
    )
    bg_delta = (
        median([diff[0] for diff in exact_diffs]),
        median([diff[1] for diff in exact_diffs]),
        median([diff[2] for diff in exact_diffs]),
    )
    return dark_bg, light_bg, bg_delta, len(dark_samples)


def alpha_from_channel(dark_value: int, light_value: int, bg_delta: float) -> float:
    if abs(bg_delta) < 1.0:
        return 1.0
    transparency = (light_value - dark_value) / bg_delta
    return clamp(1.0 - transparency, 0.0, 1.0)


def unblend(pixel_value: int, background_value: float, alpha: float) -> float:
    if alpha <= 0.001:
        return 0.0
    return (pixel_value - (1.0 - alpha) * background_value) / alpha


def extract_pixel(
    dark_pixel: tuple[int, int, int, int],
    light_pixel: tuple[int, int, int, int],
    dark_bg: Rgb,
    light_bg: Rgb,
    solid_diff_threshold: float,
    opaque_alpha_threshold: float,
    transparent_alpha_threshold: float,
    bg_delta_override: Rgb | None = None,
) -> tuple[int, int, int, int]:
    dark_rgb = dark_pixel[:3]
    light_rgb = light_pixel[:3]
    bg_delta = bg_delta_override or (
        light_bg[0] - dark_bg[0],
        light_bg[1] - dark_bg[1],
        light_bg[2] - dark_bg[2],
    )

    alpha_values = [
        alpha_from_channel(dark_rgb[0], light_rgb[0], bg_delta[0]),
        alpha_from_channel(dark_rgb[1], light_rgb[1], bg_delta[1]),
        alpha_from_channel(dark_rgb[2], light_rgb[2], bg_delta[2]),
    ]
    alpha = float(statistics.median(alpha_values))

    color_diff = (
        abs(light_rgb[0] - dark_rgb[0])
        + abs(light_rgb[1] - dark_rgb[1])
        + abs(light_rgb[2] - dark_rgb[2])
    ) / 3.0
    if color_diff < solid_diff_threshold:
        alpha = 1.0
    elif alpha > opaque_alpha_threshold:
        alpha = 1.0
    elif alpha < transparent_alpha_threshold:
        alpha = 0.0

    a = clamp_byte(alpha * 255.0)
    if a == 0:
        return (0, 0, 0, 0)

    alpha = a / 255.0
    r = unblend(dark_rgb[0], dark_bg[0], alpha)
    g = unblend(dark_rgb[1], dark_bg[1], alpha)
    b = unblend(dark_rgb[2], dark_bg[2], alpha)
    return (clamp_byte(r), clamp_byte(g), clamp_byte(b), a)


def remove_background(args: argparse.Namespace) -> None:
    try:
        from PIL import Image
    except ImportError as exc:  # pragma: no cover - helpful CLI failure path
        raise SystemExit(
            "Pillow is required. Install it with: python -m pip install Pillow"
        ) from exc

    dark_path = Path(args.dark)
    light_path = Path(args.light)
    output_path = Path(args.output)

    dark_image = Image.open(dark_path).convert("RGBA")
    light_image = Image.open(light_path).convert("RGBA")
    if dark_image.size != light_image.size:
        raise SystemExit(
            f"Image sizes do not match: {dark_path} {dark_image.size} / {light_path} {light_image.size}"
        )

    diff_estimate = estimate_backgrounds_from_diff(
        dark_image,
        light_image,
        args.diff_bucket_size,
        args.min_background_diff,
        args.background_diff_tolerance,
        args.min_background_candidate_ratio,
    )
    if diff_estimate is None:
        dark_bg = estimate_background(
            dark_image,
            args.corner_margin_ratio,
            args.corner_inset,
            args.sample_step,
        )
        light_bg = estimate_background(
            light_image,
            args.corner_margin_ratio,
            args.corner_inset,
            args.sample_step,
        )
        bg_delta: Rgb | None = None
        print("Background estimate: fallback corner samples")
    else:
        dark_bg, light_bg, bg_delta, candidate_count = diff_estimate
        print(
            "Background estimate: full-image diff "
            f"candidates={candidate_count} "
            f"dark={tuple(round(v, 2) for v in dark_bg)} "
            f"light={tuple(round(v, 2) for v in light_bg)} "
            f"delta={tuple(round(v, 2) for v in bg_delta)}"
        )

    output = Image.new("RGBA", dark_image.size, (0, 0, 0, 0))
    dark_pixels = dark_image.load()
    light_pixels = light_image.load()
    output_pixels = output.load()

    width, height = dark_image.size
    for y in range(height):
        for x in range(width):
            output_pixels[x, y] = extract_pixel(
                dark_pixels[x, y],
                light_pixels[x, y],
                dark_bg,
                light_bg,
                args.solid_diff_threshold,
                args.opaque_alpha_threshold,
                args.transparent_alpha_threshold,
                bg_delta,
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path)
    print(f"Saved transparent image: {output_path}")


def main() -> None:
    remove_background(parse_args())


if __name__ == "__main__":
    main()
