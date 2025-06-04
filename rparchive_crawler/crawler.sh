#!/bin/bash

BASE_URL="https://rparchive.wixsite.com/rparchive"
VISITED_PAGES=()
TO_VISIT=("$BASE_URL")
declare -A PAGE_TO_LINKS_OK
declare -A PAGE_TO_LINKS_ERR

# Use an associative array to track visited URLs (bash 4+)
declare -A VISITED_MAP

TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-tools-3")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-tools-2")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-tools-1")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-tools-5")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-tools-4")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/buildingmaterials")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-1")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-2")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-5")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-4")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-3")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-7")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-raw-materials-8")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-glues-and-sealants-1")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-glues-and-sealants")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-painting-and-brushes-1")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-painting-and-brushes")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/copy-of-painting-and-brushes-1")
TO_VISIT+=("https://rparchive.wixsite.com/rparchive/3d-printable-miniatures-and-scatter")


function extract_links() {
    local html="$1"
    echo "$html" | grep -Eoi '<a [^>]+>' | \
        grep -Eo 'href="[^"]+"' | cut -d'"' -f2
}

function is_internal_link() {
    [[ "$1" == "$BASE_URL"* ]]
}

function normalize_url() {
    local base="$1"
    local href="$2"
    if [[ "$href" =~ ^https?:// ]]; then
        echo "$href"
    elif [[ "$href" =~ ^/ ]]; then
        echo "${BASE_URL%/}$href"
    else
        echo "$base/$href"
    fi
}

while [ ${#TO_VISIT[@]} -gt 0 ]; do
    CURRENT="${TO_VISIT[0]}"
    TO_VISIT=("${TO_VISIT[@]:1}")

    if [[ -n "${VISITED_MAP["$CURRENT"]}" ]]; then
        continue
    fi
    VISITED_MAP["$CURRENT"]=1
    VISITED_PAGES+=("$CURRENT")

    HTML=$(curl -sL "$CURRENT")
    LINKS=$(extract_links "$HTML")

    while read -r raw_link; do
        LINK=$(normalize_url "$CURRENT" "$raw_link")

        if is_internal_link "$LINK"; then
            echo "skipping internal $LINK"
            # if [[ -z "${VISITED_MAP["$LINK"]}" ]]; then
            #     TO_VISIT+=("$LINK")
            # fi
        else
            # Check status of outgoing link
            echo "visiting $LINK"
            STATUS=$(curl -sL -o /dev/null -w "%{http_code}" "$LINK")
            if [[ "$STATUS" -lt 400 ]]; then
                PAGE_TO_LINKS_OK["$CURRENT"]+="$LINK [${STATUS}]\n"
            else
                PAGE_TO_LINKS_ERR["$CURRENT"]+="$LINK [${STATUS}]\n"
            fi
        fi
    done <<< "$LINKS"
done

# Output OK links first
echo "=== Outgoing Links OK ==="
for page in "${!PAGE_TO_LINKS_OK[@]}"; do
    printf "From: %s\n" "$page"
    printf "${PAGE_TO_LINKS_OK["$page"]}"
    echo
done

# Output errors grouped by page
echo "=== Outgoing Links with Errors ==="
for page in "${!PAGE_TO_LINKS_ERR[@]}"; do
    printf "From: %s\n" "$page"
    printf "${PAGE_TO_LINKS_ERR["$page"]}"
    echo
done
