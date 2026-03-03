// Feedback Bubble Widget
// A subtle, minimal feedback widget for the bottom-right corner
// Note: screenshot_annotator.js exposes window.screenshotAnnotator

let bubbleInitialized = false;
let isFormOpen = false;
let screenshotAttachment = null; // Stores captured screenshot

function shouldShowBubble() {
  const config = window.llamapressConfig || {};
  return config.feedbackBubbleEnabled && config.userLoggedIn;
}

function getCSRFToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : '';
}

function createBubbleHTML() {
  return `
    <div id="llamapress-feedback-bubble" class="fixed bottom-5 right-5 z-50">
      <!-- Trigger Button -->
      <button id="feedback-trigger"
              class="w-9 h-9 rounded-full bg-gray-400 opacity-50 hover:opacity-100 hover:bg-purple-600 hover:scale-110
                     transition-all duration-200 shadow-lg flex items-center justify-center text-white"
              title="Send feedback">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </button>

      <!-- Form Container (hidden by default) -->
      <div id="feedback-form-container"
           class="hidden absolute bottom-12 right-0 w-72 bg-white rounded-lg shadow-xl border border-gray-200 overflow-hidden">
        <!-- Header -->
        <div class="flex items-center justify-between px-3 py-2 bg-gray-50 border-b border-gray-200">
          <span class="text-sm font-medium text-gray-700">Send Feedback</span>
          <button id="feedback-close" class="text-gray-400 hover:text-gray-600 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Form -->
        <form id="feedback-form" class="p-3">
          <textarea id="feedback-text"
                    class="w-full h-20 border border-gray-300 rounded p-2 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                    placeholder="Share your feedback..."></textarea>

          <!-- Screenshot preview (hidden by default) -->
          <div id="feedback-screenshot-preview" class="hidden mb-2 relative">
            <img id="feedback-screenshot-img" class="w-full rounded border border-gray-200" />
            <button type="button" id="feedback-screenshot-remove"
                    class="absolute top-1 right-1 w-5 h-5 bg-red-500 text-white rounded-full text-xs flex items-center justify-center hover:bg-red-600">
              &times;
            </button>
          </div>

          <div class="flex items-center justify-between mt-2">
            <div class="flex items-center gap-2">
              <!-- Screenshot button -->
              <button type="button" id="feedback-screenshot-btn" title="Take screenshot"
                      class="text-gray-400 hover:text-gray-600 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>

              <!-- File attachment -->
              <label class="cursor-pointer text-gray-400 hover:text-gray-600 transition-colors flex items-center gap-1">
                <input type="file" id="feedback-file" class="hidden" accept="image/*,video/*,.pdf,.doc,.docx,.txt,.webm,.mp4,.mov,.avi,.mkv,.webp,.png,.jpg,.jpeg,.gif,.svg" />
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                </svg>
                <span id="feedback-filename" class="text-xs truncate max-w-20"></span>
              </label>
            </div>

            <!-- Submit -->
            <button type="submit"
                    class="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white text-sm rounded transition-colors">
              Send
            </button>
          </div>

          <!-- Status message -->
          <div id="feedback-status" class="hidden mt-2 text-xs"></div>
        </form>

        <!-- View all link -->
        <div class="px-3 py-2 bg-gray-50 border-t border-gray-200">
          <a href="/llama_bot/feedback" class="text-xs text-purple-600 hover:text-purple-800 hover:underline">
            View all feedback
          </a>
        </div>
      </div>
    </div>
  `;
}

function showStatus(message, isError = false) {
  const status = document.getElementById('feedback-status');
  if (status) {
    status.textContent = message;
    status.className = `mt-2 text-xs ${isError ? 'text-red-600' : 'text-green-600'}`;
    status.classList.remove('hidden');
  }
}

function hideStatus() {
  const status = document.getElementById('feedback-status');
  if (status) {
    status.classList.add('hidden');
  }
}

function toggleForm(show) {
  const container = document.getElementById('feedback-form-container');
  const trigger = document.getElementById('feedback-trigger');

  if (container && trigger) {
    if (show) {
      container.classList.remove('hidden');
      trigger.classList.add('bg-purple-600', 'opacity-100');
      trigger.classList.remove('bg-gray-400', 'opacity-50');
      document.getElementById('feedback-text')?.focus();
    } else {
      container.classList.add('hidden');
      trigger.classList.remove('bg-purple-600', 'opacity-100');
      trigger.classList.add('bg-gray-400', 'opacity-50');
    }
    isFormOpen = show;
  }
}

function resetForm() {
  const form = document.getElementById('feedback-form');
  const filename = document.getElementById('feedback-filename');
  const screenshotPreview = document.getElementById('feedback-screenshot-preview');

  if (form) form.reset();
  if (filename) filename.textContent = '';
  if (screenshotPreview) screenshotPreview.classList.add('hidden');

  screenshotAttachment = null;
  hideStatus();
}

