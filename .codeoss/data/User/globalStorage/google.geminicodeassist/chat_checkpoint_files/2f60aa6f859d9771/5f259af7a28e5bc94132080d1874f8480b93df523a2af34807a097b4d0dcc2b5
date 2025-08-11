import os
import sys
import json
import base64
import hashlib
from google.cloud import firestore, bigquery

# Configuration via environment variables
env = os.environ
PROJECT_ID = env.get("GOOGLE_CLOUD_PROJECT") or env.get("PROJECT_ID")
FIRESTORE_COLLECTION = env.get("FIRESTORE_COLLECTION", "permit_hashes")
BQ_DATASET = env.get("BQ_DATASET", "permits_raw")
BQ_TABLE = env.get("BQ_TABLE", "landing")  # full table: {PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}

# Initialize clients
fs_client = firestore.Client(project=PROJECT_ID)
bq_client = bigquery.Client(project=PROJECT_ID)


def compute_hash(permit_obj: dict) -> str:
    """
    Compute a SHA-256 hash of the JSON-serialized permit object.
    """
    # Ensure deterministic serialization
    serialized = json.dumps(permit_obj, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def is_new_hash(hash_str: str) -> bool:
    """
    Check Firestore to see if this hash exists. Return True if new.
    """
    doc_ref = fs_client.collection(FIRESTORE_COLLECTION).document(hash_str)
    doc = doc_ref.get()
    if doc.exists:
        return False
    # not seen before: create a record
    doc_ref.set({"inserted_at": firestore.SERVER_TIMESTAMP})
    return True


def write_to_bigquery(permit_obj: dict):
    """
    Insert the permit object into BigQuery landing table.
    """
    table_id = f"{PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}"
    errors = bq_client.insert_rows_json(table_id, [permit_obj])
    if errors:
        raise RuntimeError(f"BigQuery insert errors: {errors}")


def main():
    """
    Entrypoint for the Cloud Run job.
    Expects the raw permit JSON as the first command-line argument.
    """
    if len(sys.argv) < 2:
        print("Usage: python diff_cleaner.py '<base64_msg>'")
        sys.exit(1)

    # Pub/Sub messages often get base64-encoded. Decode if necessary.
    raw_input = sys.argv[1]
    try:
        decoded = base64.b64decode(raw_input).decode("utf-8")
        permit = json.loads(decoded)
    except Exception:
        # fallback: assume plain JSON
        permit = json.loads(raw_input)

    # Compute hash and dedupe
    h = compute_hash(permit)
    if not is_new_hash(h):
        print(f"Duplicate permit, hash={h}, skipping.")
        return

    # Insert into BigQuery
    write_to_bigquery(permit)
    print(f"Inserted new permit, hash={h}.")


if __name__ == "__main__":
    main()
