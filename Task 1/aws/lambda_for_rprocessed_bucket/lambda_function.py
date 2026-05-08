import json
import boto3
import time
import os
import urllib.request
import urllib.error

# Initialize AWS clients
redshift_data = boto3.client('redshift-data')

def lambda_handler(event, context):
    # 1. Extract the bucket and filename that triggered the tripwire
    record = event['Records'][0]
    bucket_name = record['s3']['bucket']['name'] 
    file_key = record['s3']['object']['key']
    
    s3_path = f"s3://{bucket_name}/{file_key}"
    print(f"New file detected: {s3_path}")
    
    # 2. Execute the COPY Command in Redshift Serverless
    redshift_workgroup = os.environ['REDSHIFT_WORKGROUP']
    redshift_database = os.environ['REDSHIFT_DB']
    iam_role_arn = os.environ['REDSHIFT_IAM_ROLE'] 
    
    # Using your actual table name!
    copy_query = f"""
        COPY raw_network_data 
        FROM '{s3_path}' 
        IAM_ROLE '{iam_role_arn}' 
        FORMAT AS JSON 'auto';
    """
    
    response = redshift_data.execute_statement(
        WorkgroupName=redshift_workgroup,
        Database=redshift_database,
        Sql=copy_query
    )
    
    query_id = response['Id']
    print(f"COPY command sent to Redshift. Query ID: {query_id}")
    
    # Wait for the query to finish (MVP approach)
    status = 'SUBMITTED'
    while status in ['SUBMITTED', 'PICKED', 'STARTED']:
        time.sleep(2)
        desc = redshift_data.describe_statement(Id=query_id)
        status = desc['Status']
        
    if status == 'FAILED':
        raise Exception(f"Redshift COPY failed: {desc['Error']}")
        
    print("Redshift COPY successful. Triggering dbt Cloud...")
    
    # 3. Trigger the dbt Cloud API 
    dbt_token = os.environ['DBT_API_TOKEN']
    dbt_account_id = os.environ['DBT_ACCOUNT_ID']
    dbt_job_id = os.environ['DBT_JOB_ID']
    
    # FIX: Updated the URL to perfectly match your specific dbt server!
    # Example: https://ve952.us1.dbt.com/api/v2/accounts/12345/jobs/67890/run/ ==> ve952.us1.dbt.com is the server, 12345 is the account ID, and 67890 is the job ID.
    # You need to see your dbt Cloud job's URL to get these values correct. The pattern is always the same, just replace the placeholders with your actual values.
    dbt_url = f"https://ve952.us1.dbt.com/api/v2/accounts/{dbt_account_id}/jobs/{dbt_job_id}/run/"
    
    headers = {
        # FIX 2: Added the required word "Token " back into the header
        "Authorization": f"Token {dbt_token}",
        "Content-Type": "application/json"
    }
    
    # Package the payload and send the POST request
    data = json.dumps({"cause": f"Triggered by S3 upload: {file_key}"}).encode('utf-8')
    req = urllib.request.Request(dbt_url, data=data, headers=headers, method='POST')
    
    try:
        with urllib.request.urlopen(req) as dbt_response:
            print(f"dbt Cloud job triggered successfully! Status Code: {dbt_response.getcode()}")
    except urllib.error.URLError as e:
        print(f"Error triggering dbt Cloud: {e}")
        raise e
    
    return {
        'statusCode': 200,
        'body': json.dumps('Pipeline execution complete.')
    }