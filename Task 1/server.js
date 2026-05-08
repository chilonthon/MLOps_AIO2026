/**
 * Simple Node.js proxy server for S3 uploads
 * Handles AWS credential signing so browsers don't need to
 */
import express from 'express';
import cors from 'cors';
import AWS from 'aws-sdk';

// Import config
const config = {
  region: 'us-east-1',
  accessKeyId: 'add your access key',
  secretAccessKey: 'add your secret key',
  rawBucket: 'chilonthon-raw-bucket',
};

const app = express();
app.use(cors());
app.use(express.static('.'));

// Configure AWS
const s3 = new AWS.S3({
  region: config.region,
  accessKeyId: config.accessKeyId,
  secretAccessKey: config.secretAccessKey,
});

/**
 * POST /api/upload-url
 * Generate a pre-signed URL for browser upload
 */
app.post('/api/upload-url', express.json(), (req, res) => {
  const { fileName, fileType } = req.body;

  if (!fileName) {
    return res.status(400).json({ error: 'fileName required' });
  }

  const params = {
    Bucket: config.rawBucket,
    Key: fileName,
    ContentType: fileType || 'application/octet-stream',
    Expires: 3600, // URL valid for 1 hour
  };

  try {
    const uploadURL = s3.getSignedUrl('putObject', params);
    console.log('✅ Pre-signed URL generated for:', fileName);
    res.json({ uploadURL, bucket: config.rawBucket });
  } catch (err) {
    console.error('❌ Error generating URL:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/upload
 * Direct proxy upload
 */
app.post('/api/upload', express.raw({ type: '*/*', limit: '100mb' }), (req, res) => {
  const { fileName, fileType } = req.query;

  if (!fileName) {
    return res.status(400).json({ error: 'fileName query param required' });
  }

  const params = {
    Bucket: config.rawBucket,
    Key: fileName,
    Body: req.body,
    ContentType: fileType || 'application/octet-stream',
  };

  s3.putObject(params, (err, data) => {
    if (err) {
      console.error('❌ Upload failed:', err);
      return res.status(500).json({ error: err.message });
    }
    console.log('✅ File uploaded:', fileName);
    res.json({ success: true, fileName, bucket: config.rawBucket });
  });
});

/**
 * GET /api/list/:bucket
 * List all files in an S3 bucket
 */
app.get('/api/list/:bucket', (req, res) => {
  const { bucket } = req.params;

  if (bucket !== config.rawBucket && bucket !== 'chilonthon-processed-bucket') {
    return res.status(403).json({ error: 'Bucket not allowed' });
  }

  const params = { Bucket: bucket };

  s3.listObjectsV2(params, (err, data) => {
    if (err) {
      console.error('❌ List failed:', err);
      return res.status(500).json({ error: err.message });
    }

    const files = (data.Contents || []).map(obj => ({
      name: obj.Key,
      sizeBytes: obj.Size,
      lastModified: obj.LastModified,
    }));

    console.log(`✅ Listed ${files.length} files from ${bucket}`);
    res.json({ files, bucket });
  });
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`\n🚀 Server running on http://localhost:${PORT}`);
  console.log(`📤 Upload endpoint: POST http://localhost:${PORT}/api/upload`);
  console.log(`📋 URL generator: POST http://localhost:${PORT}/api/upload-url\n`);
});
