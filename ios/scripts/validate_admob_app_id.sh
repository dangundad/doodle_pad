#!/bin/sh

set -eu

if [ "${CONFIGURATION:-}" = "Release" ] && [ -z "${GAD_APPLICATION_IDENTIFIER:-}" ]; then
  echo "error: IOS_ADMOB_APP_ID must be set for iOS Release builds." >&2
  exit 1
fi
