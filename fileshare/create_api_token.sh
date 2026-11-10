#!/usr/bin/env bash
# Usage: ./create_api_token.sh <user-email> [token-name]
set -euo pipefail
cd "$(dirname "$0")"
[ $# -ge 1 ] || { echo "Usage: $0 <user-email> [token-name]"; exit 1; }
php artisan api:token "$1" --name="${2:-api-client}" --years=20
