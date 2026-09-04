#!/bin/bash
INPUT_DIR="${INPUT_DIR:-/config-src}"
OUTPUT_DIR="${OUTPUT_DIR:-/config-out}"
BASE_FILE="$INPUT_DIR/cfg.mih.uni.yml"

if [ ! -s "$BASE_FILE" ]; then
    echo "[mixer] ERROR: Base file '$BASE_FILE' is missing or empty! Aborting." >&2
    exit 1
fi

if ! yq eval '.' "$BASE_FILE" >/dev/null 2>&1; then
    echo "[mixer] ERROR: Base file contains invalid YAML structure! Aborting." >&2
    exit 1
fi

for layer_path in "$INPUT_DIR"/cfg.mih.*.yml; do
    [ -f "$layer_path" ] || continue
    [ "$layer_path" = "$BASE_FILE" ] && continue

    filename=$(basename "$layer_path")
    flavor=$(echo "$filename" | sed 's/cfg\.mih\.\(.*\)\.yml/\1/')
    output_file="$OUTPUT_DIR/config-$flavor.yml"
    
    if [ ! -s "$layer_path" ]; then
        echo "[mixer] WARNING: Layer file '$filename' is empty! Skipping overwrite." >&2
        continue
    fi

    if ! yq eval '.' "$layer_path" >/dev/null 2>&1; then
        echo "[mixer] WARNING: Layer file '$filename' has invalid YAML! Skipping." >&2
        continue
    fi

    tmp_file="/tmp/config-$flavor.tmp"
    if yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BASE_FILE" "$layer_path" > "$tmp_file"; then
        mv "$tmp_file" "$output_file"
        echo "[mixer] Successfully compiled: config-$flavor.yml"
        host_var="PROXY_$(echo "$flavor" | tr '[:lower:]' '[:upper:]')_HOST"
        proxy_host="${!host_var}"
        if [ -n "$proxy_host" ]; then
            if curl -sf -X PUT \
                -H "Authorization: Bearer ${MIHOMO_SECRET:-}" \
                -H "Content-Type: application/json" \
                -d "{\"path\": \"/config/config-$flavor.yml\", \"payload\": \"\"}" \
                "http://$proxy_host:9090/configs?force=true" >/dev/null; then
                echo "[mixer] Reloaded $proxy_host with config-$flavor.yml"
            else
                echo "[mixer] WARNING: failed to reload proxy at $proxy_host" >&2
            fi
        fi
    else
        rm -f "$tmp_file"
    fi
done
