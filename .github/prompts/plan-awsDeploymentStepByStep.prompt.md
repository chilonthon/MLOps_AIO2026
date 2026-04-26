# AWS Deployment Plan: Pydantic + dbt + Lambda Pipeline

Based on your working `self_test/` setup (Pydantic + dbt + DuckDB), here's the step-by-step deployment strategy:

---

## Architecture Flow

```
Admin Panel Upload (index.html)
    ↓ (CSV → S3)
S3 raw-bucket-data
    ↓ (S3:ObjectCreated event)
Lambda: garbo-data-processor
    ├─ Read CSV from S3
    ├─ Validate with Pydantic (GarboDataRecord)
    ├─ Load into DuckDB
    ├─ Run dbt transformation (stg_garbo_cleaned)
    └─ Write JSON to processed-bucket
        ↓
QuickSight Dashboard
```

---

## PHASE 1: Prepare Code for AWS (Local work on your machine)

### Step 1.1 → Extract Python modules from `self_test.ipynb`
- **`lambda/pydantic_models.py`** — Copy the `GarboDataRecord` class & validators
- **`lambda/processor.py`** — CSV parsing + Pydantic validation logic
- **`lambda/dbt_orchestrator.py`** — Load records into DuckDB, run dbt, export results
- **`lambda/handler.py`** — Lambda entry point (receives S3 event)

### Step 1.2 → Copy dbt configuration
- `lambda/dbt_project.yml` (from `self_test/`)
- `lambda/models/stg_garbo_cleaned.sql` (from `self_test/`)
- **`lambda/profiles.yml`** (NEW) — Configure DuckDB for Lambda `/tmp/` storage

### Step 1.3 → Create dependencies
- `lambda/requirements.txt`: pydantic, boto3, pandas, dbt-duckdb, duckdb

### Step 1.4 → Test locally
```bash
python -m pip install -r lambda/requirements.txt
python -c "from lambda.handler import lambda_handler; print('OK')"
```

---

## PHASE 2: AWS Infrastructure Setup

### Step 2.1 → Create S3 Buckets
```bash
aws s3 mb s3://raw-bucket-data --region us-east-1
aws s3 mb s3://processed-bucket-data --region us-east-1
aws s3 mb s3://dbt-artifacts-data --region us-east-1
```

### Step 2.2 → Create IAM Role (`garbo-lambda-role`)
**Permissions needed:**
- S3: `GetObject` on `raw-bucket-data/*`
- S3: `PutObject` on `processed-bucket-data/*` and `dbt-artifacts-data/*`
- CloudWatch: `CreateLogGroup`, `CreateLogStream`, `PutLogEvents`

