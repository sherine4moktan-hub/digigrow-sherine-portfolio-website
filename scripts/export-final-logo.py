from __future__ import annotations

import argparse
import shutil
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor


CHARCOAL = "#0F3035"
TEAL = "#0F796F"
BRAND_RGB = np.array([[15.0, 48.0, 53.0], [15.0, 121.0, 111.0]])


def estimate_background(rgb: np.ndarray) -> np.ndarray:
    border = np.concatenate(
        [
            rgb[:20].reshape(-1, 3),
            rgb[-20:].reshape(-1, 3),
            rgb[:, :20].reshape(-1, 3),
            rgb[:, -20:].reshape(-1, 3),
        ]
    )
    return np.median(border, axis=0).astype(np.float32)


def separate_artwork(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    image = rgb.astype(np.float32)
    background = estimate_background(rgb)
    delta = background[None, None, :] - image

    alphas = []
    errors = []
    for colour in BRAND_RGB:
        direction = background - colour
        alpha = np.sum(delta * direction, axis=2) / np.sum(direction * direction)
        alpha = np.clip(alpha, 0.0, 1.0)
        reconstruction = (
            alpha[:, :, None] * colour[None, None, :]
            + (1.0 - alpha[:, :, None]) * background[None, None, :]
        )
        error = np.sum((image - reconstruction) ** 2, axis=2)
        alphas.append(alpha)
        errors.append(error)

    alpha_stack = np.stack(alphas, axis=2)
    error_stack = np.stack(errors, axis=2)
    labels = np.argmin(error_stack, axis=2).astype(np.uint8)
    alpha = np.take_along_axis(alpha_stack, labels[:, :, None], axis=2)[:, :, 0]

    distance = np.linalg.norm(image - background[None, None, :], axis=2)
    alpha[(distance < 12.0) | (alpha < 0.055)] = 0.0
    alpha[alpha > 0.965] = 1.0

    rgba = np.zeros((rgb.shape[0], rgb.shape[1], 4), dtype=np.uint8)
    rgba[:, :, :3] = BRAND_RGB[labels].astype(np.uint8)
    rgba[:, :, 3] = np.round(alpha * 255.0).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return rgba, labels, alpha


def contours_for_mask(mask: np.ndarray) -> list[np.ndarray]:
    contours, _ = cv2.findContours(
        mask.astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_TC89_KCOS
    )
    result: list[np.ndarray] = []
    for contour in contours:
        if abs(cv2.contourArea(contour)) < 2.0:
            continue
        simplified = cv2.approxPolyDP(contour, 0.32, True)
        if len(simplified) >= 3:
            result.append(simplified[:, 0, :])
    return result


def svg_path(contours: list[np.ndarray], offset_x: int = 0, offset_y: int = 0) -> str:
    commands: list[str] = []
    for contour in contours:
        points = contour.astype(np.float64)
        first = points[0]
        commands.append(f"M{first[0] - offset_x:.2f},{first[1] - offset_y:.2f}")
        for point in points[1:]:
            commands.append(f"L{point[0] - offset_x:.2f},{point[1] - offset_y:.2f}")
        commands.append("Z")
    return " ".join(commands)


def write_svg(
    path: Path,
    width: int,
    height: int,
    charcoal_path: str,
    teal_path: str,
    title: str,
) -> None:
    content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">
  <title id="title">{title}</title>
  <desc id="desc">Editable vector paths traced from Sherine Moktan's approved final logo artwork.</desc>
  <path fill="{CHARCOAL}" fill-rule="evenodd" d="{charcoal_path}"/>
  <path fill="{TEAL}" fill-rule="evenodd" d="{teal_path}"/>
</svg>
'''
    path.write_text(content, encoding="utf-8", newline="\n")


def draw_contours_pdf(
    pdf: canvas.Canvas,
    contours: list[np.ndarray],
    colour: str,
    source_height: int,
) -> None:
    pdf.setFillColor(HexColor(colour))
    path = pdf.beginPath()
    for contour in contours:
        first = contour[0]
        path.moveTo(float(first[0]), float(source_height - first[1]))
        for point in contour[1:]:
            path.lineTo(float(point[0]), float(source_height - point[1]))
        path.close()
    pdf.drawPath(path, fill=1, stroke=0, fillMode=0)


def transparent_resize(rgba: np.ndarray, width: int) -> Image.Image:
    source = Image.fromarray(rgba, mode="RGBA")
    height = round(source.height * width / source.width)
    return source.resize((width, height), Image.Resampling.LANCZOS)


def centred_square_icon(icon: Image.Image, size: int, padding_ratio: float = 0.08) -> Image.Image:
    canvas_image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    maximum = round(size * (1.0 - 2.0 * padding_ratio))
    scale = min(maximum / icon.width, maximum / icon.height)
    fitted = icon.resize(
        (round(icon.width * scale), round(icon.height * scale)), Image.Resampling.LANCZOS
    )
    x = (size - fitted.width) // 2
    y = (size - fitted.height) // 2
    canvas_image.alpha_composite(fitted, (x, y))
    return canvas_image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()

    final_dir = args.project / "brand-assets" / "final"
    pdf_dir = args.project / "output" / "pdf"
    site_assets = args.project / "dist" / "assets"
    final_dir.mkdir(parents=True, exist_ok=True)
    pdf_dir.mkdir(parents=True, exist_ok=True)
    site_assets.mkdir(parents=True, exist_ok=True)

    source = Image.open(args.source).convert("RGB")
    rgb = np.array(source)
    height, width = rgb.shape[:2]
    rgba, labels, alpha = separate_artwork(rgb)

    masks = [((labels == index) & (alpha >= 0.50)).astype(np.uint8) for index in range(2)]
    contours = [contours_for_mask(mask) for mask in masks]
    paths = [svg_path(item) for item in contours]

    master_svg = final_dir / "digigrow-sherine-master.svg"
    high_res_png = final_dir / "digigrow-sherine-high-resolution.png"
    print_pdf = pdf_dir / "digigrow-sherine-print.pdf"
    write_svg(master_svg, width, height, paths[0], paths[1], "DigiGrow Sherine")
    transparent_resize(rgba, 3000).save(high_res_png, "PNG", optimize=True)

    page_width = 720.0
    page_height = page_width * height / width
    pdf = canvas.Canvas(str(print_pdf), pagesize=(page_width, page_height), pageCompression=1)
    pdf.setTitle("DigiGrow Sherine - Print Logo")
    pdf.setAuthor("Sherine Moktan")
    pdf.setSubject("Approved DigiGrow Sherine logo in vector format")
    pdf.saveState()
    pdf.scale(page_width / width, page_height / height)
    draw_contours_pdf(pdf, contours[0], CHARCOAL, height)
    draw_contours_pdf(pdf, contours[1], TEAL, height)
    pdf.restoreState()
    pdf.showPage()
    pdf.save()

    # The symbol is isolated from the approved artwork without redrawing it.
    icon_x0, icon_y0, icon_x1, icon_y1 = 110, 119, 592, 657
    icon_width, icon_height = icon_x1 - icon_x0, icon_y1 - icon_y0
    icon_rgba = rgba[icon_y0:icon_y1, icon_x0:icon_x1].copy()
    icon_rgba[:, 575 - icon_x0 :] = 0
    icon_masks = [mask[icon_y0:icon_y1, icon_x0:icon_x1].copy() for mask in masks]
    for icon_mask in icon_masks:
        icon_mask[:, 575 - icon_x0 :] = 0
    icon_contours = [contours_for_mask(mask) for mask in icon_masks]
    icon_paths = [svg_path(item) for item in icon_contours]

    icon_svg = final_dir / "digigrow-sherine-icon.svg"
    icon_png = final_dir / "digigrow-sherine-icon.png"
    write_svg(
        icon_svg,
        icon_width,
        icon_height,
        icon_paths[0],
        icon_paths[1],
        "DigiGrow Sherine icon",
    )
    transparent_resize(icon_rgba, 1200).save(icon_png, "PNG", optimize=True)

    icon_image = Image.fromarray(icon_rgba, mode="RGBA")
    site_icon_512 = centred_square_icon(icon_image, 512)
    site_icon_180 = centred_square_icon(icon_image, 180)
    site_icon_png = final_dir / "digigrow-sherine-site-icon.png"
    site_icon_512.save(site_icon_png, "PNG", optimize=True)
    site_icon_512.save(site_assets / "favicon.png", "PNG", optimize=True)
    site_icon_180.save(site_assets / "apple-touch-icon.png", "PNG", optimize=True)

    square_size = 600
    available = 520.0
    icon_scale = min(available / icon_width, available / icon_height)
    icon_tx = (square_size - icon_width * icon_scale) / 2.0
    icon_ty = (square_size - icon_height * icon_scale) / 2.0
    site_icon_svg = final_dir / "digigrow-sherine-site-icon.svg"
    site_svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewBox="0 0 600 600" role="img" aria-labelledby="title desc">
  <title id="title">DigiGrow Sherine site icon</title>
  <desc id="desc">The approved DigiGrow Sherine growth-chart and leaf symbol.</desc>
  <g transform="translate({icon_tx:.4f} {icon_ty:.4f}) scale({icon_scale:.6f})">
    <path fill="{CHARCOAL}" fill-rule="evenodd" d="{icon_paths[0]}"/>
    <path fill="{TEAL}" fill-rule="evenodd" d="{icon_paths[1]}"/>
  </g>
</svg>
'''
    site_icon_svg.write_text(site_svg_content, encoding="utf-8", newline="\n")

    shutil.copy2(master_svg, site_assets / master_svg.name)
    shutil.copy2(site_icon_svg, site_assets / site_icon_svg.name)
    shutil.copy2(site_icon_png, site_assets / site_icon_png.name)

    print(f"source={width}x{height}")
    print(f"png={high_res_png}|{Image.open(high_res_png).size}")
    print(f"svg={master_svg}|paths={sum(len(item) for item in contours)} contours")
    print(f"pdf={print_pdf}|page={page_width:.2f}x{page_height:.2f}pt")
    print(f"icon_svg={icon_svg}")
    print(f"icon_png={icon_png}")
    print(f"site_icon_svg={site_icon_svg}")
    print(f"site_icon_png={site_icon_png}")


if __name__ == "__main__":
    main()
