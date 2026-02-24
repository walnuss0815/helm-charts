#!/usr/bin/env bash

PASSWORD_PATH=$1
ORIGINAL_FILE_PATH="$DOCUMENT_SOURCE_PATH"
DECRYPTED_FILE_PATH="$DOCUMENT_WORKING_PATH"
FILE_NAME=${ORIGINAL_FILE_PATH##*/}

get_password_files() {
  SEARCH_PATH=$1
  for f in $(find "$SEARCH_PATH" -type f); do echo $f; done
}

check_encryption() {
  qpdf --requires-password "$ORIGINAL_FILE_PATH"
}

decrypt_file() {
  PASSWORD=$1
  qpdf --password="$PASSWORD" --decrypt "$ORIGINAL_FILE_PATH" "$DECRYPTED_FILE_PATH" > /dev/null 2>&1
}

if check_encryption; then
  echo "$FILE_NAME is encrypted. Trying decryption..."
  PASSWORD_FILES=$(get_password_files "$PASSWORD_PATH")

  for password_file in $PASSWORD_FILES; do
    if decrypt_file "$(cat "$password_file")"; then
      echo "$FILE_NAME has been successfully decrypted."
      exit 0
    fi
  done
  echo "$FILE_NAME cannot be decrypted."
  exit 1
else
  echo "$FILE_NAME is not encrypted."
  exit 0
fi
