Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$referencePath = Join-Path $projectRoot 'brand-assets\digigrow-sherine-typography-reference.png'
$outputPath = Join-Path $projectRoot 'dist\assets\digigrow-sherine-logo-reference-font-v11.png'

$reference = [System.Drawing.Bitmap]::FromFile($referencePath)
$pixelFormat = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
$iconLayer = New-Object System.Drawing.Bitmap($reference.Width, $reference.Height, $pixelFormat)
$topLayer = New-Object System.Drawing.Bitmap($reference.Width, $reference.Height, $pixelFormat)
$bottomLayer = New-Object System.Drawing.Bitmap($reference.Width, $reference.Height, $pixelFormat)

$charcoal = [System.Drawing.ColorTranslator]::FromHtml('#0F3035')
$teal = [System.Drawing.ColorTranslator]::FromHtml('#0F796F')

# Rebuild the attached artwork on transparency while preserving its exact
# high-contrast letterforms and edge antialiasing.
for ($y = 180; $y -le 410; $y++) {
  for ($x = 20; $x -le 810; $x++) {
    $source = $reference.GetPixel($x, $y)
    $distanceFromWhite = [Math]::Max(255 - $source.R, [Math]::Max(255 - $source.G, 255 - $source.B))
    # Ignore the faint JPEG-style halo around the screenshot lettering.
    if ($distanceFromWhite -le 34) { continue }

    $alpha = [Math]::Min(255, [Math]::Max(0, [int](($distanceFromWhite - 28) * 6.5)))
    $isGreen = (($source.G - $source.R) -gt 5) -and (($source.G - $source.B) -gt 5)
    $brand = if ($isGreen) { $teal } else { $charcoal }
    $pixel = [System.Drawing.Color]::FromArgb($alpha, $brand.R, $brand.G, $brand.B)

    if ($x -le 185) {
      # Lower the leaf only enough to keep its pointed tip within the D cap height.
      $targetY = if ($isGreen -and $y -lt 285) { $y + 5 } else { $y }
      $iconLayer.SetPixel($x, $targetY, $pixel)
    }
    elseif ($y -le 312) {
      $topLayer.SetPixel($x, $y, $pixel)
    }
    elseif ($x -ge 186) {
      $bottomLayer.SetPixel($x, $y, $pixel)
    }
  }
}

$composite = New-Object System.Drawing.Bitmap($reference.Width, $reference.Height, $pixelFormat)
$graphics = [System.Drawing.Graphics]::FromImage($composite)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.DrawImageUnscaled($iconLayer, 0, 0)
$graphics.DrawImageUnscaled($bottomLayer, 0, 0)

# The attached artwork places the centre of the "o" at x=650. Compress only
# DigiGrow until that centre aligns with the final edge of Sherine at x=544.
$topLeft = 186
$topRight = 803
$topTop = 180
$topBottom = 312
$sourceOCentre = 650
$sherineEnd = 544
$topScaleX = ($sherineEnd - $topLeft) / ($sourceOCentre - $topLeft)
$sourceTopRect = New-Object System.Drawing.Rectangle($topLeft, $topTop, ($topRight - $topLeft + 1), ($topBottom - $topTop + 1))
$targetTopRect = New-Object System.Drawing.Rectangle($topLeft, $topTop, [Math]::Round($sourceTopRect.Width * $topScaleX), $sourceTopRect.Height)
$graphics.DrawImage($topLayer, $targetTopRect, $sourceTopRect, [System.Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()

# Trim transparent space, add restrained breathing room, then export at 4x
# resolution so the wordmark stays crisp in the website and future brand files.
$minX = $composite.Width
$minY = $composite.Height
$maxX = -1
$maxY = -1
for ($y = 0; $y -lt $composite.Height; $y++) {
  for ($x = 0; $x -lt $composite.Width; $x++) {
    if ($composite.GetPixel($x, $y).A -gt 3) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}

$padding = 12
$cropRect = New-Object System.Drawing.Rectangle(
  [Math]::Max(0, $minX - $padding),
  [Math]::Max(0, $minY - $padding),
  ([Math]::Min($composite.Width - 1, $maxX + $padding) - [Math]::Max(0, $minX - $padding) + 1),
  ([Math]::Min($composite.Height - 1, $maxY + $padding) - [Math]::Max(0, $minY - $padding) + 1)
)
$cropped = $composite.Clone($cropRect, $pixelFormat)
$export = New-Object System.Drawing.Bitmap(($cropped.Width * 4), ($cropped.Height * 4), $pixelFormat)
$exportGraphics = [System.Drawing.Graphics]::FromImage($export)
$exportGraphics.Clear([System.Drawing.Color]::Transparent)
$exportGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$exportGraphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$exportGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$exportGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$exportGraphics.DrawImage($cropped, 0, 0, $export.Width, $export.Height)
$exportGraphics.Dispose()
$export.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "$outputPath|$($export.Width)|$($export.Height)|scale=$([Math]::Round($topScaleX, 4))"

$reference.Dispose()
$iconLayer.Dispose()
$topLayer.Dispose()
$bottomLayer.Dispose()
$composite.Dispose()
$cropped.Dispose()
$export.Dispose()
