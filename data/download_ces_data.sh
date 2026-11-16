#!/usr/bin/env bash
# Download the CES common-content files analysisHQ.Rmd reads into data/CES Data/.
# Source: Harvard Dataverse (CC0). Each line pins a Dataverse file ID and its MD5,
# so reruns skip files that are already present and intact.
set -euo pipefail

dest="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/CES Data"
mkdir -p "$dest"

# file_id  md5  filename (as analysisHQ.Rmd expects, except 2018; see below)
files="
2438384  0c282e512c23353524a760e88b1e6c65  cces_2006_common.dta
2438385  56db35477b43f8214501e175b31f6509  cces_2008_common.dta
2419014  ad40fd08ed53eca4d272b734503c8baa  cces_2010_common_validated.dta
2456347  9ef04496652140f3767dac10beb58fd5  commoncontent2012.dta
14092734 a35b5eb4b81e607fddbc36f5f4be8e37  CCES14_Common_Content_Validated.dta
3123547  dc61fe62ab7b44b4f4f613b9ee72eeb1  CCES16_Common_OUTPUT_Feb2018_VV.dta
14075809 f6e3448be7a94197fcb4e3e750e4af09  CCES18_Common_OUTPUT_vv_topost.dta
4949545  f5fade09593144d00ffe4ca4f5e3835d  CES20_Common_OUTPUT_vv.dta
10140881 44ba1af9221fd24b618184b5d4d876d2  CCES22_Common_OUTPUT_vv_topost.dta
"

fetch() {
  local id=$1 md5=$2 name=$3 path="$dest/$3"
  if [[ -f "$path" ]] && [[ "$(md5sum "$path" | cut -d' ' -f1)" == "$md5" ]]; then
    echo "ok       $name"; return
  fi
  # format=original returns the uploaded .dta rather than Dataverse's ingested .tab.
  curl -fsSL --retry 3 -o "$path.part" \
    "https://dataverse.harvard.edu/api/access/datafile/$id?format=original"
  [[ "$(md5sum "$path.part" | cut -d' ' -f1)" == "$md5" ]] || { echo "md5 mismatch: $name" >&2; return 1; }
  mv "$path.part" "$path"
  echo "fetched  $name"
}
export -f fetch; export dest

echo "$files" | awk 'NF' | xargs -P 3 -L 1 bash -c 'fetch "$@"' _

# Dataverse's current 2018 release renamed the file analysisHQ.Rmd loads as cces18_common_vv.dta.
ln -sfn CCES18_Common_OUTPUT_vv_topost.dta "$dest/cces18_common_vv.dta"
