/**
 * aws/upload.js
 *
 * Manages the Upload_Form: file selection state, button enable/disable,
 * S3 PutObject upload, and feedback rendering.
 *
 * @module aws/upload
 */
import { uploadToS3 } from './s3client.js';

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
 * @param {string} bucketName - Target S3 bucket name
 */
export function initUploadForm(formElement, bucketName) {
  const fileInput  = formElement.querySelector('input[type="file"]');
  const uploadBtn  = formElement.querySelector('button#upload-btn');
  const feedbackEl = formElement.querySelector('#upload-feedback');

  // Debug: Log if elements are found
  console.log('✅ initUploadForm initialized', {
    fileInputFound: !!fileInput,
    uploadBtnFound: !!uploadBtn,
    feedbackElFound: !!feedbackEl,
    bucket: bucketName,
  });

  if (!fileInput || !uploadBtn) {
    console.error('❌ ERROR: Could not find file input or upload button in form');
    return;
  }

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

  fileInput.addEventListener('change', (e) => {
    console.log('📁 File selected');
    state.selectedFile = fileInput.files.length > 0 ? fileInput.files[0] : null;
    console.log('Selected:', state.selectedFile?.name);
    uploadBtn.disabled = !state.selectedFile;

    // Reset feedback when a new file is chosen
    if (state.status !== 'idle') {
      state.status = 'idle';
      state.message = '';
      renderFeedback();
    }
  });

  // ── Event: upload button click ────────────────────────────────────────────

  uploadBtn.addEventListener('click', async (e) => {
    console.log('🚀 Upload button clicked');
    
    if (!state.selectedFile) {
      console.log('⚠️ No file selected');
      return;
    }

    const file = state.selectedFile;
    console.log('📤 Starting upload:', file.name);

    state.status = 'uploading';
    state.message = '';
    setUploading(true);
    renderFeedback();

    try {
      await uploadToS3(bucketName, file.name, file);

      state.status = 'success';
      state.message = `✅ "${file.name}" uploaded successfully to ${bucketName}`;
      console.log('✅ Upload complete!');
    } catch (err) {
      state.status = 'error';
      state.message = `❌ Upload failed: ${err.message || err}`;
      console.error('❌ Upload error:', err);
    } finally {
      setUploading(false);
      renderFeedback();
    }
  });
}
