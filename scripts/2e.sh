#!/bin/sh

2e_projects_tmux() {
    projects_keys=("eebook" "eebook-bwa" "eebook-eed" "eepayweb" "eepxa-app" "eeopaque-fe-cli" "eeopaque-fe-srv" "bti-fe")

    for key in "${projects_keys[@]}"; do
        case $key in
            "eebook") value="eebook/eebkgweb" ;;
            "eebook-bwa") value="eebook/eebkgweb-bwa-custom" ;;
            "eebook-eed") value="eebook/eebkgweb-eed-custom" ;;
            "eepayweb") value="eepay/eepayweb" ;;
            "eepxa-app") value="mobile/eepxa-app" ;;
            "eeopaque-fe-cli") value="eeopaque/eeopqfecli" ;;
            "eeopaque-fe-srv") value="eeopaque/eeopqfesrv" ;;
            "bti-fe") value="bti/btife" ;;
        esac
        echo "Key: $key, Value: $value"
        tmuxinator start 2e-eebook project="$value" -n "$key"
    done
}
