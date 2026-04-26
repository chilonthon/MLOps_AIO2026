# 5G Network Quality Web App

A lightweight, multi-page static web application for monitoring 5G drive-test network quality data. Built with vanilla HTML5, CSS3, and JavaScript (ES modules)—no frontend framework required, no build step.

Includes a public Dashboard page for QuickSight data visualisation and a protected Admin Panel for managing raw CSV uploads to AWS S3.

## ⚠️ IMPORTANT: How to Run

**You MUST serve this application through a web server.** Opening HTML files directly via `file://` will not work because ES modules require HTTP/HTTPS protocol.

### Quick Start Options

**Option 1: VS Code Live Server**
1. Install "Live Server" extension in VS Code
2. Right-click on `index.html` or `admin.html`
3. Select "Open with Live Server"

## Pages

- **Dashboard** (`index.html`) — Public page embedding an Amazon QuickSight dashboard for visualizing processed 5G network quality metrics
- **Admin Panel** (`admin.html`) — Protected interface for uploading raw drive-test CSV files to S3 and viewing dataset listings

## Project Structure

```
├── index.html                      # Dashboard page
├── admin.html                      # Admin Panel page
├── package.json                    # Project metadata & test config
├── aws/
│   ├── config.js                   # AWS configuration (region, credentials, bucket names)
│   ├── s3client.js                 # S3 client singleton & command re-exports
│   ├── upload.js                   # CSV upload form & S3 PutObject logic
│   ├── s3viewer.js                 # S3 dataset viewer & ListObjectsV2 logic
│   └── quicksight.js               # QuickSight embed initialization
├── styles/
│   ├── global.css                  # Global styles (navbar, typography, utilities)
│   ├── dashboard.css               # Dashboard page styles
│   └── admin.css                   # Admin Panel styles
└── doc/
    └── MLOps_Pipeline.drawio       # Architecture diagram
```

## Configuration

Before running, configure AWS credentials and resource details:

1. Open [aws/config.js](aws/config.js)
2. Replace all placeholder values with your actual AWS identifiers:

```js
window.APP_CONFIG = {
  region: 'us-east-1',                    // Your AWS region
  credentials: {
    accessKeyId: 'YOUR_ACCESS_KEY_ID',
    secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  },
  rawBucket: 'my-raw-bucket',             // S3 bucket for raw CSV files
  processedBucket: 'my-processed-bucket', // S3 bucket for processed data
  quicksightEmbedUrl: 'https://your-quicksight-embed-url', // QuickSight dashboard URL
};
```

## Architecture

- **Frontend**: HTML5, CSS3, vanilla JavaScript (ES modules)
- **AWS Integration**: S3 SDK v3 (AWS SDK for JavaScript) via Skypack CDN
- **Data Visualisation**: Amazon QuickSight Embedding SDK via unpkg CDN
- **No Build Step**: All dependencies loaded via CDN — works out-of-the-box

## Testing

Tests are configured with Vitest:

```bash
npm test
```

## Tech Stack

- Vanilla JavaScript (ES modules) — no frameworks
- HTML5 & CSS3
- AWS SDK v3 (`@aws-sdk/client-s3`)
- Amazon QuickSight Embedding SDK
- Vitest for unit testing
