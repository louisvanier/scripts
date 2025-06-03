#!/bin/bash
# s://siteassets.parastorage.com/pages/pages/thunderbolt?&isInSeo=false
# Base Thunderbolt API URL list (add more as needed)
API_ENDPOINTS=(
   "https://siteassets.parastorage.com/pages/pages/thunderbolt?appDefinitionIdToSiteRevision=%7B%2214271d6f-ba62-d045-549b-ab972ae1f70e%22%3A%2225%22%7D&beckyExperiments=.DatePickerPortal%2C.EnableCustomCSSVarsForLoginSocialBar%2C.LoginBarEnableLoggingInStateInSSR%2C.TextInputAutoFillFix%2C.buttonUdp%2C.calculateCollapsibleTextLineHeightByFont%2C.classicPaginationAsList%2C.dataBindingInMasterResponsive%2C.dynamicSlots%2C.fileUploaderNameListMinHeight%2C.fiveGridLineStudioSkins%2C.overflowXClipInMobile%2C.runSvgLoaderFeatureOnBreadcrumbsComp%2C.svgResolver%2C.updateRichTextSemanticClassNamesOnCorvid%2C.useImageAvifFormatInNativeProGallery&blocksBuilderManifestGeneratorVersion=1.129.0&contentType=application%2Fjson&dfCk=6&dfVersion=1.4776.0&editorName=Unknown&experiments=dm_bgScrubToMotionFixer%2Cdm_deleteLayoutOverridesForRefComponents%2Cdm_migrateOldHoverBoxToNewFixer&externalBaseUrl=https%3A%2F%2Frparchive.wixsite.com%2Frparchive&fileId=576d285e.bundle.min&formFactor=desktop&hasTPAWorkerOnSite=false&isHttps=true&isInSeo=false&isPremiumDomain=true&isUrlMigrated=true&isWixCodeOnPage=false&isWixCodeOnSite=false&language=en&metaSiteId=756a2c47-a05c-4bb2-96e8-b94fac80f4af&module=thunderbolt-platform&oneDocEnabled=true&originalLanguage=en&pageId=3cc5fc_2cd5358ad02cc402b9773ea289e17049_530.json&quickActionsMenuEnabled=false&registryLibrariesTopology=%5B%7B%22artifactId%22%3A%22editor-elements%22%2C%22namespace%22%3A%22wixui%22%2C%22url%22%3A%22https%3A%2F%2Fstatic.parastorage.com%2Fservices%2Feditor-elements%2F1.13875.0%22%7D%2C%7B%22artifactId%22%3A%22editor-elements%22%2C%22namespace%22%3A%22dsgnsys%22%2C%22url%22%3A%22https%3A%2F%2Fstatic.parastorage.com%2Fservices%2Feditor-elements%2F1.13875.0%22%7D%5D&remoteWidgetStructureBuilderVersion=1.251.0&siteId=49ab84ee-744e-43f4-8ab9-baa9f9fb0316&siteRevision=530&staticHTMLComponentUrl=https%3A%2F%2Frparchive-wixsite-com.filesusr.com%2F&viewMode=desktop"
)

declare -A PAGE_TO_OK_LINKS
declare -A PAGE_TO_ERR_LINKS

for endpoint in "${API_ENDPOINTS[@]}"; do
  echo "Fetching: $endpoint"
  json=$(curl -sL "$endpoint")
  page_id=$(echo "$endpoint" | grep -oP 'pageId=[^&]+' | cut -d= -f2)

  echo $json

  links=$(echo "$json" | jq -r '.sdkData[]?.linkPropsByHref? | keys[]')

    for link in $links; do
    if [[ "$link" == http* && "$link" != *wixsite.com* ]]; then
        status=$(curl -sL -o /dev/null -w "%{http_code}" "$link")
        if [[ "$status" -lt 400 ]]; then
        PAGE_TO_OK_LINKS["$page_id"]+="$link [$status]\n"
        else
        PAGE_TO_ERR_LINKS["$page_id"]+="$link [$status]\n"
        fi
    fi
    done
done

echo -e "\n=== Outgoing Links OK ==="
for page in "${!PAGE_TO_OK_LINKS[@]}"; do
  echo "From page: $page"
  echo -e "${PAGE_TO_OK_LINKS[$page]}"
  echo
done

echo -e "=== Outgoing Links with Errors ==="
for page in "${!PAGE_TO_ERR_LINKS[@]}"; do
  echo "From page: $page"
  echo -e "${PAGE_TO_ERR_LINKS[$page]}"
  echo
done
