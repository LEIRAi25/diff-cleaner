import os
import sys
import json
import base64
import hashlib
import logging
from google.cloud import firestore, bigquery
from google.cloud.exceptions import Conflict
from google.api_core import exceptions as api_exceptions

# Configuration via environment variables
env = os.environ
PROJECT_ID = env.get("GOOGLE_CLOUD_PROJECT") or env.get("PROJECT_ID")
FIRESTORE_DATABASE_ID = env.get("FIRESTORE_DATABASE_ID")  # This is a required variable.
FIRESTORE_COLLECTION = env.get("FIRESTORE_COLLECTION", "permit_hashes")
BQ_DATASET = env.get("BQ_DATASET", "permits_raw")
BQ_TABLE = env.get("BQ_TABLE", "landing")  # full table: {PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}

# Configure logging for better output in production environments like Cloud Run
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

if not PROJECT_ID:
    # Use critical level for fatal errors before exiting
    logging.critical("FATAL: GOOGLE_CLOUD_PROJECT or PROJECT_ID environment variable not set.")
    sys.exit(1)

if not FIRESTORE_DATABASE_ID:
    logging.critical("FATAL: The FIRESTORE_DATABASE_ID environment variable is required but was not set.")
    logging.critical("ACTION: Please configure this variable in your Cloud Run Job's settings.")
    sys.exit(1)

# Initialize clients
fs_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)
bq_client = bigquery.Client(project=PROJECT_ID)


class BigQueryInsertError(Exception):
    """Custom exception for BigQuery insertion failures."""
    pass


def compute_hash(permit_obj: dict) -> str:
    """
    Compute a SHA-256 hash of the JSON-serialized permit object.
    """
    # Ensure deterministic serialization
    serialized = json.dumps(permit_obj, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def is_new_hash(hash_str: str) -> bool:
    """
    Atomically check and create a document in Firestore for the given hash.
    Returns True if the document was created, False if it already existed.
    """
    doc_ref = fs_client.collection(FIRESTORE_COLLECTION).document(hash_str)
    try:
        # The create() method is atomic and will raise a Conflict exception
        # if the document already exists, preventing race conditions.
        doc_ref.create({"inserted_at": firestore.SERVER_TIMESTAMP})
        return True
    except Conflict:
        # The document already exists, so this is a duplicate.
        return False
    except api_exceptions.NotFound as e:
        # This provides more specific logging if the database is missing during the write operation.
        logging.critical(f"FATAL: Could not write to Firestore. The database '{FIRESTORE_DATABASE_ID}' may not exist or is misconfigured. Error: {e}")
        # Re-raise the exception to ensure the job fails as expected, but with better logging.
        raise


def write_to_bigquery(permit_obj: dict):
    """
    Insert the permit object into BigQuery landing table.
    """
    table_id = f"{PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}"
    # The insert_rows_json method expects a list of rows.
    rows_to_insert = [permit_obj]
    errors = bq_client.insert_rows_json(table_id, rows_to_insert)
    if errors:
        logging.error("Encountered errors while inserting rows into BigQuery.")
        for error in errors:
            # Each error is a dict with 'index' and 'errors' keys
            logging.error(f"  - Row index {error['index']}: {error['errors']}")
        raise BigQueryInsertError("Failed to insert rows into BigQuery.")


def main():
    """
    Entrypoint for the Cloud Run job.
    Expects a Base64-encoded JSON payload as the first command-line argument.
    It will fall back to parsing plain JSON if Base64 decoding fails.
    """
    # --- Configuration Logging ---
    # Log the configuration values the script is actually using. This helps debug environment issues.
    logging.info("--- Job Configuration (v3 - Explicit Build) ---")
    logging.info(f"  PROJECT_ID: {PROJECT_ID}")
    logging.info(f"  FIRESTORE_DATABASE_ID: {FIRESTORE_DATABASE_ID}")
    logging.info(f"  FIRESTORE_COLLECTION: {FIRESTORE_COLLECTION}")
    logging.info(f"  BIGQUERY_TABLE: {PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}")
    logging.info("-------------------------")

    # First, let's verify the Firestore connection as the logs indicate this is the problem area.
    try:
        # This is a simple, low-cost operation to check if the database is available.
        # We just need to see if we can start iterating collections.
        next(fs_client.collections(), None)
        logging.info(f"Successfully connected to Firestore database '{FIRESTORE_DATABASE_ID}'.")
    except api_exceptions.NotFound:
        logging.critical("-" * 50)
        logging.critical(f"FATAL: Firestore database '{FIRESTORE_DATABASE_ID}' not found in project '{PROJECT_ID}'.")
        logging.critical("This error means the SCRIPT IS RUNNING but cannot connect to the database.")
        logging.critical("ACTION: This is likely a deployment issue. Ensure the Cloud Run Job's configuration has the correct 'FIRESTORE_DATABASE_ID' environment variable set for the latest revision.")
        logging.critical("-" * 50)
        sys.exit(1)

    if len(sys.argv) < 2:
        logging.error("Usage: python diff_cleaner.py '<base64_json_payload>'")
        sys.exit(1)

    raw_input = sys.argv[1]
    permit = None

    # Pub/Sub messages are Base64 encoded. Try to decode first.
    try:
        # The `validate=True` flag ensures only valid Base64 is processed.
        decoded = base64.b64decode(raw_input, validate=True).decode("utf-8")
        permit = json.loads(decoded)
    except (ValueError, TypeError, base64.binascii.Error):
        logging.info("Input is not valid Base64. Falling back to parsing as plain JSON.")
        try:
            permit = json.loads(raw_input)
        except json.JSONDecodeError:
            logging.error("Input is not valid JSON.", exc_info=True)
            sys.exit(1)

    # Compute hash and dedupe
    h = compute_hash(permit)
    if not is_new_hash(h):
        logging.info(f"Duplicate permit, hash={h}, skipping.")
        return

    # Insert into BigQuery
    write_to_bigquery(permit)
    logging.info(f"Successfully inserted new permit, hash={h}.")


if __name__ == "__main__":
    main()
