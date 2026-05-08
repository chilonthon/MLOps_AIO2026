import boto3
import os

s3_client = boto3.client('s3')

def download_file_from_s3(bucket: str, key: str, download_path: str):
    """Downloads a file from S3 to the local Lambda /tmp directory"""
    print(f"Downloading s3://{bucket}/{key} to {download_path}")
    s3_client.download_file(bucket, key, download_path)

def upload_file_to_s3(local_path: str, bucket: str, key: str):
    """Uploads the processed file back to S3"""
    print(f"Uploading {local_path} to s3://{bucket}/{key}")
    s3_client.upload_file(local_path, bucket, key)