/**
 * aws/quicksight.js
 *
 * Initializes the Amazon QuickSight embedded dashboard inside a container element.
 * The amazon-quicksight-embedding-sdk must be loaded via a <script> tag in the HTML
 * before this module is called, exposing window.QuickSightEmbedding.
 *
 * @module aws/quicksight
 */

/**
 * Embeds a QuickSight dashboard into the given container element.
 *
 * Renders a spinner with "Loading Dashboard..." while the SDK initializes,
 * then replaces it with the embedded iframe on success, or a descriptive
 * error message on failure.
 *
 * @param {HTMLElement} containerElement - DOM element to render the dashboard into
 * @param {string} embedUrl - QuickSight embed URL from APP_CONFIG.quicksightEmbedUrl
 * @returns {Promise<void>}
 */
export async function initQuickSightDashboard(containerElement, embedUrl) {
  // 1. Show spinner immediately
  containerElement.innerHTML = `
    <div class="spinner-center">
      <span class="spinner">
        <span class="spinner__ring"></span>
        Loading Dashboard...
      </span>
    </div>`;

  try {
    // 2. Verify the SDK is available (loaded via <script> tag in index.html)
    if (!window.QuickSightEmbedding) {
      throw new Error('QuickSight Embedding SDK not loaded');
    }

    const sdk = window.QuickSightEmbedding;

    // 3. Embed the dashboard — support both legacy and newer SDK API shapes
    if (typeof sdk.createEmbeddingContext === 'function') {
      // Newer SDK (v2+): createEmbeddingContext → embedDashboard
      const embeddingContext = await sdk.createEmbeddingContext();
      await embeddingContext.embedDashboard({
        url: embedUrl,
        container: containerElement,
        scrolling: 'no',
        height: '100%',
        width: '100%',
      });
    } else if (typeof sdk.embedDashboard === 'function') {
      // Legacy SDK (v1): direct embedDashboard call
      sdk.embedDashboard({
        url: embedUrl,
        container: containerElement,
        scrolling: 'no',
        height: '100%',
        width: '100%',
      });
    } else {
      throw new Error('QuickSight Embedding SDK API not recognized');
    }
  } catch (err) {
    // 4. Replace spinner with error message
    containerElement.innerHTML = `
      <div class="message message--error">
        Failed to load QuickSight dashboard:
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
