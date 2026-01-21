#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for required tools
for cmd in sops butane envsubst; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Check for encrypted secrets
if [[ ! -f secrets.env.sops ]]; then
    echo "Error: secrets.env.sops not found."
    echo "Create it from secrets.env.example:"
    echo "  cp secrets.env.example secrets.env"
    echo "  # Edit secrets.env with real values"
    echo "  sops -e secrets.env > secrets.env.sops"
    echo "  rm secrets.env"
    exit 1
fi

echo "Decrypting secrets..."
sops -d secrets.env.sops > secrets.env

# Export all variables from secrets.env
set -a
source secrets.env
set +a

echo "Generating Ignition config..."
envsubst < flatcar.bu.yaml | butane --strict -o flatcar.ign

# Clean up decrypted secrets
rm -f secrets.env

echo "Done: flatcar.ign generated"
echo ""
echo "To deploy, upload flatcar.ign to Proxmox and attach to VM."
