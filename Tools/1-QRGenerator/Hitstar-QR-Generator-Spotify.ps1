######################################
#
# ************************************
# Powershell QR-Code-Generator Script
# Spotify Edition
# ************************************
#
# Purpose: Generates QR-Codes for HitStar cards using Spotify Track IDs.
#          Scanning these QR codes opens the song directly in the Spotify app.
#
# Usage:
#   Provide a spotify-input.txt (UTF-8 encoded) in the same folder.
#   Each line should have the format:
#       Category\Artist - Title|SpotifyTrackID
#   Example:
#       Summer\SNAP! - The Power|5T8EDUDqKcs6OSOwEsfqG7
#       Rock\Queen - Bohemian Rhapsody|7tFiyTwD0nx5a1eklYtX2J
#
#   Run the script. QR codes are saved in subfolders.
#
#   The QR code content will be:
#       https://open.spotify.com/track/TRACKID
#   This opens the Spotify app on Android when scanned with ANY QR reader.
#
#   If no SpotifyTrackID is provided, the QR code will contain the
#   classic HitStar format (Category/Artist - Title) for backwards
#   compatibility with the HitStar Spotify Edition web app, which
#   falls back to Spotify search.
#
######################################

# Get the folder where the script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define paths
$inputFile = Join-Path $scriptDir "spotify-input.txt"
$outputRoot = Join-Path $scriptDir "QR_Output_Spotify"
$exePath = Join-Path $scriptDir "SimpleCodeGenerator.exe"

# Read lines (UTF-8, non-empty)
$lines = Get-Content -Path $inputFile -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$total = $lines.Count
$index = 0

foreach ($line in $lines) {
    $index++
    $cleanLine = $line.Trim()

    # Split on pipe to get path part and optional Spotify ID
    $pipeParts = $cleanLine -split "\|"
    $pathPart = $pipeParts[0].Trim()
    $spotifyId = if ($pipeParts.Count -ge 2) { $pipeParts[1].Trim() } else { "" }

    # Split path on backslash
    $parts = $pathPart -split "\\"

    if ($parts.Count -eq 2) {
        $category = $parts[0].Trim()
        $songInfo = $parts[1].Trim()

        # Clean filename for Windows
        $safeFilename = [RegEx]::Replace($songInfo, '[\\/:*?"<>|]', '')

        # Determine QR content
        if ($spotifyId -ne "") {
            # Spotify deep link - opens Spotify app directly
            $qrContent = "https://open.spotify.com/track/$spotifyId"
        } else {
            # Fallback: classic format (HitStar web app will do Spotify search)
            $qrContent = "$category/$songInfo"
        }

        # Prepare category subfolder path
        $categoryFolder = Join-Path $outputRoot $category

        # Create subfolder if needed
        if (!(Test-Path $categoryFolder)) {
            New-Item -ItemType Directory -Path $categoryFolder | Out-Null
        }

        # Final PNG path
        $outputPath = Join-Path $categoryFolder "$safeFilename.png"

        # Console output
        Write-Host "[$index/$total] Generating QR: $qrContent -> $category\$safeFilename.png"

        # Run QR generator
        Start-Process -NoNewWindow -FilePath $exePath -ArgumentList "/ErrorCorrection 4 /MinVersion 10 /MaxVersion 40 /Save `"$qrContent`" `"$outputPath`" 10" -Wait
    } else {
        Write-Host "[$index/$total] Skipping invalid line: $cleanLine"
    }
}

Write-Host "`n✅ QR Code generation complete! Check the folder: $outputRoot"
Write-Host "These QR codes contain Spotify deep links."
Write-Host "Scanning them with any QR reader on a phone with Spotify installed will open the song directly."
