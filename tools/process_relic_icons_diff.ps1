param(
    [string]$ImageDir = "image",
    [string]$OutputDir = "assets/processed/relics",
    [string]$ContentDoc = "docs/content_reference.md"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$source = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class RelicIconDiffProcessor
{
    private struct Rgb
    {
        public double R;
        public double G;
        public double B;

        public Rgb(double r, double g, double b)
        {
            R = r;
            G = g;
            B = b;
        }
    }

    public static void ProcessPair(string darkSheetPath, string lightSheetPath, string outputDir, string[] relicIds, int startIndex, List<string> manifestLines)
    {
        using (var darkSheet = new Bitmap(darkSheetPath))
        using (var lightSheet = new Bitmap(lightSheetPath))
        {
            if (darkSheet.Width != lightSheet.Width || darkSheet.Height != lightSheet.Height)
                throw new InvalidOperationException("Sheet dimensions do not match: " + darkSheetPath + " / " + lightSheetPath);

            var darkBg = EstimateBackground(darkSheet);
            var lightBg = EstimateBackground(lightSheet);

            for (int cellIndex = 0; cellIndex < 16; cellIndex++)
            {
                int relicIndex = startIndex + cellIndex;
                if (relicIndex >= relicIds.Length)
                    return;

                int col = cellIndex % 4;
                int row = cellIndex / 4;
                int x0 = (int)Math.Round(col * darkSheet.Width / 4.0);
                int y0 = (int)Math.Round(row * darkSheet.Height / 4.0);
                int x1 = (int)Math.Round((col + 1) * darkSheet.Width / 4.0);
                int y1 = (int)Math.Round((row + 1) * darkSheet.Height / 4.0);
                int width = x1 - x0;
                int height = y1 - y0;

                using (var output = new Bitmap(width, height, PixelFormat.Format32bppArgb))
                {
                    for (int y = 0; y < height; y++)
                    {
                        for (int x = 0; x < width; x++)
                        {
                            Color d = darkSheet.GetPixel(x0 + x, y0 + y);
                            Color l = lightSheet.GetPixel(x0 + x, y0 + y);
                            Color result = ExtractForeground(d, l, darkBg, lightBg);
                            output.SetPixel(x, y, result);
                        }
                    }

                    string relicId = relicIds[relicIndex];
                    string outputPath = Path.Combine(outputDir, relicId + ".png");
                    output.Save(outputPath, ImageFormat.Png);
                    manifestLines.Add(String.Format("{0},{1},{2},{3},{4}", relicIndex + 1, relicId, Path.GetFileName(darkSheetPath), Path.GetFileName(lightSheetPath), cellIndex + 1));
                }
            }
        }
    }

    private static Rgb EstimateBackground(Bitmap bmp)
    {
        var samples = new List<Color>();
        int w = bmp.Width;
        int h = bmp.Height;
        int marginX = Math.Max(1, w / 40);
        int marginY = Math.Max(1, h / 40);

        AddPatchSamples(bmp, samples, 0, 0, marginX, marginY);
        AddPatchSamples(bmp, samples, w - marginX, 0, marginX, marginY);
        AddPatchSamples(bmp, samples, 0, h - marginY, marginX, marginY);
        AddPatchSamples(bmp, samples, w - marginX, h - marginY, marginX, marginY);

        return new Rgb(Median(samples, 0), Median(samples, 1), Median(samples, 2));
    }

    private static void AddPatchSamples(Bitmap bmp, List<Color> samples, int x0, int y0, int width, int height)
    {
        for (int y = y0; y < y0 + height; y += 2)
        {
            for (int x = x0; x < x0 + width; x += 2)
            {
                samples.Add(bmp.GetPixel(x, y));
            }
        }
    }

    private static double Median(List<Color> samples, int channel)
    {
        var values = new List<int>(samples.Count);
        foreach (var c in samples)
        {
            if (channel == 0) values.Add(c.R);
            else if (channel == 1) values.Add(c.G);
            else values.Add(c.B);
        }
        values.Sort();
        return values[values.Count / 2];
    }

    private static Color ExtractForeground(Color darkPixel, Color lightPixel, Rgb darkBg, Rgb lightBg)
    {
        double dr = lightBg.R - darkBg.R;
        double dg = lightBg.G - darkBg.G;
        double db = lightBg.B - darkBg.B;

        double ar = AlphaFromChannel(darkPixel.R, lightPixel.R, dr);
        double ag = AlphaFromChannel(darkPixel.G, lightPixel.G, dg);
        double ab = AlphaFromChannel(darkPixel.B, lightPixel.B, db);
        double alpha = Median3(ar, ag, ab);

        double colorDiff = (Math.Abs(lightPixel.R - darkPixel.R) + Math.Abs(lightPixel.G - darkPixel.G) + Math.Abs(lightPixel.B - darkPixel.B)) / 3.0;
        if (colorDiff < 14.0)
            alpha = 1.0;
        else if (alpha > 0.965)
            alpha = 1.0;
        else if (alpha < 0.045)
            alpha = 0.0;

        int a = ClampToByte(alpha * 255.0);
        if (a == 0)
            return Color.FromArgb(0, 0, 0, 0);

        double r = Unblend(darkPixel.R, darkBg.R, alpha);
        double g = Unblend(darkPixel.G, darkBg.G, alpha);
        double b = Unblend(darkPixel.B, darkBg.B, alpha);
        return Color.FromArgb(a, ClampToByte(r), ClampToByte(g), ClampToByte(b));
    }

    private static double AlphaFromChannel(int darkValue, int lightValue, double bgDelta)
    {
        if (Math.Abs(bgDelta) < 1.0)
            return 1.0;

        double transparency = (lightValue - darkValue) / bgDelta;
        return Clamp01(1.0 - transparency);
    }

    private static double Unblend(int pixel, double bg, double alpha)
    {
        if (alpha <= 0.001)
            return 0.0;

        return (pixel - (1.0 - alpha) * bg) / alpha;
    }

    private static double Median3(double a, double b, double c)
    {
        if (a > b) { double t = a; a = b; b = t; }
        if (b > c) { double t = b; b = c; c = t; }
        if (a > b) { double t = a; a = b; b = t; }
        return b;
    }

    private static double Clamp01(double value)
    {
        if (value < 0.0) return 0.0;
        if (value > 1.0) return 1.0;
        return value;
    }

    private static int ClampToByte(double value)
    {
        if (value < 0.0) return 0;
        if (value > 255.0) return 255;
        return (int)Math.Round(value);
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing

function Get-RelicIds {
    param([string]$Path)

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $ids = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ($line -match '^\|.*\|\s*`([A-Za-z0-9_]+)`\s*\|\s*(COMMON|FINE|RARE|EPIC|LEGENDARY)\s*\|') {
            $ids.Add($Matches[1])
        }
    }

    if ($ids.Count -eq 0) {
        throw "No relic ids found in $Path"
    }

    return $ids.ToArray()
}

$imageRoot = Resolve-Path -LiteralPath $ImageDir
$docPath = Resolve-Path -LiteralPath $ContentDoc
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$outputRoot = Resolve-Path -LiteralPath $OutputDir

$relicIds = Get-RelicIds -Path $docPath
$relicPrefix = "$([char]0x9057)$([char]0x7269)"
$whiteBackground = "$([char]0x767D)$([char]0x8272)$([char]0x80CC)$([char]0x666F)"

$sheetPairs = @(
    @{ Dark = "$relicPrefix" + "1-16.png"; Light = "$relicPrefix" + "1-16" + "$whiteBackground" + ".png"; Start = 0 },
    @{ Dark = "$relicPrefix" + "17-32.png"; Light = "$relicPrefix" + "17-32" + "$whiteBackground" + ".png"; Start = 16 },
    @{ Dark = "$relicPrefix" + "33-43.png"; Light = "$relicPrefix" + "33-43" + "$whiteBackground" + ".png"; Start = 32 }
)

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("index,relic_id,dark_sheet,light_sheet,source_cell")

foreach ($pair in $sheetPairs) {
    $darkPath = Join-Path $imageRoot $pair.Dark
    $lightPath = Join-Path $imageRoot $pair.Light
    if (-not (Test-Path -LiteralPath $darkPath)) { throw "Missing dark sheet: $darkPath" }
    if (-not (Test-Path -LiteralPath $lightPath)) { throw "Missing light sheet: $lightPath" }

    [RelicIconDiffProcessor]::ProcessPair($darkPath, $lightPath, $outputRoot, $relicIds, [int]$pair.Start, $manifestLines)
}

$manifestPath = Join-Path $outputRoot "relic_icon_manifest.csv"
Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8

Write-Host "Generated $($relicIds.Length) relic icons in $outputRoot"
Write-Host "Manifest: $manifestPath"
