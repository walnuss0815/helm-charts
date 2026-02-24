#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

"$SCRIPT_DIR/decryptpdf.sh" "$PDF_DECRYPTION_PASSWORD_PATH"
