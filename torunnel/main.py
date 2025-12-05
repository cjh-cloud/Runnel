import libtorrent as lt
import time
import sys
import os
import boto3
import shutil
from botocore.exceptions import NoCredentialsError

# Configuration
# AWS_ACCESS_KEY = 'YOUR_ACCESS_KEY'
# AWS_SECRET_KEY = 'YOUR_SECRET_KEY'
BUCKET_NAME = 'music-app-public-bucket'
S3_FOLDER_PREFIX = 'music/' # Folder inside S3 to put files
TEMP_DOWNLOAD_DIR = './temp_downloads'

def download_torrent(magnet_link):
    """
    Downloads the torrent content to a local temporary directory.
    """
    if not os.path.exists(TEMP_DOWNLOAD_DIR):
        os.makedirs(TEMP_DOWNLOAD_DIR)

    ses = lt.session()
    ses.listen_on(6881, 6891)

    print("Metadata downloading...")
    params = {
        'save_path': TEMP_DOWNLOAD_DIR,
        'storage_mode': lt.storage_mode_t(2),
    }
    handle = lt.add_magnet_uri(ses, magnet_link, params)
    
    # Wait for metadata to be retrieved so we know the name
    while not handle.has_metadata():
        time.sleep(1)
    
    torrent_name = handle.status().name
    print(f"Metadata retrieved: {torrent_name}")
    print(f"Starting download to: {TEMP_DOWNLOAD_DIR}/{torrent_name}")

    while handle.status().state != lt.torrent_status.seeding:
        s = handle.status()
        state_str = ['queued', 'checking', 'downloading metadata', \
                     'downloading', 'finished', 'seeding', 'allocating']
        
        sys.stdout.write(f'\r{s.progress * 100:.2f}% complete (down: {s.download_rate / 1000:.1f} kB/s up: {s.upload_rate / 1000:.1f} kB/s peers: {s.num_peers}) {state_str[s.state]}')
        sys.stdout.flush()
        time.sleep(1)

    print(f"\nDownload of '{torrent_name}' complete.")
    return torrent_name

def upload_to_s3(torrent_name, local_path, music_path, bucket, s3_prefix):
    """
    Uploads a file or a directory of files to S3.
    """
    # s3 = boto3.client('s3', aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    s3 = boto3.client('s3')

    print("\nStarting upload to S3...")

    # Check if it's a single file or a directory
    if os.path.isfile(local_path):
        files_to_upload = [local_path]
        root_path = os.path.dirname(local_path)
    else:
        files_to_upload = []
        root_path = local_path
        for root, dirs, files in os.walk(local_path):
            for file in files:
                files_to_upload.append(os.path.join(root, file))

    for file_path in files_to_upload:

        # TODO : 
        # Calculate S3 Key (path)
        relative_path = os.path.relpath(file_path, TEMP_DOWNLOAD_DIR).replace(torrent_name, music_path)
        s3_key = os.path.join(s3_prefix, relative_path).replace("\\", "/") # Ensure forward slashes for S3

        print(f"Uploading {file_path} to s3://{bucket}/{s3_key}")
        
        try:
            s3.upload_file(file_path, bucket, s3_key)
        except FileNotFoundError:
            print("The file was not found")
        except NoCredentialsError:
            print("Credentials not available")

    print("Upload complete.")

def cleanup():
    """
    Removes the temporary download directory.
    """
    print("Cleaning up local files...")
    if os.path.exists(TEMP_DOWNLOAD_DIR):
        shutil.rmtree(TEMP_DOWNLOAD_DIR)
    print("Cleanup complete.")

if __name__ == "__main__":
    # Example Magnet Link (This is for an Ubuntu ISO - legitimate use case)
    magnet = input("Enter Magnet Link: ")
    music_path = input("Enter Music Path (e.g., Twenty One Pilots/Clancy): ")
    
    try:
        downloaded_torrent = download_torrent(magnet)
        downloaded_path = os.path.join(TEMP_DOWNLOAD_DIR, downloaded_torrent)
        upload_to_s3(downloaded_torrent, downloaded_path, music_path, BUCKET_NAME, S3_FOLDER_PREFIX)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cleanup()
