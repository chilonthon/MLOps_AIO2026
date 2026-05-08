# AWS Lambda Data Processing Pipeline - Setup Guide

## Overview
You'll build a pipeline that:
1. **Upload** CSV to S3 (via web UI) ✅ Already done
2. **Trigger** Lambda function automatically (S3 event)
3. **Process** CSV with Pydantic validation
4. **Save** processed data to S3 processed bucket
5. **Monitor** pipeline in CloudWatch

---

## Phase 1: Lambda Function Development (Local)

### 1.1 Project Structure
```
aws/lambda/
├── requirements.txt          # Python dependencies
├── lambda_function.py        # Main handler
├── models/
│   └── data_models.py       # Pydantic models
├── processors/
│   └── csv_processor.py      # CSV processing logic
└── utils/
    └── s3_helper.py         # S3 utilities
```

### 1.2 Dependencies to Install
```bash
pip install pydantic boto3 pandas
```

### 1.3 What to Create

#### A) Pydantic Models (data validation)
- Define **5G data schema** (columns, types, validation rules)
- Example: lat/lon validation, signal strength ranges, timestamp parsing

#### B) Processors
- Read CSV from S3
- Validate each row with Pydantic
- Handle invalid rows (skip/log/quarantine)
- Clean/transform data
- Save to processed bucket

#### C) Lambda Handler
- Entry point for AWS
- Parse S3 event
- Call processor
- Return success/error response

---

## Phase 2: AWS Setup

### 2.1 Create Lambda Function
```bash
aws lambda create-function \
  --function-name 5g-data-processor \
  --runtime python3.11 \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-s3-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda.zip
```

### 2.2 Create IAM Role
- Policy 1: S3 read/write access
- Policy 2: CloudWatch Logs

### 2.3 Create S3 Event Trigger
- S3 bucket: `chilonthon-raw-bucket`
- Event: `s3:ObjectCreated:*`
- Destination: Lambda function
- Filter: `*.csv` only

---

## Phase 3: Deployment

### 3.1 Package Lambda
```bash
cd aws/lambda
pip install -r requirements.txt -t ./package
cp lambda_function.py package/
cd package && zip -r ../lambda.zip . && cd ..
```

### 3.2 Upload to AWS
```bash
aws lambda update-function-code \
  --function-name 5g-data-processor \
  --zip-file fileb://lambda.zip
```

### 3.3 Test
- Upload test CSV to `chilonthon-raw-bucket`
- Monitor CloudWatch logs
- Check `chilonthon-processed-bucket` for output

---

## Phase 4: Monitoring & Debugging

### 4.1 CloudWatch Logs
```bash
aws logs tail /aws/lambda/5g-data-processor --follow
```

### 4.2 Lambda Metrics
- Duration
- Errors
- Invocations

### 4.3 Troubleshooting
- Check IAM permissions
- Verify S3 event notification configuration
- Check function timeout (default 3 sec → increase to 30 sec)
- Test locally with SAM

---

## Quick Start Checklist

- [ ] Create Pydantic models for 5G data schema
- [ ] Write CSV processor logic
- [ ] Write Lambda handler function
- [ ] Test locally with sample CSV
- [ ] Create IAM role in AWS
- [ ] Package Lambda function
- [ ] Deploy to AWS Lambda
- [ ] Configure S3 event triggers
- [ ] Test end-to-end (upload → process → verify output)
- [ ] Monitor CloudWatch logs
- [ ] Set up alerts for failures

---

## File Templates Ready to Generate

1. `lambda_function.py` - Lambda handler
2. `models/data_models.py` - Pydantic schemas
3. `processors/csv_processor.py` - Processing logic
4. `utils/s3_helper.py` - S3 utilities
5. `requirements.txt` - Dependencies
6. `Makefile` - Deployment automation
7. `.env.example` - Configuration template

---

## AWS Resources Needed

1. **Lambda Function** - Code execution
2. **S3 Bucket Policy** - Read raw, write processed
3. **IAM Role** - Permissions (S3, CloudWatch)
4. **CloudWatch** - Logs and monitoring
5. **S3 Event Notification** - Trigger Lambda on upload

---

## Estimated Timeline

- **Step 1-2:** 30 min (create Pydantic models + processor)
- **Step 3:** 15 min (Lambda handler)
- **Step 4:** 10 min (local testing)
- **Step 5-6:** 20 min (AWS setup + deployment)
- **Step 7:** 10 min (end-to-end testing)

**Total: ~1.5 hours**
