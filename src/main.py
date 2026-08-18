import os
import time
import requests
import clickhouse_connect
from dotenv import load_dotenv

# Load config from .env
load_dotenv()

API_URL = os.getenv("API_URL", "http://api.open-notify.org/astros.json")
DB_HOST = os.getenv("CLICKHOUSE_HOST", "localhost")
DB_PORT = int(os.getenv("CLICKHOUSE_PORT", 8123))
DB_USER = os.getenv("CLICKHOUSE_USER", "admin")
DB_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "admin")

MAX_RETRIES = 5
TIMEOUT = 10


def fetch_data(url: str, retries: int = MAX_RETRIES) -> str:
    """Fetch raw JSON from API with exponential backoff on errors."""
    for attempt in range(retries):
        try:
            print(f"Fetching data from API (attempt {attempt + 1}/{retries})...")
            response = requests.get(url, timeout=TIMEOUT)
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            if attempt == retries - 1:
                print("Max retries reached. Failing process.")
                raise e
            
            wait_time = 2 ** (attempt + 1)
            print(f"Fetch failed: {e}. Retrying in {wait_time}s...")
            time.sleep(wait_time)


def load_to_clickhouse(json_data: str) -> None:
    """Load raw payload to ClickHouse and force merge deduplication."""
    client = clickhouse_connect.get_client(
        host=DB_HOST,
        port=DB_PORT,
        username=DB_USER,
        password=DB_PASSWORD
    )

    # Insert raw string into staging table
    client.insert('default.raw_table', [[json_data]], column_names=['raw_data'])
    print("Raw payload inserted into raw_table.")


if __name__ == "__main__":
    try:
        payload = fetch_data(API_URL)
        load_to_clickhouse(payload)
        print("Pipeline execution completed successfully!")
    except Exception as err:
        print(f"Pipeline failed: {err}")