#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------
# Configuration (filled in placeholders)
# ---------------------------------------------------
GITHUB_OWNER="LEIRAI25"
GITHUB_REPO="diff-cleaner"
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
JOB_NAME="diff-cleaner"

# ---------------------------------------------------
# 1. Remove existing scheduler job to avoid conflicts
# ---------------------------------------------------
echo "Deleting old scheduler job 'trigger-diff-cleaner' if it exists..."
gcloud scheduler jobs delete trigger-diff-cleaner --location=us-central1 --quiet || true

# ---------------------------------------------------
# 2. Create a new Cloud Scheduler job to trigger pubsub
# ---------------------------------------------------
# Assumes you have a Pub/Sub topic named 'trigger-diff-cleaner'
echo "Creating scheduler job 'sched-diff-cleaner' (every 5 minutes)..."
gcloud scheduler jobs create pubsub sched-diff-cleaner \
  --project="$PROJECT_ID" \
  --location="$REGION" \
  --schedule="*/5 * * * *" \
  --topic="trigger-diff-cleaner" \
  --message-body='{"permit_id":"SCHEDULED","note":"scheduled trigger"}'

# ---------------------------------------------------
# 3. Initialize GitHub repository (if not done already)
# ---------------------------------------------------
# This will create and push your local code to GitHub
if ! gh repo view "$GITHUB_OWNER/$GITHUB_REPO" &>/dev/null; then
  echo "Creating GitHub repo $GITHUB_OWNER/$GITHUB_REPO..."
  gh repo create "$GITHUB_OWNER/$GITHUB_REPO" --public --source=. --remote=origin --push
else
  echo "GitHub repo already exists: $GITHUB_OWNER/$GITHUB_REPO"
fi

# ---------------------------------------------------
# 4. Create Cloud Build trigger for GitHub pushes
# ---------------------------------------------------
echo "Setting up Cloud Build trigger 'diff-cleaner-trigger'..."
# Delete existing trigger if present
gcloud beta builds triggers delete diff-cleaner-trigger --quiet || true

gcloud beta builds triggers create github \
  --name="diff-cleaner-trigger" \
  --repo-name="$GITHUB_REPO" \
  --repo-owner="$GITHUB_OWNER" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.yaml" \
  --substitutions="_REGION=$REGION,_JOB_NAME=$JOB_NAME,_IMAGE_NAME=us-central1-docker.pkg.dev/$PROJECT_ID/permits/$JOB_NAME"

# ---------------------------------------------------
# 5. (Optional) Notification channel setup skipped
# ---------------------------------------------------
echo "Skipping Monitoring notification channel setup (none provided)."

echo "✅ Infrastructure setup complete!"
