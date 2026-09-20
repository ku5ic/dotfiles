#!/usr/bin/env bats
# Tests for ~/.dotfiles/scripts/wifi-blocks.sh.
#
# The script shells out to system_profiler, which is macOS-only and returns live
# scan data, so every test puts a stub earlier on PATH that replays a fixture
# built by the helpers below. That keeps the suite hermetic and runnable on the
# Linux CI box.
#
# Run with: bats tests/

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/wifi-blocks.sh"
  FIXTURE="$BATS_TEST_TMPDIR/scan.txt"
  STUB_BIN="$BATS_TEST_TMPDIR/bin"

  mkdir -p "$STUB_BIN"
  printf '#!/usr/bin/env bash\ncat "%s"\n' "$FIXTURE" >"$STUB_BIN/system_profiler"
  chmod +x "$STUB_BIN/system_profiler"
}

# The connected AP sits on channel 44 at -35 dBm, above every threshold used
# here, so any test whose 36-64 count is off by one has leaked it in.
begin_scan() {
  cat >"$FIXTURE" <<'EOF'
Wi-Fi:

      Interfaces:
        en0:
          Current Network Information:
            MyConnectedAP:
              PHY Mode: 802.11a/n/ac/ax
              Channel: 44 (5GHz, 160MHz)
              Signal / Noise: -35 dBm / -92 dBm
          Other Local Wi-Fi Networks:
EOF
}

# neighbour <channel> <band> <rssi>
neighbour() {
  cat >>"$FIXTURE" <<EOF
            AP-on-$1:
              PHY Mode: 802.11a/n/ac/ax
              Channel: $1 ($2, 80MHz)
              Network Type: Infrastructure
              Security: WPA2 Personal
              Signal / Noise: $3 dBm / -92 dBm
EOF
}

# A second interface section trailing the neighbours block.
append_awdl_section() {
  cat >>"$FIXTURE" <<'EOF'
        awdl0:
          Current Network Information:
            AwdlPeer:
              PHY Mode: 802.11a/n/ac/ax
              Channel: 108 (5GHz, 80MHz)
              Signal / Noise: -30 dBm / -92 dBm
EOF
}

run_blocks() {
  PATH="$STUB_BIN:$PATH" run "$SCRIPT" "$@"
}

@test "counts a neighbour in the 36-64 block" {
  begin_scan
  neighbour 36 5GHz -50
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 1 AP 36(-50)"* ]]
  [[ "$output" == *"100-128 : 0 APs"* ]]
}

@test "counts a neighbour in the 100-128 block" {
  begin_scan
  neighbour 104 5GHz -60
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 0 APs"* ]]
  [[ "$output" == *"100-128 : 1 AP 104(-60)"* ]]
}

@test "excludes the connected AP on channel 44" {
  begin_scan
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 0 APs"* ]]
}

@test "ignores a neighbour weaker than the default threshold" {
  begin_scan
  neighbour 40 5GHz -88
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 0 APs"* ]]
}

@test "a looser threshold argument admits the weak neighbour" {
  begin_scan
  neighbour 40 5GHz -88
  run_blocks -90
  [ "$status" -eq 0 ]
  [[ "$output" == *"Threshold: -90 dBm"* ]]
  [[ "$output" == *"36-64   : 1 AP 40(-88)"* ]]
}

# Regression: inblock used to stay set for the rest of the file, so a strong AP
# in any section after the neighbours block was counted as a neighbour.
@test "ignores channels in a section following the neighbours block" {
  begin_scan
  neighbour 52 5GHz -55
  append_awdl_section
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 1 AP 52(-55)"* ]]
  [[ "$output" == *"100-128 : 0 APs"* ]]
}

# Regression: channel numbers were compared as strings, so under an awk that
# keeps the post-gsub value a string ("6" >= "36" is true) a 2.4 GHz neighbour
# landed in the 36-64 block.
@test "does not count 2.4 GHz channels in the 5 GHz blocks" {
  begin_scan
  neighbour 6 2GHz -40
  neighbour 1 2GHz -45
  neighbour 11 2GHz -42
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 0 APs"* ]]
  [[ "$output" == *"100-128 : 0 APs"* ]]
}

@test "pluralises the AP count" {
  begin_scan
  neighbour 36 5GHz -50
  neighbour 60 5GHz -55
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"36-64   : 2 APs 36(-50) 60(-55)"* ]]
}

@test "recommends 100-128 when it is the quieter block" {
  begin_scan
  neighbour 36 5GHz -50
  neighbour 60 5GHz -55
  neighbour 104 5GHz -60
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pick: 100-128 (control channel 100)"* ]]
}

@test "recommends 36-64 when the blocks are tied" {
  begin_scan
  neighbour 36 5GHz -50
  neighbour 104 5GHz -60
  run_blocks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pick: 36-64 (control channel 36)"* ]]
}

@test "fails when the scan reports no neighbours section" {
  cat >"$FIXTURE" <<'EOF'
Wi-Fi:

      Interfaces:
        en0:
          Status: Off
EOF
  run_blocks
  [ "$status" -eq 1 ]
  [[ "$output" == *"No scan results"* ]]
}
