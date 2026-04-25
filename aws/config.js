/**
 * Runtime configuration stub.
 * Replace placeholder values with real AWS resource identifiers before deployment.
 *
 * @type {import('./s3client.js').AppConfig}
 */
window.APP_CONFIG = {
  region: 'us-east-1',
  credentials: {
    accessKeyId: 'YOUR_ACCESS_KEY_ID',
    secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  },
  rawBucket: 'my-raw-bucket',
  processedBucket: 'my-processed-bucket',
  quicksightEmbedUrl: 'https://your-quicksight-embed-url',
};
