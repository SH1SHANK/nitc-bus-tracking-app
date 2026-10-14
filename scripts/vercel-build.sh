#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================"
echo "ERROR: In-container Vercel builds are disabled for Tracklet."
echo "Tracklet follows the 'Build Once, Verify, Deploy Prebuilt' DevSecOps pipeline."
echo "Flutter Web is built and verified once in GitHub Actions (.github/workflows/deploy-web.yml)"
echo "and deployed to Vercel as a prebuilt bundle using 'vercel deploy --prebuilt'."
echo "================================================================================"
exit 1