**IAM Trust Policy** (`aws/lambda-role-trust-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**IAM Inline Policy** (`aws/lambda-role-policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::raw-bucket-data", "arn:aws:s3:::raw-bucket-data/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::processed-bucket-data/*", "arn:aws:s3:::dbt-artifacts-data/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

**Create Role:**
```bash
aws iam create-role \
  --role-name garbo-lambda-role \
  --assume-role-policy-document file://aws/lambda-role-trust-policy.json

aws iam put-role-policy \
  --role-name garbo-lambda-role \
  --policy-name garbo-lambda-policy \
  --policy-document file://aws/lambda-role-policy.json
```

### Step 2.3 → Create Lambda Layer (bundles dependencies)
```bash
# Create layer directory structure
mkdir -p lambda/layer/python/lib/python3.11/site-packages

# Install dependencies into layer
pip install -r lambda/requirements.txt -t lambda/layer/python/lib/python3.11/site-packages/

# Create ZIP
cd lambda/layer
zip -r ../lambda-layer.zip .
cd ../..

# Publish to AWS
aws lambda publish-layer-version \
  --layer-name garbo-dependencies \
  --zip-file fileb://lambda/lambda-layer.zip \
  --compatible-runtimes python3.11 \
  --region us-east-1
```

**Note**: Get the Layer ARN for Step 3.2
```bash
LAYER_ARN=$(aws lambda list-layer-versions --layer-name garbo-dependencies --query 'LayerVersions[0].LayerVersionArn' --output text)
echo $LAYER_ARN
```

---

## PHASE 3: Deploy Lambda

### Step 3.1 → Package Lambda function
```bash
cd lambda/
zip -r ../garbo-lambda.zip \
  handler.py \
  processor.py \
  pydantic_models.py \
  dbt_orchestrator.py \
  dbt_project.yml \
  models/ \
  profiles.yml \
  -x '*.pyc' '__pycache__/*'
cd ..
```

### Step 3.2 → Deploy to AWS
```bash
# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name garbo-lambda-role --query 'Role.Arn' --output text)

# Get layer ARN
LAYER_ARN=$(aws lambda list-layer-versions --layer-name garbo-dependencies --query 'LayerVersions[0].LayerVersionArn' --output text)

# Create Lambda function
aws lambda create-function \
  --function-name garbo-data-processor \
  --runtime python3.11 \
  --role $ROLE_ARN \
  --handler handler.lambda_handler \
  --zip-file fileb://garbo-lambda.zip \
  --memory-size 1024 \
  --timeout 600 \
  --layers $LAYER_ARN \
  --environment Variables="{RAW_BUCKET=raw-bucket-data,PROCESSED_BUCKET=processed-bucket-data}" \
  --region us-east-1
```

**Configuration Details:**
- **Runtime**: Python 3.11
- **Memory**: 1024 MB (dbt + DuckDB need RAM)
- **Timeout**: 600 sec (10 min for processing)
- **Handler**: `handler.lambda_handler`

### Step 3.3 → Configure S3 → Lambda Trigger

**Step 3.3a:** Grant S3 permission to invoke Lambda
```bash
aws lambda add-permission \
  --function-name garbo-data-processor \
  --statement-id AllowS3Invoke \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::raw-bucket-data \
  --region us-east-1
```

**Step 3.3b:** Set up S3 event notification
```bash
# Get Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name garbo-data-processor --query 'Configuration.FunctionArn' --output text)

# Configure S3 bucket notification
aws s3api put-bucket-notification-configuration \
  --bucket raw-bucket-data \
  --notification-configuration "{
    \"LambdaFunctionConfigurations\": [
      {
        \"LambdaFunctionArn\": \"$LAMBDA_ARN\",
        \"Events\": [\"s3:ObjectCreated:*\"]
      }
    ]
  }" \
  --region us-east-1
```

---

## PHASE 4: End-to-End Testing

### Step 4.1 → Upload test CSV
```bash
aws s3 cp data/2022-07-04-garbo01-combined-kml.csv s3://raw-bucket-data/test.csv
```

**Expected**: Lambda invokes automatically within 5-10 seconds

### Step 4.2 → Monitor CloudWatch logs
```bash
aws logs tail /aws/lambda/garbo-data-processor --follow
```

**Expected output:**
```
Processing s3://raw-bucket-data/test.csv
Validated 1200 records
Running dbt transformation...
Successfully processed test.csv
```

### Step 4.3 → Verify processed output
```bash
# List files in processed bucket
aws s3 ls s3://processed-bucket-data/

# View processed JSON
aws s3 cp s3://processed-bucket-data/test.csv.json - | jq '.' | head -50
```

**Expected**: Valid JSON with transformed 5G metrics

### Step 4.4 → Check for errors
If Lambda fails:
```bash
# Get recent error logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/garbo-data-processor \
  --filter-pattern "ERROR"
```

---

## PHASE 5: Scale to All 170 CSVs

### Step 5.1 → Batch upload all CSVs
```bash
for file in data/*.csv; do
  echo "Uploading $(basename $file)..."
  aws s3 cp "$file" "s3://raw-bucket-data/$(basename $file)"
done
```

**Expected**: 170 Lambda invocations triggered automatically

### Step 5.2 → Monitor execution metrics
```bash
# Get average Lambda duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=garbo-data-processor \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average,Maximum \
  --region us-east-1
```

### Step 5.3 → Count successful invocations
```bash
# Check invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=garbo-data-processor \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Sum \
  --region us-east-1
```

### Step 5.4 → Check error count
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=garbo-data-processor \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Sum \
  --region us-east-1
```

### Step 5.5 → Set up CloudWatch alarms
```bash
# Alert on Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name garbo-lambda-errors \
  --alarm-description "Alert when Lambda errors occur" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --dimensions Name=FunctionName,Value=garbo-data-processor \
  --region us-east-1

# Alert on high duration
aws cloudwatch put-metric-alarm \
  --alarm-name garbo-lambda-duration \
  --alarm-description "Alert when Lambda duration exceeds 120 seconds" \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --threshold 120000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=FunctionName,Value=garbo-data-processor \
  --region us-east-1
```

---

## PHASE 6: Optimization & Troubleshooting

### Performance Optimization
- **Timeout exceeded?** → Increase to 900 sec or add memory to 2048 MB
- **Cold starts slow?** → Enable Lambda Provisioned Concurrency (cost tradeoff)
- **DuckDB file corrupted?** → Use S3 for persistent storage instead of `/tmp/`

### Common Issues & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| `ModuleNotFoundError: No module named 'dbt'` | dbt not in layer | Verify layer ZIP includes `python/lib/python3.11/site-packages/dbt*` |
| Lambda timeout (> 600 sec) | Processing too slow | Increase memory to 2048 MB, optimize SQL queries |
| `Permission denied` S3 | IAM role missing permissions | Add S3 GetObject/PutObject to role policy |
| `DuckDB: database is locked` | Multiple Lambda invocations on same file | Use unique temp files per invocation |
| Pydantic validation fails | CSV encoding issue | Ensure CSV is UTF-8 encoded |

---

## PHASE 7: Continuous Deployment (Optional)

### Create automated deploy script (`aws/deploy.sh`)
```bash
#!/bin/bash
set -e

echo "🔨 Building Lambda package..."
cd lambda/
zip -r ../garbo-lambda.zip \
  handler.py processor.py pydantic_models.py dbt_orchestrator.py \
  dbt_project.yml models/ profiles.yml \
  -x '*.pyc' '__pycache__/*'
cd ..

echo "📤 Uploading to AWS..."
aws lambda update-function-code \
  --function-name garbo-data-processor \
  --zip-file fileb://garbo-lambda.zip \
  --region us-east-1

echo "✅ Deployment complete!"
```

**Usage:**
```bash
chmod +x aws/deploy.sh
./aws/deploy.sh
```

---

## File Structure to Create

```
project-root/
├── lambda/
│   ├── handler.py                    # Lambda entry point
│   ├── processor.py                  # Pydantic + CSV validation
│   ├── pydantic_models.py            # Models from self_test
│   ├── dbt_orchestrator.py           # dbt + DuckDB runner
│   ├── requirements.txt              # Python dependencies
│   ├── dbt_project.yml               # Copy from self_test/
│   ├── profiles.yml                  # DuckDB profile config
│   ├── models/
│   │   └── stg_garbo_cleaned.sql     # Copy from self_test/
│   └── layer/                        # (Generated by build process)
│       └── python/lib/python3.11/site-packages/
│
├── aws/
│   ├── lambda-role-trust-policy.json
│   ├── lambda-role-policy.json
│   └── deploy.sh                     # Automated deployment
│
└── data/                             # Your 170 CSV files
    └── 2022-07-04-garbo01-combined-kml.csv
    ...
```

---

## Deployment Checklist

**PHASE 1: Code Preparation**
- [ ] Extract Pydantic models to `lambda/pydantic_models.py`
- [ ] Extract processor logic to `lambda/processor.py`
- [ ] Create `lambda/dbt_orchestrator.py`
- [ ] Create `lambda/handler.py`
- [ ] Copy dbt config: `lambda/dbt_project.yml`, `lambda/models/`, `lambda/profiles.yml`
- [ ] Create `lambda/requirements.txt`
- [ ] Test locally: `python -c "from lambda.handler import lambda_handler"`

**PHASE 2: AWS Infrastructure**
- [ ] Create 3 S3 buckets (raw, processed, dbt-artifacts)
- [ ] Create IAM role `garbo-lambda-role`
- [ ] Create Lambda layer `garbo-dependencies`

**PHASE 3: Deploy Lambda**
- [ ] Package Lambda ZIP
- [ ] Deploy function `garbo-data-processor`
- [ ] Configure S3 → Lambda trigger

**PHASE 4: Testing**
- [ ] Upload test CSV
- [ ] Check CloudWatch logs
- [ ] Verify processed JSON output

**PHASE 5: Scale**
- [ ] Upload all 170 CSVs
- [ ] Monitor metrics
- [ ] Set CloudWatch alarms

**PHASE 6: Optimize**
- [ ] Review performance metrics
- [ ] Adjust memory/timeout if needed
- [ ] Document results

---

## Quick Reference: AWS CLI Commands

```bash
# View Lambda logs (real-time)
aws logs tail /aws/lambda/garbo-data-processor --follow

# View Lambda function details
aws lambda get-function --function-name garbo-data-processor

# Manually invoke Lambda (for testing)
aws lambda invoke \
  --function-name garbo-data-processor \
  --payload '{"Records":[{"s3":{"bucket":{"name":"raw-bucket-data"},"object":{"key":"test.csv"}}}]}' \
  response.json

# Update Lambda code (after code changes)
aws lambda update-function-code \
  --function-name garbo-data-processor \
  --zip-file fileb://garbo-lambda.zip

# Delete Lambda function
aws lambda delete-function --function-name garbo-data-processor

# Delete S3 bucket
aws s3 rb s3://raw-bucket-data --force

# Delete IAM role
aws iam delete-role-policy --role-name garbo-lambda-role --policy-name garbo-lambda-policy
aws iam delete-role --role-name garbo-lambda-role
```

---

## Estimated Timeline

| Phase | Duration | Effort |
|-------|----------|--------|
| PHASE 1: Code prep | 30-60 min | Extract + test |
| PHASE 2: AWS setup | 15-20 min | Create resources |
| PHASE 3: Deploy | 10-15 min | Package + upload |
| PHASE 4: Test | 10-15 min | Upload + verify |
| PHASE 5: Scale | 20-30 min | Batch upload + monitor |
| **Total** | **~2-3 hours** | **Mostly waiting** |

---

## Next Steps

1. **Start PHASE 1** — Extract Python modules from `self_test.ipynb`
2. **Run local tests** — Verify `lambda_handler` works
3. **Follow PHASE 2** — Create AWS infrastructure
4. **Deploy PHASE 3** — Upload Lambda
5. **Test PHASE 4** — Single CSV
6. **Scale PHASE 5** — All 170 CSVs
