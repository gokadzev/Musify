import requests
import json
import time

# Define the repository you want to get the downloads for
repo_owner = "gokadzev"
repo_name = "Musify"

# Define the URL of the GitHub API endpoint for releases
api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases"

# Define a dictionary to hold the total download counts for each release
download_counts = {}

def handle_rate_limit(response):
    if response.status_code == 403:
        # If we get a rate limit error, we need to wait and try again
        reset_time = int(response.headers["X-RateLimit-Reset"])
        remaining_limit = int(response.headers["X-RateLimit-Remaining"])
        if remaining_limit == 0:
            sleep_time = reset_time - time.time()
            print(f"Rate limit exceeded. Waiting {sleep_time} seconds...")
            time.sleep(sleep_time)
            return True
    return False

def make_request(url):
    response = requests.get(url)
    while handle_rate_limit(response):
        response = requests.get(url)  # Retry after rate limit
    return response

try:
    response = make_request(api_url)
    response.raise_for_status()  # Raise an exception for any HTTP errors
    releases = response.json()
except requests.exceptions.HTTPError as e:
    print(f"Error occurred while retrieving releases: {e}")
    exit(1)
except json.JSONDecodeError as e:
    print(f"Error occurred while parsing response JSON: {e}")
    exit(1)

# Function to get the download count for a release
def get_download_count(release):
    return sum(asset["download_count"] for asset in release["assets"])

# Loop through each release and get the download count
for release in releases:
    download_counts[release["tag_name"]] = get_download_count(release)

if "next" in response.links:
    # Make additional requests to retrieve all releases
    while "next" in response.links:
        next_url = response.links["next"]["url"]
        response = make_request(next_url)
        try:
            response.raise_for_status()
            releases = response.json()
        except requests.exceptions.HTTPError as e:
            print(f"Error occurred while retrieving releases: {e}")
            exit(1)
        except json.JSONDecodeError as e:
            print(f"Error occurred while parsing response JSON: {e}")
            exit(1)

        for release in releases:
            download_counts[release["tag_name"]] = get_download_count(release)

# Calculate the total download count
total_downloads = sum(download_counts.values())
json_obj = {"downloads_count": total_downloads}

# Write the download counts to a JSON file
with open("downloads_count.json", "w") as f:
    json.dump(json_obj, f)
