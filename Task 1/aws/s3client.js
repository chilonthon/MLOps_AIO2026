/**
 * Simple S3 uploader using backend proxy
 * Backend handles AWS credential signing
 */

const PROXY_URL = 'http://localhost:3001';

console.log('✅ S3 client initialized (proxy mode)');
console.log('Backend:', PROXY_URL);

/**
 * Upload a file to S3 via backend proxy
 */
export async function uploadToS3(bucket, key, file) {
  console.log('Uploading via proxy:', key);

  try {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(
      `${PROXY_URL}/api/upload?fileName=${encodeURIComponent(key)}&fileType=${encodeURIComponent(file.type)}`,
      {
        method: 'POST',
        body: file, // Send raw file
      }
    );

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Upload failed: ${response.status} - ${error.error}`);
    }

    const result = await response.json();
    console.log('✅ Upload successful!', result);
    return result;
  } catch (err) {
    console.error('❌ Upload failed:', err);
    throw err;
  }
}

// Dummy exports for compatibility
export const ListObjectsV2Command = null;
export const PutObjectCommand = null;
export const s3Client = null;
