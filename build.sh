#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

CODESIGN_IDENTITY='Developer ID Application: zpershuai@gmail.com'

echo "Installing VoiceInput with signing identity:"
echo "  $CODESIGN_IDENTITY"

make install CODESIGN_IDENTITY="$CODESIGN_IDENTITY"
