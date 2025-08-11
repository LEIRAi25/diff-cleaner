import os
import json
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)

def handler(event, context):
    """Cloud Run job entry point."""
    logging.info(f"Received event: {event}")
    logging.info(f"Received context: {context}")

    # The event is the JSON payload from the Cloud Run job
    logging.info(f"Job payload: {event}")

if __name__ == "__main__":
    # This allows the script to be run locally for testing
    job_payload_str = os.environ.get("JOB_PAYLOAD")
    if job_payload_str:
        try:
            event = json.loads(job_payload_str)
            handler(event, None)
        except json.JSONDecodeError:
            logging.error(f"Invalid JSON in JOB_PAYLOAD: {job_payload_str}")
    else:
        logging.info("JOB_PAYLOAD environment variable not set.")