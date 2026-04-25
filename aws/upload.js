/**
 * aws/upload.js
 *
 * Manages the Upload_Form: file selection state, button enable/disable,
 * S3 PutObject upload, and feedback rendering.
 *
 * @module aws/upload
 */
import { PutObjectCommand } from './s3client.js';

/**
 * @typedef {Object} UploadState
 * @property {File|null}  selectedFile  - Currently selected file, or null
 * @property {'idle'|'uploading'|'success'|'error'} status
 * @property {string}     message       - Feedback message to display
 */

/**
 * Initialises the upload form, wiring up file-selection and upload events.
 *
 * @param {HTMLFormElement} formElement - The <form> element containing the upload controls
 * @param {import('@aws-sdk/client-s3').S3Client} s3Client - Pre-configured S3Client instance
 * @param {string} bucketName - Target S3 bucket name
 */
export function initUploadForm(formElement, s3Client, bucketName) {
  const fileInput  = formElement.querySelector('input[type="file"]');
  const uploadBtn  = formElement.querySelector('button#upload-btn');
  const feedbackEl = formElement.querySelector('#upload-feedback');

  /** @type {UploadState} */
  const state = {
    selectedFile: null,
    status: 'idle',
    message: '',
  };

  // ── Helpers ──────────────────────────────────────────────────────────────

  function renderFeedback() {
    if (state.status === 'uploading') {
      feedbackEl.innerHTML = `
        <div class="spinner-center">
          <span class="spinner">
            <span class="spinner__ring"></span>
            Uploading…
          </span>
        </div>`;
      return;
    }

    if (state.status === 'success') {
      feedbackEl.innerHTML = `
        <div class="message message--success">${escapeHtml(state.message)}</div>`;
      return;
    }

    if (state.status === 'error') {
      feedbackEl.innerHTML = `
        <div class="message message--error">${escapeHtml(state.message)}</div>`;
      return;
    }

    // idle — clear feedback
    feedbackEl.innerHTML = '';
  }

  function setUploading(isUploading) {
    if (isUploading) {
      uploadBtn.classList.add('btn--loading');
      uploadBtn.disabled = true;
    } else {
      uploadBtn.classList.remove('btn--loading');
      // Re-enable only if a file is still selected
      uploadBtn.disabled = !state.selectedFile;
    }
  }

  /** Minimal HTML-escape to prevent XSS in error messages */
  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  // ── Event: file input change ──────────────────────────────────────────────

  fileInput.addEventListener('change', () => {
    state.selectedFile = fileInput.files.length > 0 ? fileInput.files[0] : null;
    uploadBtn.disabled = !state.selectedFile;

    // Reset feedback when a new file is chosen
    if (state.status !== 'idle') {
      state.status = 'idle';
      state.message = '';
      renderFeedback();
    }
  });

  // ── Event: upload button click ────────────────────────────────────────────

  uploadBtn.addEventListener('click', async () => {
    if (!state.selectedFile) return;

    const file = state.selectedFile;

    state.status = 'uploading';
    state.message = '';
    setUploading(true);
    renderFeedback();

    try {
      await s3Client.send(
        new PutObjectCommand({
          Bucket: bucketName,
          Key: file.name,
          Body: file,
          ContentType: file.type,
        })
      );

      state.status = 'success';
      state.message = `"${file.name}" uploaded successfully to ${bucketName}.`;
    } catch (err) {
      state.status = 'error';
      state.message = `Upload failed: ${err.message || err}`;
    } finally {
      setUploading(false);
      renderFeedback();
    }
  });
}
