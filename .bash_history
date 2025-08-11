gcloud auth configure-docker us-central1-docker.pkg.dev
docker build -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
# Authenticate Docker (if you haven’t already)
gcloud auth configure-docker us-central1-docker.pkg.dev
# Build (if you haven’t already)
docker build -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
# Push into the newly created repo
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
latest: digest: sha256:e2ca1beb4dca326199c83d374b
pwd
ls
docker build -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker pull us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker run --rm us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest ls -l /app
docker run --rm   --entrypoint sh   us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest   -c "ls -l /app"
docker pull us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker run --rm   --entrypoint sh   us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest   -c "ls -l /ap





total 0
ariel@cloudshell:~ (vantage-468221)$ docker pull us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
latest: Pulling from vantage-468221/permits/diff-cleaner
Digest: sha256:e2ca1beb4dca326199c83d374b0cfeeea5a4ce29f7153076632efdeba735db40
Status: Image is up to date for us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
ariel@cloudshell:~ (vantage-468221)$ docker run --rm   --entrypoint sh   us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest   -c "ls -l /ap
> 
docker run --rm --entrypoint sh us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest -c "echo 'Contents of /app:'; ls -l /app"
ls -1
# 1) List files in the current directory
ls -l
# 2) Show the top of your Dockerfile to confirm it’s the one we drafted
sed -n '1,20p' Dockerfile
docker build --no-cache -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker run --rm --entrypoint sh   us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest   -c "ls -l /app"
# Show the entire Dockerfile with line numbers
nl -ba Dockerfile
# Insert COPY diff_cleaner.py /app/ after the WORKDIR line
sed -i '2a COPY diff_cleaner.py /app/' Dockerfile
# Show the top of Dockerfile to confirm
head -n 10 Dockerfile
docker build --no-cache -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker build --no-cache -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker build --no-cache -t us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest .
docker push us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest
docker run --rm   --entrypoint sh   us-central1-docker.pkg.dev/vantage-468221/permits/diff-cleaner:latest   -c "echo 'Contents of /app:'; ls -l /app"
gcloud run jobs execute diff-cleaner   --region=us-central1   --project=vantage-468221   --args='{"permit_id":"MANUAL-TEST","note":"testing end-to-end"}'
gcloud auth login            # if you haven’t already
gcloud config set project vantage-468221
gcloud run jobs execute diff-cleaner   --region=us-central1   --project=vantage-468221   --args='{"permit_id":"MANUAL-TEST","note":"testing end-to-end"}'
gcloud builds submit --config cloudbuild.yaml .
gcloud config set project vantage-468221
gcloud builds submit --config cloudbuild.yaml .
# First, get your project number, which is used in the service account's email address
PROJECT_NUMBER=$(gcloud projects describe vantage-468221 --format='value(projectNumber)')
# Define the Cloud Build service account email
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
# --- Grant Required Roles ---
# 1. (Fixes current error) Allow Cloud Build to access source code and perform its duties
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/cloudbuild.serviceAgent"
# 2. (Proactive fix) Allow Cloud Build to push images to Artifact Registry
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/artifactregistry.writer"
# 3. (Proactive fix) Allow Cloud Build to update your Cloud Run job
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/run.admin"
# 4. (Proactive fix) Allow Cloud Build to act as the Cloud Run job's service account during deployment
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/iam.serviceAccountUser"
gcloud builds submit --config cloudbuild.yaml .
# The service account your Cloud Run job runs as
RUN_SA="vantage-cloud@vantage-468221.iam.gserviceaccount.com"
echo "Granting permissions to Cloud Run service account: ${RUN_SA}"
# Allow the job to read/write to Firestore
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${RUN_SA}"     --role="roles/datastore.user"
# Allow the job to write to BigQuery
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${RUN_SA}"     --role="roles/bigquery.dataEditor"
echo "Permissions granted."
# Get your project number, which is part of the Cloud Build service account's email
PROJECT_NUMBER=$(gcloud projects describe vantage-468221 --format='value(projectNumber)')
# Define the Cloud Build service account email
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo "Granting permissions to Cloud Build service account: ${CLOUDBUILD_SA}"
# 1. (Fixes the build error) Allow Cloud Build to access source code and perform its duties
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/cloudbuild.builds.builder"
# 2. (Proactive fix) Allow Cloud Build to push images to Artifact Registry
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/artifactregistry.writer"
# 3. (Proactive fix) Allow Cloud Build to update your Cloud Run job
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/run.admin"
# 4. (Proactive fix) Allow Cloud Build to act as the Cloud Run job's service account during deployment
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/iam.serviceAccountUser"
echo "All necessary permissions have been granted."
# Get your project number again, just in case
PROJECT_NUMBER=$(gcloud projects describe vantage-468221 --format='value(projectNumber)')
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo "Granting necessary roles to ${CLOUDBUILD_SA}..."
# 1. (Fixes current error) Allow Cloud Build to access source code and logs
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/cloudbuild.builds.builder"
# 2. (Proactive fix) Allow Cloud Build to push images to Artifact Registry
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/artifactregistry.writer"
# 3. (Proactive fix) Allow Cloud Build to update your Cloud Run job
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/run.admin"
# 4. (Proactive fix) Allow Cloud Build to act as the Cloud Run job's service account
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:${CLOUDBUILD_SA}"     --role="roles/iam.serviceAccountUser"
echo "All permissions have been granted. Please try your build again."
gcloud builds submit --config cloudbuild.yaml .gcloud builds submit --config cloudbuild.yaml .
gcloud builds submit --config cloudbuild.yaml .
gcloud projects add-iam-policy-binding vantage-468221     --member="serviceAccount:270221788805-compute@developer.gserviceaccount.com"     --role="roles/logging.logWriter"
gcloud builds submit --config cloudbuild.yaml .
gcloud iam service-accounts add-iam-policy-binding $(gcloud projects describe vantage-468221 --format="value(projectNumber)")-compute@developer.gserviceaccount.com --member=serviceAccount:$(gcloud projects describe vantage-468221 --format="value(projectNumber)")-compute@developer.gserviceaccount.com --role="roles/iam.serviceAccountUser" --project=vantage-468221
export GITHUB_PAT="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"
echo "$GITHUB_PAT" | gh auth login
gh auth status
export GITHUB_OWNER="LEIRAI25"
export GITHUB_REPO="diff-cleaner"
export PROJECT_ID="vantage-468221"
export REGION="us-central1"
./setup_infra.sh
gcloud builds triggers list | grep diff-cleaner
