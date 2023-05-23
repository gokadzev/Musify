import requests
import json
import time

# Define the repository you want to get the downloads for
repo_owner = "gokadzev"
repo_name = "Musify"

# Define the URL of the Github API endpoint for releases
api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases"

# Define a dictionary to hold the total download counts for each release
download_counts = {}

def handle_rate_limit(response):
    if response.status_code == 403:
        # If we get a rate limit error, we need to wait and try again
        reset_time = int(response.headers["X-RateLimit-Reset"])
        sleep_time = reset_time - time.time()
        print(f"Rate limit exceeded. Waiting {sleep_time} seconds...")
        time.sleep(sleep_time)
        return True
    return False

# Make the initial request to the API endpoint
response = requests.get(api_url)
if handle_rate_limit(response):
    response = requests.get(api_url)  # Retry after rate limit

# Loop through each release and get the download count
while True:
    # Get the download count for each asset in the release
    for release in response.json():
        download_count = sum(asset["download_count"] for asset in release["assets"])
        download_counts[release["tag_name"]] = download_count

    if "next" in response.links:
        # Make the next request to the API endpoint
        response = requests.get(response.links["next"]["url"])
        if handle_rate_limit(response):
            continue  # Retry after rate limit
    else:
        break  # No more pages, exit the loop

total_downloads = sum(download_counts.values())
json_obj = {"downloads_count": total_downloads}

# Write the download counts to a JSON file
with open("downloads_count.json", "w") as f:
    json.dump(json_obj, f)
