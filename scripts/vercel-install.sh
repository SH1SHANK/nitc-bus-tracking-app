#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================"
echo "ERROR: In-container Vercel SDK installation is disabled for Tracklet."
echo "Tracklet builds use GitHub Actions runners with repository-locked dependencies."
echo "================================================================================"
exit 1
