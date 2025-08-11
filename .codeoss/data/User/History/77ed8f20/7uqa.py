import os
import sys
import json
import hashlib
import logging
import base64
from google.cloud import firestore
from google.cloud import bigquery
from google.api_core import exceptions

# --- Configuration -----------------------------------------------------------

# Configure basic logging to standard output, which Cloud Run captures.
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Get Project ID and Firestore DB ID from environment variables.
# The Cloud Run job environment must have these set.
PROJECT_ID = os.environ.get('PROJECT_ID')
FIRESTORE_DATABASE_ID = os.environ.get('FIRESTORE_DATABASE_ID', '(default)')

# Firestore collection for storing hashes to prevent duplicates
FIRESTORE_COLLECTION = 'processed_hashes'

# BigQuery dataset and table for storing the permit data
BIGQUERY_DATASET = 'permits'
BIGQUERY_TABLE = 'permits_raw'

# --- Initialization ----------------------------------------------------------

# Initialize clients
try:
    if not PROJECT_ID:
        logging.critical("FATAL: PROJECT_ID environment variable not set.")
        sys.exit(1)

    # When connecting to a non-default database, you must specify it.
    db = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)
    bq_client = bigquery.Client(project=PROJECT_ID)
    logging.info(f"Clients initialized for project '{PROJECT_ID}' and Firestore DB '{FIRESTORE_DATABASE_ID}'.")

except Exception as e:
    logging.critical(f"Failed to initialize Google Cloud clients: {e}")
    sys.exit(1)


# --- Core Functions ----------------------------------------------------------

def is_new_hash(data_hash: str) -> bool:
    """
    Checks if a hash already exists in the Firestore collection.
    If it doesn't exist, it creates the document and returns True.
    If it exists, it returns False.
    """
    doc_ref = db.collection(FIRESTORE_COLLECTION).document(data_hash)
    try:
        doc = doc_ref.get()
        if doc.exists:
            logging.info(f"Hash {data_hash} already exists. Skipping.")
            return False
        else:
            # Document doesn't exist, so we create it to mark as processed.
            doc_ref.create({"inserted_at": firestore.SERVER_TIMESTAMP})
            logging.info(f"New hash {data_hash} added to Firestore.")
            return True
    except Exception as e:
        logging.error(f"Error checking or creating hash document in Firestore: {e}")
        # Fail safely by assuming it's not new to prevent duplicate processing.
        return False

def insert_into_bigquery(data: dict):
    """Inserts a dictionary as a new row into the BigQuery table."""
    table_id = f"{PROJECT_ID}.{BIGQUERY_DATASET}.{BIGQUERY_TABLE}"
    try:
        # BigQuery's insert_rows_json expects a list of dictionaries
        errors = bq_client.insert_rows_json(table_id, [data])
        if not errors:
            logging.info(f"Successfully inserted 1 row into {table_id}.")
        else:
            logging.error(f"Encountered errors while inserting rows into BigQuery: {errors}")
    except Exception as e:
        logging.error(f"Failed to insert row into BigQuery table {table_id}: {e}")

def main():
    """
    Main execution logic.
    Reads payload, checks for duplicates, and inserts into BigQuery if new.
    """
    payload_str = os.environ.get('JOB_PAYLOAD')

    if not payload_str:
        logging.critical("FATAL: JOB_PAYLOAD environment variable not set.")
        sys.exit(1)

    try:
        data = json.loads(payload_str)
    except json.JSONDecodeError:
        logging.error(f"Invalid JSON in JOB_PAYLOAD: {payload_str}")
        sys.exit(1)

    # Create a stable hash of the incoming data to check for duplicates
    canonical_json = json.dumps(data, sort_keys=True).encode('utf-8')
    data_hash = hashlib.sha256(canonical_json).hexdigest()

    logging.info(f"Processing payload with hash: {data_hash}")

    if is_new_hash(data_hash):
        insert_into_bigquery(data)

if __name__ == "__main__":
    main()