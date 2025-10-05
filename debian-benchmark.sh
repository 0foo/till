#!/usr/bin/env bash
# bench-debian-mirrors.sh
# Benchmark Debian mirrors (from Ubuntu or anywhere)
# - Tests real download throughput of dists/<release>/InRelease
# - Works with a built-in mirror list or a custom list via --mirrors-file
# - Outputs a sorted table by fastest speed

set -euo pipefail

release="bookworm"
mirrors_file=""
timeout_s=6

usage() {
  cat <<EOF
Usage: $0 [-r <debian-release>] [-m <mirrors-file>] [-t <timeout-seconds>]

Options:
  -r  Debian release codename to test (default: ${release})
      Examples: bookworm, trixie, bullseye
  -m  Path to a file containing mirror base URLs (one per line).
      If not provided, a built-in list is used.
  -t  Per-request timeout in seconds (default: ${timeout_s})

Notes:
  * The test URL on each mirror is: <mirror>/dists/<release>/InRelease
  * Only HTTP 200 results are considered valid for ranking.
  * Requires: curl, awk, sort
EOF
}

while getopts ":r:m:t:h" opt; do
  case "$opt" in
    r) release="$OPTARG" ;;
    m) mirrors_file="$OPTARG" ;;
    t) timeout_s="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

# Built-in set of commonly reliable Debian mirrors (HTTP/HTTPS).
# Feel free to add/remove mirrors relevant to your region.
builtin_mirrors=(
  "http://deb.debian.org/debian"
  "http://ftp.us.debian.org/debian"
  "http://ftp.de.debian.org/debian"
  "http://ftp.uk.debian.org/debian"
  "http://mirror.csclub.uwaterloo.ca/debian"
  "http://mirror.ox.ac.uk/debian"
  "http://mirror.netcologne.de/debian"
  "http://ftp.fr.debian.org/debian"
  "http://mirror.vcu.edu/debian"
  "http://mirrors.ocf.berkeley.edu/debian"
  "http://mirrors.rit.edu/debian"
  "http://mirror.math.princeton.edu/pub/debian"
)

# Load mirrors
mirrors=()
if [[ -n "$mirrors_file" ]]; then
  if [[ ! -f "$mirrors_file" ]]; then
    echo "Mirrors file not found: $mirrors_file" >&2
    exit 1
  fi
  # filter out empty lines and comments
  mapfile -t mirrors < <(grep -Ev '^\s*(#|$)' "$mirrors_file")
else
  mirrors=("${builtin_mirrors[@]}")
fi

if [[ ${#mirrors[@]} -eq 0 ]]; then
  echo "No mirrors to test." >&2
  exit 1
fi

# Header
printf "%-45s  %8s  %10s  %6s  %s\n" "MIRROR" "HTTP" "SPEED(KB/s)" "TIME(s)" "STATUS"
printf "%-45s  %8s  %10s  %6s  %s\n" "---------------------------------------------" "--------" "----------" "------" "------"

# Collect results: mirror|http_code|speed_kbs|time_total|status_text
results="$(mktemp)"
trap 'rm -f "$results"' EXIT

for m in "${mirrors[@]}"; do
  url="${m%/}/dists/${release}/InRelease"
  # curl outputs: "<time_total> <speed_download> <http_code>"
  read -r time_total speed_bytes http_code < <(
    curl -L -sS --max-time "$timeout_s" --connect-timeout 3 \
         -o /dev/null \
         -w '%{time_total} %{speed_download} %{http_code}\n' \
         "$url" || echo "999 0 000"
  )

  # Convert bytes/sec to KB/s with 1 decimal
  # Guard against zero/invalid values
  speed_kbs="0.0"
  if awk "BEGIN{exit !($speed_bytes > 0)}"; then
    speed_kbs=$(awk -v b="$speed_bytes" 'BEGIN{printf "%.1f", b/1024}')
  fi

  status="OK"
  if [[ "$http_code" != "200" ]]; then
    status="BAD"
  fi
  if [[ "$time_total" == "999" ]]; then
    status="TIMEOUT"
    time_total="$timeout_s"
  fi

  printf "%-45s  %8s  %10s  %6s  %s\n" "$m" "$http_code" "$speed_kbs" "$time_total" "$status"
  printf "%s|%s|%s|%s|%s\n" "$m" "$http_code" "$speed_kbs" "$time_total" "$status" >>"$results"
done

echo
echo "Ranking (valid mirrors only, HTTP 200) ..."
# Sort by speed (desc), then time (asc)
best_line=$(awk -F'|' '$2=="200"{print $0}' "$results" | sort -t'|' -k3,3nr -k4,4n | head -n1 || true)

if [[ -n "$best_line" ]]; then
  best_mirror=$(echo "$best_line" | awk -F'|' '{print $1}')
  best_speed=$(echo  "$best_line" | awk -F'|' '{print $3}')
  best_time=$(echo   "$best_line" | awk -F'|' '{print $4}')
  echo "Best mirror: $best_mirror"
  echo "Speed: ${best_speed} KB/s, Time: ${best_time} s"
  echo
  echo "Example sources.list entry for ${release}:"
  echo "  deb ${best_mirror} ${release} main contrib non-free non-free-firmware"
  echo
else
  echo "No valid mirrors (HTTP 200) were found for release '${release}'."
  echo "Check network/firewall or try a different release with: $0 -r <codename>"
fi
