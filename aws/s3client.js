/**
 * Shared AWS S3 client module.
 *
 * Instantiates a singleton S3Client using runtime config from window.APP_CONFIG
 * and re-exports the command constructors needed by upload.js and s3viewer.js.
 *
 * No build step — AWS SDK v3 is loaded via Skypack CDN ESM.
 */
import {
  S3Client,
  ListObjectsV2Command,
  PutObjectCommand,
} from 'https://cdn.skypack.dev/@aws-sdk/client-s3';

const { region, credentials } = window.APP_CONFIG;

export const s3Client = new S3Client({ region, credentials });

export { ListObjectsV2Command, PutObjectCommand };
