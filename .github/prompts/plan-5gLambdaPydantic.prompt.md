# Plan: Lambda + Pydantic 5G Data Processing Architecture

## TL;DR
Build a serverless data pipeline: CSV files uploaded to S3 (raw-bucket) trigger a Lambda function that validates data with Pydantic models, transforms it, and writes processed results to S3 (processed-bucket) for QuickSight visualization. No infrastructure changes to existing web app required—Lambda runs independently and uses the same S3 buckets configured in `config.js`.

## Steps

### Phase 1: Pydantic Models & Data Schema (Foundation)
1. **Analyze CSV structure** — Extract columns from sample files (time, latitude, longitude, speed, truck, svr1-4, Bitrate, etc.)
2. **Create Pydantic models** (`lambda/models.py`) — Define:
   - `Metric5G` model with validated fields (timestamps, GPS coords, signal strengths, bitrates, retransmissions)
   - Optional/nullable field handling (many columns in CSV are empty)
   - Custom validators for data quality (e.g., valid lat/lon ranges, speed bounds)
   - `DrivePath` model aggregating metrics by truck and date
3. **Unit tests** — Test Pydantic models with valid/invalid data using pytest

### Phase 2: Lambda Function Development
4. **Create Lambda handler** (`lambda/handler.py`) — Main entry point that:
   - Receives S3 event (bucket, key) when CSV uploaded
   - Reads CSV from raw-bucket using boto3
   - Parses CSV with pandas
   - Validates each row with Pydantic models (catches schema violations, missing required fields)
   - Transforms to enriched format (JSON with aggregated metrics per truck/date)
   - Writes to processed-bucket with structured naming (`processed/{date}/{truck}-processed.json`)
   - Logs metrics (rows processed, validation errors, execution time)
5. **Error handling** — Implement graceful failure:
   - Invalid rows logged to CloudWatch, not halting entire job
   - Dead-letter mechanism (move unparseable files to error bucket)
   - Retry logic for transient S3 failures

### Phase 3: Lambda Layer & Dependencies
6. **Create Lambda layer** (`lambda/layer/`) with:
   - `requirements.txt`: pydantic, boto3, pandas, pyarrow (for Parquet if using it)
   - Package structure: `python/lib/python3.11/site-packages/`
7. **Build & package** — Create ZIP file compatible with Lambda Python 3.11 runtime
8. **Test locally** — Validate layer can be imported and Pydantic models work

### Phase 4: AWS Infrastructure Setup
9. **S3 Event Notification** — Configure raw-bucket to emit S3:ObjectCreated events to Lambda
10. **Lambda Configuration** — Set up:
    - Runtime: Python 3.11
    - Memory: 512 MB (adjustable based on CSV size)
    - Timeout: 60-300 sec (depends on CSV volume)
    - IAM role with permissions:
      - `s3:GetObject` on raw-bucket
      - `s3:PutObject` on processed-bucket
      - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (CloudWatch)
11. **Attach layer** — Link Lambda layer to function

### Phase 5: Testing & Validation
12. **Unit tests** — Pydantic model validation, edge cases (empty fields, invalid data types)
13. **Integration test** — Upload sample CSV to raw-bucket, verify processed file appears in processed-bucket
14. **Error scenarios** — Test with malformed CSV, missing columns, invalid coordinates
15. **Performance test** — Measure execution time on 170 CSV files (batch or trigger per file)

### Phase 6: Deployment & Monitoring
16. **Package Lambda function** — Create deployment ZIP with handler + models
17. **Deploy to AWS** — Upload via AWS CLI or SAM
18. **CloudWatch monitoring** — Set up alarms for:
    - Lambda execution errors
    - High invocation count (unexpected file uploads)
    - Duration trending
19. **Update web app docs** — Add note to README on Lambda processing pipeline

### Phase 7: Integration with Web App
20. **Connect to existing flow** — Admin Panel uploads CSVs → Lambda processes automatically → QuickSight consumes processed data
21. **Optional: Add status endpoint** — Create API endpoint to query Lambda processing status/logs (future enhancement)

## Relevant Files

- `d:\OneDrive - Swinburne University\AIO2024 Log\STA for MLOps\MLOps_AIO2026\data\` — Sample CSVs with 5G drive-test metrics (170+ files)
- `aws/config.js` — Already configured with `rawBucket` and `processedBucket` endpoints
- `package.json` — Existing project metadata; Lambda will use separate Python runtime
- `admin.html` — CSV upload interface (remains unchanged; triggers Lambda via S3 events)

**New files to create:**
- `lambda/models.py` — Pydantic schemas for 5G metrics
- `lambda/handler.py` — Lambda function entry point
- `lambda/requirements.txt` — Python dependencies (pydantic, boto3, pandas)
- `lambda/tests/test_models.py` — Unit tests for Pydantic models
- `lambda/tests/test_handler.py` — Integration tests for Lambda
- `lambda/layer/` — Packaged Lambda layer (ZIP)
- `lambda/deploy.sh` — Shell script to build and deploy to AWS

## Verification

1. **Model Validation** — Run `python -m pytest lambda/tests/test_models.py` locally; all Pydantic validators pass
2. **CSV Parsing** — Upload sample CSV to raw-bucket; Lambda executes without errors
3. **Output Format** — Verify processed JSON/Parquet in processed-bucket has correct schema
4. **Error Handling** — Upload malformed CSV; confirm it's handled gracefully and logged
5. **Performance** — Measure Lambda execution time on all 170 CSVs (sequential or batch); < 5 min acceptable
6. **QuickSight Integration** — Confirm processed data can be queried by QuickSight (Redshift or S3 as source)

## Decisions

- **Processing trigger**: S3 events (automatic when CSV uploaded), not SQS (simpler setup for assignment)
- **Output format**: JSON with nested structure (one file per truck per date) for easier QuickSight ingestion
- **Error strategy**: Log invalid rows to CloudWatch, don't fail entire Lambda execution (fault tolerance)
- **Lambda timeout**: Start at 300 sec; optimize if needed based on actual execution time
- **Testing framework**: Use pytest for Lambda tests (separate from Vitest used in web app)
- **Scope**: Lambda + Pydantic only; no Redshift or QuickSight deploy in this phase (assumed to exist)

## Further Considerations

1. **Batch Processing vs. Real-time** — Currently set up for per-file triggers. If you need to batch 170 files at once, consider EventBridge rule to trigger daily batch job instead.
2. **Pydantic V2 compatibility** — Confirm you want Pydantic v2 (latest) or v1 (legacy). Recommendation: v2 for modern async support.
3. **Parquet vs. JSON** — Should processed output be Parquet (columnar, better for large queries) or JSON (simpler to debug)? Recommend Parquet for QuickSight performance.