async function submitFeedback(description, file, screenshot) {
  // Append page context to description so we know where the feedback came from
  const requestPath = window.request_path || '/';
  const viewPath = window.view_path || '';
  const pageContext = `\n\n---\nPage: ${requestPath}\nView: ${viewPath}`;
  const fullDescription = description + pageContext;

  const formData = new FormData();
  formData.append('user_feedback[title]', 'Quick Feedback');
  formData.append('user_feedback[description]', fullDescription);
  formData.append('user_feedback[feedback_type]', 'general');

  if (file) {
    formData.append('user_feedback[attachments][]', file);
  }

  if (screenshot && screenshot.blob) {
    const screenshotFile = new File([screenshot.blob], screenshot.filename, { type: 'image/png' });
    formData.append('user_feedback[attachments][]', screenshotFile);
  }

  const response = await fetch('/llama_bot/feedback', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': getCSRFToken(),
      'Accept': 'text/html'
    },
    body: formData,
    redirect: 'manual'
  });

  // With redirect: 'manual', a redirect returns type 'opaqueredirect' with status 0
  // This is expected and means the feedback was created successfully
  if (response.type === 'opaqueredirect' || response.ok || (response.status >= 200 && response.status < 400)) {
    return { success: true };
  }

  throw new Error('Failed to submit feedback');
}

function attachEventListeners() {
  const trigger = document.getElementById('feedback-trigger');
  const closeBtn = document.getElementById('feedback-close');
  const form = document.getElementById('feedback-form');
  const fileInput = document.getElementById('feedback-file');
  const filenameDisplay = document.getElementById('feedback-filename');

  if (trigger) {
    trigger.addEventListener('click', () => toggleForm(!isFormOpen));
  }

  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      toggleForm(false);
      resetForm();
    });
  }

  if (fileInput && filenameDisplay) {
    fileInput.addEventListener('change', (e) => {
      const file = e.target.files?.[0];
      filenameDisplay.textContent = file ? file.name : '';
    });
  }

  // Screenshot button
  const screenshotBtn = document.getElementById('feedback-screenshot-btn');
  if (screenshotBtn) {
    screenshotBtn.addEventListener('click', () => {
      toggleForm(false); // Close form while taking screenshot

      window.screenshotAnnotator?.startCapture((attachment) => {
        screenshotAttachment = attachment;

        // Show preview
        const preview = document.getElementById('feedback-screenshot-preview');
        const img = document.getElementById('feedback-screenshot-img');
        if (preview && img && attachment.dataUrl) {
          img.src = attachment.dataUrl;
          preview.classList.remove('hidden');
        }

        // Reopen form
        toggleForm(true);
      });
    });
  }

  // Remove screenshot button
  const removeScreenshotBtn = document.getElementById('feedback-screenshot-remove');
  if (removeScreenshotBtn) {
    removeScreenshotBtn.addEventListener('click', () => {
      screenshotAttachment = null;
      const preview = document.getElementById('feedback-screenshot-preview');
      if (preview) preview.classList.add('hidden');
    });
  }

  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();

      const textarea = document.getElementById('feedback-text');
      const fileInput = document.getElementById('feedback-file');
      const description = textarea?.value?.trim();
      const file = fileInput?.files?.[0];

      if (!description) {
        showStatus('Please enter some feedback', true);
        return;
      }

      const submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = 'Sending...';
      }

      try {
        await submitFeedback(description, file, screenshotAttachment);
        showStatus('Thanks for your feedback!');

        setTimeout(() => {
          toggleForm(false);
          resetForm();
          if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Send';
          }
        }, 1500);
      } catch (error) {
        console.error('Feedback submission error:', error);
        showStatus('Failed to send. Please try again.', true);
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Send';
        }
      }
    });
  }

  // Close on click outside
  document.addEventListener('click', (e) => {
    const bubble = document.getElementById('llamapress-feedback-bubble');
    if (isFormOpen && bubble && !bubble.contains(e.target)) {
      toggleForm(false);
    }
  });
}

function initFeedbackBubble() {
  // Skip if already initialized or shouldn't show
  if (bubbleInitialized || !shouldShowBubble()) return;

  // Check if bubble already exists (from previous Turbo navigation)
  if (document.getElementById('llamapress-feedback-bubble')) return;

  // Inject the bubble
  const wrapper = document.createElement('div');
  wrapper.innerHTML = createBubbleHTML();
  document.body.appendChild(wrapper.firstElementChild);

  attachEventListeners();
  bubbleInitialized = true;
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initFeedbackBubble);

// Handle Turbo navigation
document.addEventListener('turbo:load', () => {
  // Re-check config on each Turbo navigation
  if (shouldShowBubble() && !document.getElementById('llamapress-feedback-bubble')) {
    bubbleInitialized = false;
    initFeedbackBubble();
  }
});
