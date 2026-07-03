#!/bin/sh
set -eu

USERS_FILE=users.txt
TEMPLATE_DIR="."

[ -f "${USERS_FILE}" ] || { echo "${USERS_FILE} not found!"; exit 1; }
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <realm>, e.g. $0 https://kc.example.com/realms/test"
  exit 1
else
  export REALM="$1"
fi

for USER in $(cat "${USERS_FILE}"); do
  export USER

  echo "Generating manifests for $USER..."
  for file in *.yaml; do
    envsubst < "$TEMPLATE_DIR/$file" | kubectl apply -f -
  done

done

echo "Done."
