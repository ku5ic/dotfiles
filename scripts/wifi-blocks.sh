#!/usr/bin/env bash
set -euo pipefail

# Counts NEIGHBOURING 5 GHz APs per 160 MHz block, ignoring anything weaker than the threshold.
# Only parses the "Other Local Wi-Fi Networks" section, so the connected AP is excluded.
# Usage: wifi-blocks [rssi_threshold]   (default -75)

threshold="${1:--75}"

system_profiler SPAirPortDataType | awk -v th="$threshold" '
  # Section headers sit at 10 spaces; that indent or shallower ends the neighbours
  # block. Tested by substring rather than a /^ {0,10}/ interval, which not every awk supports.
  substr($0, 1, 11) ~ /[^ ]/       { inblock = 0 }
  /^ *Other Local Wi-Fi Networks:/ { inblock = 1; seen = 1; next }
  !inblock                         { next }

  /Channel: /          { pending = $2 + 0 }
  /Signal \/ Noise: / {
    rssi = $4 + 0
    if (!pending || rssi < th + 0) { pending = 0; next }
    if (pending >= 36  && pending <= 64)  { low++;  lowlist  = lowlist  " " pending "(" rssi ")" }
    if (pending >= 100 && pending <= 128) { high++; highlist = highlist " " pending "(" rssi ")" }
    pending = 0
  }

  END {
    if (!seen) {
      print "No scan results: Wi-Fi is off, or the interface reported no neighbouring networks." > "/dev/stderr"
      exit 1
    }
    printf "Threshold: %s dBm (neighbours only)\n\n", th
    printf "36-64   : %d AP%s%s\n", low+0,  (low+0  == 1 ? "" : "s"), lowlist
    printf "100-128 : %d AP%s%s\n", high+0, (high+0 == 1 ? "" : "s"), highlist
    if (high+0 < low+0)
      print "\nPick: 100-128 (control channel 100) - DFS, expect occasional radar channel changes"
    else
      print "\nPick: 36-64 (control channel 36)"
  }
'
