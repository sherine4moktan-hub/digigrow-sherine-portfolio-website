Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$masterPath = Join-Path $projectRoot 'brand-assets\digigrow-sherine-master-reference.png'
$outputPath = Join-Path $projectRoot 'dist\assets\digigrow-sherine-logo-bodoni-compact-v10.png'

$master = [System.Drawing.Bitmap]::FromFile($masterPath)
$canvas = New-Object System.Drawing.Bitmap(2170, 725, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Preserve the original icon pixel-for-pixel. The wordmark begins after x=430.
$graphics.DrawImage(
  $master,
  (New-Object System.Drawing.Rectangle(0, 0, 430, 725)),
  0,
  0,
  430,
  725,
  [System.Drawing.GraphicsUnit]::Pixel
)

$charcoal = [System.Drawing.ColorTranslator]::FromHtml('#0F3035')
$teal = [System.Drawing.ColorTranslator]::FromHtml('#0F796F')
$charcoalBrush = New-Object System.Drawing.SolidBrush($charcoal)
$tealBrush = New-Object System.Drawing.SolidBrush($teal)
$topFont = New-Object System.Drawing.Font('Bodoni MT', 365, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$bottomFont = New-Object System.Drawing.Font('Bodoni MT', 275, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$format = [System.Drawing.StringFormat]::GenericTypographic
$format.FormatFlags = $format.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces

$textX = 458
$topY = 44
$digiWidth = $graphics.MeasureString('Digi', $topFont, 2500, $format).Width
$sherineWidth = $graphics.MeasureString('Sherine', $bottomFont, 2500, $format).Width
$grWidth = $graphics.MeasureString('Gr', $topFont, 2500, $format).Width
$oWidth = $graphics.MeasureString('o', $topFont, 2500, $format).Width

# Narrow only the top wordmark so the centre of the "o" sits directly above
# the final edge of "Sherine". The icon, letter height and lower word stay intact.
$naturalOCentre = $digiWidth - 10 + $grWidth + ($oWidth / 2)
$sherineEnd = 3 + $sherineWidth
$topScaleX = $sherineEnd / $naturalOCentre
$topState = $graphics.Save()
$topTransform = New-Object System.Drawing.Drawing2D.Matrix($topScaleX, 0, 0, 1, $textX, 0)
$graphics.Transform = $topTransform
$graphics.DrawString('Digi', $topFont, $charcoalBrush, [System.Drawing.PointF]::new(0, $topY), $format)
$graphics.DrawString('Grow', $topFont, $tealBrush, [System.Drawing.PointF]::new($digiWidth - 10, $topY), $format)
$graphics.Restore($topState)
$topTransform.Dispose()
$graphics.DrawString('Sherine', $bottomFont, $charcoalBrush, [System.Drawing.PointF]::new($textX + 3, 350), $format)

$graphics.Dispose()
$master.Dispose()
$charcoalBrush.Dispose()
$tealBrush.Dispose()
$topFont.Dispose()
$bottomFont.Dispose()

# Trim only the unused transparent perimeter; internal alignment stays untouched.
$minX = $canvas.Width
$minY = $canvas.Height
$maxX = -1
$maxY = -1
for ($y = 0; $y -lt $canvas.Height; $y++) {
  for ($x = 0; $x -lt $canvas.Width; $x++) {
    if ($canvas.GetPixel($x, $y).A -gt 5) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}

$padding = 14
$left = [Math]::Max(0, $minX - $padding)
$top = [Math]::Max(0, $minY - $padding)
$right = [Math]::Min($canvas.Width - 1, $maxX + $padding)
$bottom = [Math]::Min($canvas.Height - 1, $maxY + $padding)
$rect = New-Object System.Drawing.Rectangle($left, $top, ($right - $left + 1), ($bottom - $top + 1))
$cropped = $canvas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$cropped.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "$outputPath|$($cropped.Width)|$($cropped.Height)"

$cropped.Dispose()
$canvas.Dispose()
