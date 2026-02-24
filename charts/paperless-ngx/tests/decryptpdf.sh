#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PASSWORD_PATH="$SCRIPT_DIR/tmp/passwords"

export "DOCUMENT_SOURCE_PATH=$SCRIPT_DIR/tmp/sample-encrypted.pdf"
export "DOCUMENT_WORKING_PATH=$SCRIPT_DIR/tmp/sample-decrypted.pdf"

prepare_example_pdf() {
  PASSWORD=$1
  mkdir -p "$SCRIPT_DIR/tmp"
  wget https://pdfobject.com/pdf/sample.pdf -O "$SCRIPT_DIR/tmp/sample.pdf"
  qpdf --encrypt "$PASSWORD" "$PASSWORD" 256 -- "$SCRIPT_DIR/tmp/sample.pdf" "$SCRIPT_DIR/tmp/sample-encrypted.pdf"
}

prepare_example_passwords() {
  for l in {a..z}; do
    mkdir -p "$PASSWORD_PATH/$l"
    for i in {1..10}; do
      echo "$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)" > "$PASSWORD_PATH/$l/$i"
    done
  done
}

prepare_example_passwords

PASSWORD="$(cat "$PASSWORD_PATH/n/5")"
echo "PW: $PASSWORD"
prepare_example_pdf "$PASSWORD"

"$SCRIPT_DIR/../scripts/decryptpdf.sh" "$PASSWORD_PATH"
