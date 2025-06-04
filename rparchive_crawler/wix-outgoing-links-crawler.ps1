
$BaseUrl = "https://rparchive.wixsite.com/rparchive"

# Subpages to append to base URL
$SubPaths = @(
    "",
    # "/copy-of-tools-3",
    # "/copy-of-tools-2",
    # "/copy-of-tools-1",
    # "/copy-of-tools-5",
    "/copy-of-tools-4"
    # "/buildingmaterials"
    # "/copy-of-raw-materials-1",
    # "/copy-of-raw-materials-2",
    # "/copy-of-raw-materials-5",
    # "/copy-of-raw-materials-4",
    # "/copy-of-raw-materials-3",
    # "/copy-of-raw-materials-7",
    # "/copy-of-raw-materials-8",
    # "/copy-of-glues-and-sealants-1",
    # "/copy-of-glues-and-sealants",
    # "/copy-of-painting-and-brushes-1",
    # "/copy-of-painting-and-brushes",
    # "/copy-of-painting-and-brushes-1",
    # "/3d-printable-miniatures-and-scatter"
)

# Keywords to flag uncertain matches
$UncertainKeywords = @("Product is unavailable", "@EXAMPLE OF ANOTHER PRODUCT MATCH")

$OkLinks = @{}
$ErrLinks = @{}
$UncertainLinks = @{}

# Function to extract hrefs
function Get-LinksFromHtml {
    param ([string]$html)
    $matches = Select-String -InputObject $html -Pattern '<a [^>]*href="([^"]+)"' -AllMatches
    return $matches.Matches.Groups[1].Value
}

foreach ($path in $SubPaths) {
    $PageUrl = "$BaseUrl$path"
    Write-Host "Checking page: $PageUrl"
    try {
        $html = Invoke-WebRequest -Uri $PageUrl -UseBasicParsing -ErrorAction Stop
        $links = Get-LinksFromHtml -html $html.Content

        foreach ($rawLink in $links) {
            if ($rawLink.StartsWith("http") -and !$rawLink.StartsWith($BaseUrl)) {
                Write-Host "  Visiting external link: $rawLink"
                try {
                    $response = Invoke-WebRequest -Uri $rawLink -UseBasicParsing -ErrorAction Stop
                    $body = $response.Content
                    $matched = $false

                    foreach ($keyword in $UncertainKeywords) {
                        if ($body -like "*$keyword*") {
                            $UncertainLinks[$PageUrl] += "`n$rawLink [UNSURE: matched '$keyword']"
                            $matched = $true
                            break
                        }
                    }

                    if (-not $matched) {
                        $OkLinks[$PageUrl] += "`n$rawLink [200 OK]"
                    }
                } catch {
                    $ErrLinks[$PageUrl] += "`n$rawLink [ERROR: $($_.Exception.Message)]"
                }
            }
        }
    } catch {
        Write-Host "Failed to load page: $PageUrl"
    }
}

# Output the results
Write-Host "`n=== OK Links ==="
foreach ($page in $OkLinks.Keys) {
    Write-Host "From: $page"
    Write-Host $OkLinks[$page]
    Write-Host ""
}

Write-Host "`n=== Uncertain Links (matched keywords) ==="
foreach ($page in $UncertainLinks.Keys) {
    Write-Host "From: $page"
    Write-Host $UncertainLinks[$page]
    Write-Host ""
}

Write-Host "`n=== Broken or Error Links ==="
foreach ($page in $ErrLinks.Keys) {
    Write-Host "From: $page"
    Write-Host $ErrLinks[$page]
    Write-Host ""
}
