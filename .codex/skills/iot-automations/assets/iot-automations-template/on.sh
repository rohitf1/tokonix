#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tuya_bulb.py" on
