import os
import urllib.parse
from utils.s3_helper import download_file_from_s3, upload_file_to_s3
from processors.csv_processor import process_csv

# Environment variable for your processed bucket
PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET', 'chilonthon-processed-bucket')

def lambda_handler(event, context):
    try:
        # 1. Get the bucket and file key from the S3 event
        record = event['Records'][0]
        source_bucket = record['s3']['bucket']['name']
        
        # Handle spaces or special characters in the filename
        file_key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
        
        # Define local paths in the Lambda /tmp directory
        filename = os.path.basename(file_key)
        download_path = f"/tmp/{filename}"
        
        # FIX: Change the output extension to .json
        json_filename = filename.replace('.csv', '.json')
        output_path = f"/tmp/processed_{json_filename}"
        
        print(f"Triggered by file: {file_key} in bucket: {source_bucket}")
        
        # 2. Download from Raw S3 Bucket
        download_file_from_s3(source_bucket, file_key, download_path)
        
        # 3. Process the CSV (Validate with Pydantic)
        stats = process_csv(download_path, output_path)
        print(f"Processing Complete. Stats: {stats}")
        
        # 4. Upload to Processed S3 Bucket (using the new json name)
        upload_file_to_s3(output_path, PROCESSED_BUCKET, f"{json_filename}")
        
        return {
            'statusCode': 200,
            'body': f"Successfully processed {file_key}. Stats: {stats}"
        }
        
    except Exception as e:
        print(f"Error processing S3 event: {str(e)}")
        raise e