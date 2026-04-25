# 5G Network Quality Web App

A multi-page static web application for monitoring 5G drive-test network quality data. Built with HTML5, CSS3, and vanilla JavaScript — no frontend framework, no build step.

## ⚠️ IMPORTANT: How to Run

**You MUST serve this application through a web server.** Opening HTML files directly (file://) will NOT work because ES modules require HTTP/HTTPS protocol.

### Option 1: Using Python (Recommended)
```bash
# Python 3
python -m http.server 8080

# Then open: http://localhost:8080
```

### Option 2: Using Node.js
```bash
# Install serve globally (one time)
npm install -g serve

# Run the server
serve -p 8080

# Then open: http://localhost:8080
```

### Option 3: Using npx (No installation needed)
```bash
npx serve -p 8080

# Then open: http://localhost:8080
```

### Option 4: Using VS Code Live Server Extension
1. Install "Live Server" extension in VS Code
2. Right-click on `index.html` or `admin.html`
3. Select "Open with Live Server"

## Pages

- **Dashboard** (`index.html`) — Embeds an Amazon QuickSight dashboard for visualizing processed 5G network quality metrics.
- **Admin Panel** (`admin.html`) — Protected page for uploading raw drive-test CSV files to S3 and monitoring both raw and processed dataset listings.

## Project Structure

```
/
├── index.html              # Dashboard page
├── admin.html              # Admin Panel page
├── config.js               # Runtime configuration stub (AWS region, credentials, bucket names)
├── shared/
│   ├── styles.css          # Global styles (navbar, footer, typography, utilities)
│   ├── navbar.js           # Shared navbar module
│   └── footer.js           # Shared footer module
├── admin/
│   ├── admin.css           # Admin Panel styles
│   ├── upload.js           # CSV upload form logic (S3 PutObject)
│   └── s3viewer.js         # S3 dataset viewer (ListObjectsV2)
└── dashboard/
    ├── dashboard.css       # Dashboard page styles
    └── quicksight.js       # QuickSight embed initialization
```

## Configuration

Edit `config.js` and replace the placeholder values with your real AWS resource identifiers:

```js
window.APP_CONFIG = {
  region: 'us-east-1',
  credentials: {
    accessKeyId: 'YOUR_ACCESS_KEY_ID',
    secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  },
  rawBucket: 'your-raw-bucket-name',
  processedBucket: 'your-processed-bucket-name',
  quicksightEmbedUrl: 'https://your-quicksight-embed-url',
};
```

## Running Locally

No build step required. Serve the project root with any static file server, for example:

```bash
npx serve .
# or
python -m http.server 8080
```

Then open `http://localhost:8080` in your browser.

## External SDKs

Loaded via CDN — no installation needed:

- **AWS SDK v3** (`@aws-sdk/client-s3`) — via [Skypack](https://cdn.skypack.dev/@aws-sdk/client-s3)
- **Amazon QuickSight Embedding SDK** — via [unpkg](https://unpkg.com/amazon-quicksight-embedding-sdk/dist/quicksight-embedding-js-sdk.min.js)

## Tech Stack

- HTML5, CSS3, vanilla JavaScript (ES modules)
- No React, Vue, Angular, or any frontend framework
- AWS SDK v3 for S3 operations
- Amazon QuickSight Embedding SDK for dashboard rendering
