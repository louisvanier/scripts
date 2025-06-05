Add-Type -AssemblyName System.Web # required for parsing query strings

# PowerShell script to check links on a list of Wix site pages using the Thunderbolt JSON endpoint

# Base URL
$BaseUrl = "https://rparchive.wixsite.com/rparchive"

# Subpages to append to base URL
$SubPaths = @(
    # "",
    # "/copy-of-tools-3",
    # "/copy-of-tools-2",
    # "/copy-of-tools-1",
    "/copy-of-tools-5",
    "/copy-of-tools-4",
    "/buildingmaterials"
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
    # "/3d-printable-miniatures-and-scatter"
)

# Criteria for uncertain links
$UncertainPatterns = @("Product is unavailable", "no products that match")

$outLinks = [System.Collections.ArrayList]::new()

# will scan an entire wix thunderbolt JSOn response and try to scan for links that are going outside of wix 
function Get-OutlinksFromJson {
    param (
        [Parameter(Mandatory)]
        [object] $json
    )

    function Walk($node) {
        if ($null -eq $node) { return }

        # Handle objects (PSCustomObject)
        if ($node -is [PSCustomObject]) {
            $props = $node | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            foreach ($prop in $props) {
                $value = $node.$prop
                # Look for "html" key
                if ($prop -eq "html" -and $value -is [string]) {
                    $matches = Select-String -InputObject $value -Pattern '<a\s+[^>]*href="([^"]+)"' -AllMatches |
                    ForEach-Object {
                        foreach ($match in $_.Matches) {
                            $match.Groups[1].Value
                        }
                    }
                    Write-Host "Scanned html, links before =  $($outLinks.Count)"
                    foreach ($match in $matches) {
                        Write-Host "found href = $match"
                        [void]$outLinks.Add($match)
                    }
                    Write-Host "Scanned html, links after =  $($outLinks.Count)"
                }

                # Look for "linkPropsByHref" key
                elseif ($prop -eq "linkPropsByHref" -and ($value -is [PSCustomObject])) {
                    [void]$outLinks.Add($value.PSObject.Properties.Name)
                }

                Walk $value
            }
        }
        # Handle arrays/lists
        elseif ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string])) {
            foreach ($item in $node) {
                Walk $item
            }
        }
    }

    Walk $json
    Write-Host "Returning with  $($outLinks.Count) links found in JSOn"
    return $outLinks | Sort-Object -Unique
}

$OkLinks = @{}
$ErrLinks = @{}
$UncertainLinks = @{}

foreach ($Path in $SubPaths) {
    $PageUrl = "$BaseUrl$Path"
    Write-Host "Processing: $PageUrl"

    try {
        $html = Invoke-WebRequest -Uri $PageUrl -UseBasicParsing -ErrorAction Stop
        $htmlContent = $html.Content

        # sensitive to positions of attributes
        $preloadLinks = Select-String -InputObject $html -Pattern '<link[^>] ?href="([^"]+)"[^>]*rel="preload"[^>]+' -AllMatches |
        ForEach-Object {
            foreach ($match in $_.Matches) {
                $match.Groups[1].Value
            }
        }

        foreach ($preload in $preloadLinks) {
            Write-Host "Fetching JSON from: $preload"
            $json = Invoke-RestMethod -Uri $preload -ErrorAction Stop
            $outLinks.Clear()
            $links = Get-OutlinksFromJson -json $json
            Write-Host "Found $($links.Count) links"

            foreach ($link in $links) {
                Write-Host "  Checking link: $link"
                try {
                    $response = Invoke-WebRequest -Uri $link -MaximumRedirection 5 -UseBasicParsing -ErrorAction Stop
                    $content = $response.Content
                    if ($UncertainPatterns | Where-Object { $content -match $_ }) {
                        if (-not $UncertainLinks.ContainsKey($PageUrl)) { $UncertainLinks[$PageUrl] = @() }
                        $UncertainLinks[$PageUrl] += "$link [UNCERTAIN]"
                    } else {
                        if (-not $OkLinks.ContainsKey($PageUrl)) { $OkLinks[$PageUrl] = @() }
                        $OkLinks[$PageUrl] += "$link [OK]"
                    }
                } catch {
                    if (-not $ErrLinks.ContainsKey($PageUrl)) { $ErrLinks[$PageUrl] = @() }
                    $ErrLinks[$PageUrl] += "$link [ERROR]"
                }
            }
        } 
    } catch {
        Write-Warning "Failed to process {$PageUrl}: ${_}"
    }
}


Write-Host "`n=== Outgoing Links OK ==="
foreach ($page in $OkLinks.Keys) {
    Write-Host "From: $page"
    $OkLinks[$page] | ForEach-Object { Write-Host "  $_" }
}

Write-Host "`n=== Outgoing Links UNCERTAIN ==="
foreach ($page in $UncertainLinks.Keys) {
    Write-Host "From: $page"
    $UncertainLinks[$page] | ForEach-Object { Write-Host "  $_" }
}

Write-Host "`n=== Outgoing Links with ERRORS ==="
foreach ($page in $ErrLinks.Keys) {
    Write-Host "From: $page"
    $ErrLinks[$page] | ForEach-Object { Write-Host "  $_" }
}
