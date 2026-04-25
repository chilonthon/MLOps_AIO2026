/**
 * aws/s3viewer.js
 *
 * Fetches and renders File_Entry rows for an S3 bucket column in the S3_Viewer.
 *
 * @module aws/s3viewer
 */
import { ListObjectsV2Command } from './s3client.js';

/**
 * @typedef {Object} FileEntry
 * @property {string} name         - S3 object key (file name)
 * @property {number} sizeBytes    - Object size in bytes
 * @property {Date}   lastModified - Last modified timestamp
 */

/**
 * @typedef {Object} ColumnState
 * @property {'loading'|'loaded'|'empty'|'error'} status
 * @property {FileEntry[]} entries
 * @property {string}      errorMessage
 */

/**
 * Formats a byte count into a human-readable string.
 * - < 1 024 B  → "X B"
 * - < 1 048 576 B → "X.X KB"
 * - else → "X.X MB"
 *
 * @param {number} bytes
 * @returns {string}
 */
function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1048576).toFixed(1)} MB`;
}

/**
 * Formats a Date into a readable locale string.
 *
 * @param {Date} date
 * @returns {string}
 */
function formatDate(date) {
  return `${date.toLocaleDateString()} ${date.toLocaleTimeString()}`;
}

/**
 * Renders a spinner with "Fetching from S3..." into containerElement,
 * then fetches the bucket listing and replaces the spinner with either:
 *  - a table of FileEntry rows (non-empty results)
 *  - the provided emptyMessage (zero objects)
 *  - a descriptive error message (on failure)
 *
 * @param {HTMLElement} containerElement - DOM element to render into
 * @param {import('@aws-sdk/client-s3').S3Client} s3Client - Pre-configured S3Client instance
 * @param {string} bucketName - S3 bucket to list
 * @param {string} emptyMessage - Message to display when the bucket has no objects
 * @returns {Promise<void>}
 */
export async function loadDatasetColumn(containerElement, s3Client, bucketName, emptyMessage) {
  // 1. Show spinner immediately
  containerElement.innerHTML = `
    <div class="spinner-center">
      <span class="spinner">
        <span class="spinner__ring"></span>
        Fetching from S3...
      </span>
    </div>`;

  try {
    const response = await s3Client.send(new ListObjectsV2Command({ Bucket: bucketName }));
    const contents = response.Contents;

    // 2a. Empty bucket
    if (!contents || contents.length === 0) {
      containerElement.innerHTML = `<p>${escapeHtml(emptyMessage)}</p>`;
      return;
    }

    // 2b. Build FileEntry list
    /** @type {FileEntry[]} */
    const entries = contents.map((obj) => ({
      name: obj.Key,
      sizeBytes: obj.Size,
      lastModified: obj.LastModified,
    }));

    // 3. Render table
    const rows = entries
      .map(
        (entry) => `
      <tr>
        <td>${escapeHtml(entry.name)}</td>
        <td>${escapeHtml(formatSize(entry.sizeBytes))}</td>
        <td>${escapeHtml(formatDate(entry.lastModified))}</td>
      </tr>`
      )
      .join('');

    containerElement.innerHTML = `
      <table class="dataset-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Size</th>
            <th>Last Modified</th>
          </tr>
        </thead>
        <tbody>
          ${rows}
        </tbody>
      </table>`;
  } catch (err) {
    // 4. Error state
    containerElement.innerHTML = `
      <div class="message message--error">
        Failed to load datasets from <strong>${escapeHtml(bucketName)}</strong>:
        ${escapeHtml(err.message || String(err))}
      </div>`;
  }
}

/** Minimal HTML-escape to prevent XSS in dynamic content */
function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
