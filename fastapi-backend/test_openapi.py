import requests

try:
    response = requests.get("http://localhost:8000/openapi.json")
    print(f"Status: {response.status_code}")
    if response.status_code != 200:
        print(f"Error: {response.text}")
except Exception as e:
    print(f"Exception: {e}")
