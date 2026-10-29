Add-Type -AssemblyName System.Drawing

$assetDirectory = Join-Path $PSScriptRoot '..\dist\assets'
$outputPath = Join-Path $assetDirectory 'digigrow-sherine-logo-elegant-v8.png'

$width = 1450
$height = 380
$bitmap = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$charcoal = [System.Drawing.ColorTranslator]::FromHtml('#0F3035')
$teal = [System.Drawing.ColorTranslator]::FromHtml('#0F796F')
$charcoalBrush = New-Object System.Drawing.SolidBrush($charcoal)
$tealBrush = New-Object System.Drawing.SolidBrush($teal)
$topFont = New-Object System.Drawing.Font('Bodoni MT', 112, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$bottomFont = New-Object System.Drawing.Font('Bodoni MT', 84, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$textFormat = [System.Drawing.StringFormat]::GenericTypographic
$textFormat.FormatFlags = $textFormat.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces

# A slim growth mark: three understated bars, an upward path, and a leaf.
$iconPen = New-Object System.Drawing.Pen($charcoal, 7)
$iconPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$iconPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$iconPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$accentPen = New-Object System.Drawing.Pen($teal, 7)
$accentPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$accentPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$accentPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

$graphics.DrawLine($iconPen, 54, 242, 54, 199)
$graphics.DrawLine($iconPen, 54, 242, 104, 242)
$graphics.DrawLine($iconPen, 104, 242, 104, 199)
$graphics.DrawLine($iconPen, 104, 199, 54, 199)
$graphics.DrawLine($iconPen, 130, 242, 130, 168)
$graphics.DrawLine($iconPen, 130, 242, 180, 242)
$graphics.DrawLine($iconPen, 180, 242, 180, 168)
$graphics.DrawLine($iconPen, 180, 168, 130, 168)
$graphics.DrawLine($iconPen, 206, 242, 206, 129)
$graphics.DrawLine($iconPen, 206, 242, 256, 242)
$graphics.DrawLine($iconPen, 256, 242, 256, 129)
$graphics.DrawLine($iconPen, 256, 129, 206, 129)

$trend = New-Object System.Drawing.Drawing2D.GraphicsPath
$trend.AddLines([System.Drawing.Point[]]@(
  (New-Object System.Drawing.Point(45, 250)),
  (New-Object System.Drawing.Point(93, 218)),
  (New-Object System.Drawing.Point(151, 235)),
  (New-Object System.Drawing.Point(249, 160))
))
$graphics.DrawPath($accentPen, $trend)
$graphics.DrawLine($accentPen, 249, 160, 225, 164)
$graphics.DrawLine($accentPen, 249, 160, 244, 177)

$leaf = New-Object System.Drawing.Drawing2D.GraphicsPath
$leaf.StartFigure()
$leaf.AddBezier(229, 138, 225, 102, 257, 72, 309, 57)
$leaf.AddBezier(309, 57, 314, 97, 289, 127, 229, 138)
$leaf.CloseFigure()
$graphics.DrawPath($accentPen, $leaf)
$graphics.DrawBezier($accentPen, 234, 132, 255, 108, 282, 82, 304, 63)

# Smaller, lighter editorial wordmark aligned as two calm lines.
$textX = 340
$topY = 24
$graphics.DrawString('Digi', $topFont, $charcoalBrush, [System.Drawing.PointF]::new($textX, $topY), $textFormat)
$digiWidth = $graphics.MeasureString('Digi', $topFont, 2000, $textFormat).Width
$graphics.DrawString('Grow', $topFont, $tealBrush, [System.Drawing.PointF]::new($textX + $digiWidth - 5, $topY), $textFormat)
$graphics.DrawString('Sherine', $bottomFont, $charcoalBrush, [System.Drawing.PointF]::new($textX + 2, 179), $textFormat)

# Trim transparent padding while retaining a small safety margin.
$graphics.Dispose()
$charcoalBrush.Dispose()
$tealBrush.Dispose()
$topFont.Dispose()
$bottomFont.Dispose()
$iconPen.Dispose()
$accentPen.Dispose()
$trend.Dispose()
$leaf.Dispose()

$minX = $bitmap.Width
$minY = $bitmap.Height
$maxX = -1
$maxY = -1
for ($y = 0; $y -lt $bitmap.Height; $y++) {
  for ($x = 0; $x -lt $bitmap.Width; $x++) {
    if ($bitmap.GetPixel($x, $y).A -gt 5) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}

$padding = 12
$left = [Math]::Max(0, $minX - $padding)
$top = [Math]::Max(0, $minY - $padding)
$right = [Math]::Min($bitmap.Width - 1, $maxX + $padding)
$bottom = [Math]::Min($bitmap.Height - 1, $maxY + $padding)
$cropRect = New-Object System.Drawing.Rectangle($left, $top, ($right - $left + 1), ($bottom - $top + 1))
$cropped = $bitmap.Clone($cropRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$cropped.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "$outputPath|$($cropped.Width)|$($cropped.Height)"

$cropped.Dispose()
$bitmap.Dispose()
