param(
    [string]$ImageDir = "image",
    [string]$OutputDir = "assets/processed/player_units",
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

public static class PlayerUnitIconDiffProcessor
{
    private const int GridBoundarySearchRadius = 24;
    private const int BlankAlphaThreshold = 8;

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

    public static void ProcessPair(
        string darkSheetPath,
        string lightSheetPath,
        string outputDir,
        string transparentSheetPath,
        string[] unitIds,
        int startIndex,
        int maxItems,
        List<string> manifestLines,
        List<string> gridScanLines
    )
    {
        using (var darkSheet = new Bitmap(darkSheetPath))
        using (var lightSheet = new Bitmap(lightSheetPath))
        {
            if (darkSheet.Width != lightSheet.Width || darkSheet.Height != lightSheet.Height)
                throw new InvalidOperationException("Sheet dimensions do not match: " + darkSheetPath + " / " + lightSheetPath);

            var darkBg = EstimateBackground(darkSheet);
            var lightBg = EstimateBackground(lightSheet);

            using (var transparentSheet = new Bitmap(darkSheet.Width, darkSheet.Height, PixelFormat.Format32bppArgb))
            {
                for (int y = 0; y < darkSheet.Height; y++)
                {
                    for (int x = 0; x < darkSheet.Width; x++)
                    {
                        Color d = darkSheet.GetPixel(x, y);
                        Color l = lightSheet.GetPixel(x, y);
                        transparentSheet.SetPixel(x, y, ExtractForeground(d, l, darkBg, lightBg));
                    }
                }

                bool[] gridColumns = DetectGridColumns(transparentSheet, Path.GetFileName(darkSheetPath), gridScanLines);
                bool[] gridRows = DetectGridRows(transparentSheet, Path.GetFileName(darkSheetPath), gridScanLines);
                ClearGridLines(transparentSheet, gridColumns, gridRows);
                transparentSheet.Save(transparentSheetPath, ImageFormat.Png);

                int[] cutColumns = BuildCutBoundaries(transparentSheet, gridColumns, true);
                int[] cutRows = BuildCutBoundaries(transparentSheet, gridRows, false);
                int canvasWidth = Math.Max((int)Math.Ceiling(darkSheet.Width / 4.0), MaxSegmentSize(cutColumns));
                int canvasHeight = Math.Max((int)Math.Ceiling(darkSheet.Height / 4.0), MaxSegmentSize(cutRows));

                for (int cellIndex = 0; cellIndex < 16; cellIndex++)
                {
                    int unitIndex = startIndex + cellIndex;
                    if (unitIndex >= unitIds.Length || unitIndex >= startIndex + maxItems)
                        return;

                    int col = cellIndex % 4;
                    int row = cellIndex / 4;
                    int x0 = cutColumns[col];
                    int y0 = cutRows[row];
                    int x1 = cutColumns[col + 1];
                    int y1 = cutRows[row + 1];

                    using (var cropped = CropBitmap(transparentSheet, x0, y0, x1, y1))
                    {
                        using (var padded = PadToCanvas(cropped, canvasWidth, canvasHeight))
                        {
                            using (var centered = CenterSubject(padded))
                            {
                                string unitId = unitIds[unitIndex];
                                string outputPath = Path.Combine(outputDir, unitId + ".png");
                                centered.Save(outputPath, ImageFormat.Png);
                                manifestLines.Add(String.Format("{0},{1},{2},{3},{4},{5}", unitIndex + 1, unitId, Path.GetFileName(darkSheetPath), Path.GetFileName(lightSheetPath), cellIndex + 1, outputPath));
                            }
                        }
                    }
                }
            }
        }
    }

    private static bool IsNearExpectedGridBoundary(int x, int y, int width, int height, int tolerance)
    {
        double cellW = width / 4.0;
        double cellH = height / 4.0;

        for (int i = 0; i <= 4; i++)
        {
            int gx = (int)Math.Round(i * cellW);
            int gy = (int)Math.Round(i * cellH);
            if (Math.Abs(x - gx) <= tolerance || Math.Abs(y - gy) <= tolerance)
                return true;
        }

        if (x <= tolerance || y <= tolerance || x >= width - 1 - tolerance || y >= height - 1 - tolerance)
            return true;

        return false;
    }

    private static bool[] DetectGridColumns(Bitmap sheet, string sheetName, List<string> gridScanLines)
    {
        bool[] result = new bool[sheet.Width];
        double cellW = sheet.Width / 4.0;
        for (int i = 0; i <= 4; i++)
        {
            int center = (int)Math.Round(i * cellW);
            int from = Math.Max(0, center - 16);
            int to = Math.Min(sheet.Width - 1, center + 16);
            for (int x = from; x <= to; x++)
            {
                LineScanStats stats = AnalyzeColumn(sheet, x);
                stats.SheetName = sheetName;
                stats.Axis = "column";
                stats.BoundaryIndex = i;
                stats.Position = x;
                stats.ShouldErase = ShouldEraseLine(stats);
                gridScanLines.Add(stats.ToCsvLine());
                if (stats.ShouldErase)
                    result[x] = true;
            }
        }
        return result;
    }

    private static bool[] DetectGridRows(Bitmap sheet, string sheetName, List<string> gridScanLines)
    {
        bool[] result = new bool[sheet.Height];
        double cellH = sheet.Height / 4.0;
        for (int i = 0; i <= 4; i++)
        {
            int center = (int)Math.Round(i * cellH);
            int from = Math.Max(0, center - 16);
            int to = Math.Min(sheet.Height - 1, center + 16);
            for (int y = from; y <= to; y++)
            {
                LineScanStats stats = AnalyzeRow(sheet, y);
                stats.SheetName = sheetName;
                stats.Axis = "row";
                stats.BoundaryIndex = i;
                stats.Position = y;
                stats.ShouldErase = ShouldEraseLine(stats);
                gridScanLines.Add(stats.ToCsvLine());
                if (stats.ShouldErase)
                    result[y] = true;
            }
        }
        return result;
    }

    private static LineScanStats AnalyzeColumn(Bitmap sheet, int x)
    {
        var stats = new LineScanStats();
        stats.TotalPixels = sheet.Height;
        var buckets = new Dictionary<string, int>();

        for (int y = 0; y < sheet.Height; y++)
        {
            AccumulateLinePixel(sheet.GetPixel(x, y), stats, buckets);
        }

        FinalizeLineStats(stats, buckets);
        return stats;
    }

    private static LineScanStats AnalyzeRow(Bitmap sheet, int y)
    {
        var stats = new LineScanStats();
        stats.TotalPixels = sheet.Width;
        var buckets = new Dictionary<string, int>();

        for (int x = 0; x < sheet.Width; x++)
        {
            AccumulateLinePixel(sheet.GetPixel(x, y), stats, buckets);
        }

        FinalizeLineStats(stats, buckets);
        return stats;
    }

    private static void AccumulateLinePixel(Color color, LineScanStats stats, Dictionary<string, int> buckets)
    {
        if (color.A <= 0)
            return;

        stats.NonTransparentPixels++;

        if (!IsLineLikePixel(color))
            return;

        stats.LineLikePixels++;
        string key = QuantizeLinePixel(color);
        if (!buckets.ContainsKey(key))
            buckets[key] = 0;
        buckets[key]++;
    }

    private static void FinalizeLineStats(LineScanStats stats, Dictionary<string, int> buckets)
    {
        foreach (var pair in buckets)
        {
            if (pair.Value <= stats.DominantCount)
                continue;

            stats.DominantKey = pair.Key;
            stats.DominantCount = pair.Value;
        }
    }

    private static bool ShouldEraseLine(LineScanStats stats)
    {
        if (stats.TotalPixels <= 0)
            return false;

        double lineLikeRatio = (double)stats.LineLikePixels / stats.TotalPixels;
        double dominantTotalRatio = (double)stats.DominantCount / stats.TotalPixels;
        double dominantLineLikeRatio = stats.LineLikePixels > 0 ? (double)stats.DominantCount / stats.LineLikePixels : 0.0;

        if (lineLikeRatio >= 0.18 && dominantTotalRatio >= 0.035)
            return true;

        if (lineLikeRatio >= 0.28 && dominantLineLikeRatio >= 0.12)
            return true;

        if (dominantTotalRatio >= 0.10)
            return true;

        return false;
    }

    private static string QuantizeLinePixel(Color color)
    {
        int a = color.A / 16;
        int r = color.R / 24;
        int g = color.G / 24;
        int b = color.B / 24;
        return a.ToString() + ":" + r.ToString() + ":" + g.ToString() + ":" + b.ToString();
    }

    private static void ClearGridLines(Bitmap sheet, bool[] columns, bool[] rows)
    {
        for (int y = 0; y < sheet.Height; y++)
        {
            for (int x = 0; x < sheet.Width; x++)
            {
                if (IsMarkedOrNeighbor(columns, x) || IsMarkedOrNeighbor(rows, y))
                    sheet.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
            }
        }
    }

    private static bool IsMarkedOrNeighbor(bool[] mask, int index)
    {
        if (index >= 0 && index < mask.Length && mask[index])
            return true;

        int previous = index - 1;
        if (previous >= 0 && previous < mask.Length && mask[previous])
            return true;

        int next = index + 1;
        if (next >= 0 && next < mask.Length && mask[next])
            return true;

        return false;
    }

    private static bool IsLineLikePixel(Color color)
    {
        if (color.A < 8)
            return false;

        int max = Math.Max(color.R, Math.Max(color.G, color.B));
        int min = Math.Min(color.R, Math.Min(color.G, color.B));
        if (max <= 0)
            return true;

        double saturation = (double)(max - min) / max;
        return saturation <= 0.32;
    }

    private class LineScanStats
    {
        public string SheetName = "";
        public string Axis = "";
        public int BoundaryIndex = 0;
        public int Position = 0;
        public int TotalPixels = 0;
        public int NonTransparentPixels = 0;
        public int LineLikePixels = 0;
        public string DominantKey = "";
        public int DominantCount = 0;
        public bool ShouldErase = false;

        public string ToCsvLine()
        {
            double nonTransparentRatio = TotalPixels > 0 ? (double)NonTransparentPixels / TotalPixels : 0.0;
            double lineLikeRatio = TotalPixels > 0 ? (double)LineLikePixels / TotalPixels : 0.0;
            double dominantTotalRatio = TotalPixels > 0 ? (double)DominantCount / TotalPixels : 0.0;
            double dominantLineLikeRatio = LineLikePixels > 0 ? (double)DominantCount / LineLikePixels : 0.0;

            return String.Format(
                "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9:F4},{10:F4},{11:F4},{12:F4},{13}",
                SheetName,
                Axis,
                BoundaryIndex,
                Position,
                TotalPixels,
                NonTransparentPixels,
                LineLikePixels,
                DominantKey,
                DominantCount,
                nonTransparentRatio,
                lineLikeRatio,
                dominantTotalRatio,
                dominantLineLikeRatio,
                ShouldErase ? "true" : "false"
            );
        }
    }

    private static int[] BuildCutBoundaries(Bitmap sheet, bool[] gridMask, bool vertical)
    {
        int limit = vertical ? sheet.Width : sheet.Height;
        int[] boundaries = new int[5];
        boundaries[0] = 0;
        boundaries[4] = limit;

        for (int i = 1; i < 4; i++)
        {
            int expected = (int)Math.Round(i * limit / 4.0);
            boundaries[i] = ChooseCutBoundary(sheet, gridMask, vertical, expected);
        }

        for (int i = 1; i < 4; i++)
        {
            int min = boundaries[i - 1] + 1;
            int max = limit - (4 - i);
            boundaries[i] = ClampInt(boundaries[i], min, max);
        }

        return boundaries;
    }

    private static int ChooseCutBoundary(Bitmap sheet, bool[] gridMask, bool vertical, int expected)
    {
        int limit = vertical ? sheet.Width : sheet.Height;
        int from = Math.Max(1, expected - GridBoundarySearchRadius);
        int to = Math.Min(limit - 1, expected + GridBoundarySearchRadius);

        int markedBlank = FindBlankBoundary(sheet, gridMask, vertical, expected, from, to, 0);
        if (markedBlank >= 0)
            return markedBlank;

        int neighborBlank = FindBlankBoundary(sheet, gridMask, vertical, expected, from, to, 1);
        if (neighborBlank >= 0)
            return neighborBlank;

        int anyBlank = FindBlankBoundary(sheet, gridMask, vertical, expected, from, to, 2);
        if (anyBlank >= 0)
            return anyBlank;

        return FindLeastFilledBoundary(sheet, gridMask, vertical, expected, from, to);
    }

    private static int FindBlankBoundary(Bitmap sheet, bool[] gridMask, bool vertical, int expected, int from, int to, int mode)
    {
        for (int offset = 0; offset <= GridBoundarySearchRadius; offset++)
        {
            int left = expected - offset;
            if (left >= from && left <= to && IsBoundaryCandidate(gridMask, left, mode) && IsBlankLine(sheet, vertical, left))
                return left;

            int right = expected + offset;
            if (right != left && right >= from && right <= to && IsBoundaryCandidate(gridMask, right, mode) && IsBlankLine(sheet, vertical, right))
                return right;
        }

        return -1;
    }

    private static int FindLeastFilledBoundary(Bitmap sheet, bool[] gridMask, bool vertical, int expected, int from, int to)
    {
        int best = expected;
        int bestCount = Int32.MaxValue;
        int bestPriority = Int32.MaxValue;
        int bestDistance = Int32.MaxValue;

        for (int x = from; x <= to; x++)
        {
            int priority = IsBoundaryCandidate(gridMask, x, 0) ? 0 : (IsBoundaryCandidate(gridMask, x, 1) ? 1 : 2);
            int count = CountNonBlankPixelsOnLine(sheet, vertical, x);
            int distance = Math.Abs(x - expected);

            if (count < bestCount || (count == bestCount && priority < bestPriority) || (count == bestCount && priority == bestPriority && distance < bestDistance))
            {
                best = x;
                bestCount = count;
                bestPriority = priority;
                bestDistance = distance;
            }
        }

        return best;
    }

    private static bool IsBoundaryCandidate(bool[] gridMask, int position, int mode)
    {
        if (mode == 2)
            return true;

        if (position >= 0 && position < gridMask.Length && gridMask[position])
            return true;

        if (mode == 1)
        {
            int previous = position - 1;
            if (previous >= 0 && previous < gridMask.Length && gridMask[previous])
                return true;

            int next = position + 1;
            if (next >= 0 && next < gridMask.Length && gridMask[next])
                return true;
        }

        return false;
    }

    private static bool IsBlankLine(Bitmap sheet, bool vertical, int position)
    {
        return CountNonBlankPixelsOnLine(sheet, vertical, position) == 0;
    }

    private static int CountNonBlankPixelsOnLine(Bitmap sheet, bool vertical, int position)
    {
        int count = 0;
        if (vertical)
        {
            for (int y = 0; y < sheet.Height; y++)
            {
                if (sheet.GetPixel(position, y).A >= BlankAlphaThreshold)
                    count++;
            }
        }
        else
        {
            for (int x = 0; x < sheet.Width; x++)
            {
                if (sheet.GetPixel(x, position).A >= BlankAlphaThreshold)
                    count++;
            }
        }

        return count;
    }

    private static int MaxSegmentSize(int[] boundaries)
    {
        int result = 1;
        for (int i = 0; i < boundaries.Length - 1; i++)
        {
            int size = boundaries[i + 1] - boundaries[i];
            if (size > result)
                result = size;
        }
        return result;
    }

    private static Bitmap CropBitmap(Bitmap source, int x0, int y0, int x1, int y1)
    {
        x0 = ClampInt(x0, 0, source.Width - 1);
        y0 = ClampInt(y0, 0, source.Height - 1);
        x1 = ClampInt(x1, x0 + 1, source.Width);
        y1 = ClampInt(y1, y0 + 1, source.Height);

        int width = x1 - x0;
        int height = y1 - y0;
        var output = new Bitmap(width, height, PixelFormat.Format32bppArgb);

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                output.SetPixel(x, y, source.GetPixel(x0 + x, y0 + y));
            }
        }

        return output;
    }

    private static Bitmap PadToCanvas(Bitmap source, int width, int height)
    {
        int canvasWidth = Math.Max(width, source.Width);
        int canvasHeight = Math.Max(height, source.Height);
        var output = new Bitmap(canvasWidth, canvasHeight, PixelFormat.Format32bppArgb);
        int dx = (canvasWidth - source.Width) / 2;
        int dy = (canvasHeight - source.Height) / 2;

        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                Color color = source.GetPixel(x, y);
                if (color.A == 0)
                    continue;

                output.SetPixel(x + dx, y + dy, color);
            }
        }

        return output;
    }

    private static int ClampInt(int value, int min, int max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private static Bitmap CenterSubject(Bitmap source)
    {
        int minX = source.Width;
        int minY = source.Height;
        int maxX = -1;
        int maxY = -1;

        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                if (source.GetPixel(x, y).A < 16)
                    continue;

                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
        }

        var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        if (maxX < minX || maxY < minY)
            return output;

        int subjectWidth = maxX - minX + 1;
        int subjectHeight = maxY - minY + 1;
        int targetX = (source.Width - subjectWidth) / 2;
        int targetY = (source.Height - subjectHeight) / 2;
        int dx = targetX - minX;
        int dy = targetY - minY;

        for (int y = minY; y <= maxY; y++)
        {
            for (int x = minX; x <= maxX; x++)
            {
                Color color = source.GetPixel(x, y);
                if (color.A == 0)
                    continue;

                int tx = x + dx;
                int ty = y + dy;
                if (tx >= 0 && tx < output.Width && ty >= 0 && ty < output.Height)
                    output.SetPixel(tx, ty, color);
            }
        }

        return output;
    }

    private static Rgb EstimateBackground(Bitmap bmp)
    {
        var samples = new List<Color>();
        int w = bmp.Width;
        int h = bmp.Height;
        int marginX = Math.Max(1, w / 40);
        int marginY = Math.Max(1, h / 40);

        AddPatchSamples(bmp, samples, 8, 8, marginX, marginY);
        AddPatchSamples(bmp, samples, w - marginX - 8, 8, marginX, marginY);
        AddPatchSamples(bmp, samples, 8, h - marginY - 8, marginX, marginY);
        AddPatchSamples(bmp, samples, w - marginX - 8, h - marginY - 8, marginX, marginY);

        return new Rgb(Median(samples, 0), Median(samples, 1), Median(samples, 2));
    }

    private static void AddPatchSamples(Bitmap bmp, List<Color> samples, int x0, int y0, int width, int height)
    {
        int maxX = Math.Min(bmp.Width, x0 + width);
        int maxY = Math.Min(bmp.Height, y0 + height);
        for (int y = Math.Max(0, y0); y < maxY; y += 2)
        {
            for (int x = Math.Max(0, x0); x < maxX; x += 2)
            {
                if (!IsNearExpectedGridBoundary(x, y, bmp.Width, bmp.Height, 6))
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

function Get-PlayerUnitIds {
    param([string]$Path)

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $inSection = $false
    $ids = New-Object System.Collections.Generic.List[string]
    $playerUnitHeading = "$([char]0x73A9)$([char]0x5BB6)$([char]0x5355)$([char]0x4F4D)"

    foreach ($line in $lines) {
        if ($line -match ("^##\s+" + [regex]::Escape($playerUnitHeading))) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^##\s+') {
            break
        }

        if ($inSection -and $line -match '^\|.*\|\s*`([^`]+)`\s*\|') {
            $ids.Add($Matches[1])
        }
    }

    if ($ids.Count -eq 0) {
        throw "No player unit ids found in $Path"
    }

    return $ids.ToArray()
}

$imageRoot = Resolve-Path -LiteralPath $ImageDir
$docPath = Resolve-Path -LiteralPath $ContentDoc
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$outputRoot = Resolve-Path -LiteralPath $OutputDir

$unitIds = Get-PlayerUnitIds -Path $docPath
$playerPrefix = "$([char]0x73A9)$([char]0x5BB6)$([char]0x5355)$([char]0x4F4D)"
$blackBackground = "$([char]0x9ED1)$([char]0x8272)$([char]0x80CC)$([char]0x666F)"
$whiteBackground = "$([char]0x767D)$([char]0x8272)$([char]0x80CC)$([char]0x666F)"
$transparentBackground = "$([char]0x900F)$([char]0x660E)$([char]0x80CC)$([char]0x666F)"

$sheetPairs = @(
    @{ Dark = "$playerPrefix" + "1-16" + "$blackBackground" + ".png"; Light = "$playerPrefix" + "1-16" + "$whiteBackground" + ".png"; Transparent = "$playerPrefix" + "1-16" + "$transparentBackground" + ".png"; Start = 0; Count = 16 },
    @{ Dark = "$playerPrefix" + "17-30" + "$blackBackground" + ".png"; Light = "$playerPrefix" + "17-30" + "$whiteBackground" + ".png"; Transparent = "$playerPrefix" + "17-30" + "$transparentBackground" + ".png"; Start = 16; Count = 14 }
)

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("index,unit_id,dark_sheet,light_sheet,source_cell,output")
$gridScanLines = New-Object System.Collections.Generic.List[string]
$gridScanLines.Add("sheet,axis,boundary_index,position,total_pixels,nontransparent_pixels,line_like_pixels,dominant_bucket,dominant_count,nontransparent_ratio,line_like_ratio,dominant_total_ratio,dominant_line_like_ratio,erase")

foreach ($pair in $sheetPairs) {
    $darkPath = Join-Path $imageRoot $pair.Dark
    $lightPath = Join-Path $imageRoot $pair.Light
    $transparentPath = Join-Path $imageRoot $pair.Transparent

    if (-not (Test-Path -LiteralPath $darkPath)) { throw "Missing dark sheet: $darkPath" }
    if (-not (Test-Path -LiteralPath $lightPath)) { throw "Missing light sheet: $lightPath" }

    [PlayerUnitIconDiffProcessor]::ProcessPair(
        $darkPath,
        $lightPath,
        $outputRoot,
        $transparentPath,
        $unitIds,
        [int]$pair.Start,
        [int]$pair.Count,
        $manifestLines,
        $gridScanLines
    )
}

$manifestPath = Join-Path $outputRoot "player_unit_icon_manifest.csv"
Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8
$gridScanPath = Join-Path $outputRoot "player_unit_grid_scan.csv"
Set-Content -LiteralPath $gridScanPath -Value $gridScanLines -Encoding UTF8

Write-Host "Generated $($unitIds.Length) player unit icons in $outputRoot"
Write-Host "Manifest: $manifestPath"
Write-Host "Grid scan: $gridScanPath"
Write-Host "Transparent sheets saved in $imageRoot"
