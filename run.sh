#!/bin/bash
# This script ensures the JOB_PAYLOAD environment variable (set by Cloud Build)
# is passed as a command-line argument to the Python script.
set -euo pipefail

echo "Executing Python script with payload from JOB_PAYLOAD..."
exec python ./diff_cleaner.py "$JOB_PAYLOAD"