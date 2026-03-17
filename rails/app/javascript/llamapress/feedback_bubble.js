// Feedback Bubble Widget with Notifications
// A minimal feedback widget with messaging and notifications support
// Note: screenshot_annotator.js exposes window.screenshotAnnotator

let bubbleInitialized = false;
let isFormOpen = false;
let screenshotAttachment = null;
let notificationSubscription = null;
let unreadCount = 0;
let currentTab = 'feedback';

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
      <!-- Trigger Button with Badge -->
      <button id="feedback-trigger"
              class="relative w-12 h-12 rounded-full bg-gray-400 opacity-60 hover:opacity-100 hover:bg-purple-600 hover:scale-110
                     transition-all duration-200 shadow-lg flex items-center justify-center text-white"
              title="Feedback & Messages">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <!-- Notification Badge -->
        <span id="notification-badge"
              class="hidden absolute -top-1 -right-1 min-w-5 h-5 px-1.5 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center">
          0
        </span>
      </button>

      <!-- Expanded Panel -->
      <div id="feedback-panel"
           class="hidden absolute bottom-16 right-0 w-80 bg-white rounded-xl shadow-2xl border border-gray-200 overflow-hidden">

        <!-- Tab Navigation - Icon only, cleaner -->
        <div class="flex border-b border-gray-200">
          <button id="tab-feedback" class="tab-btn flex-1 py-3 flex justify-center items-center text-purple-600 border-b-2 border-purple-600 bg-white" data-tab="feedback" title="Feedback">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
            </svg>
          </button>
          <button id="tab-messages" class="tab-btn flex-1 py-3 flex justify-center items-center text-gray-400 hover:text-gray-600 border-b-2 border-transparent bg-gray-50 hover:bg-white" data-tab="messages" title="Messages">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </button>
          <button id="tab-notifications" class="tab-btn flex-1 py-3 flex justify-center items-center text-gray-400 hover:text-gray-600 border-b-2 border-transparent bg-gray-50 hover:bg-white relative" data-tab="notifications" title="Notifications">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            <span id="notifications-tab-badge" class="hidden absolute -top-1 right-2 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
        </div>

        <!-- Feedback Tab Content -->
        <div id="content-feedback">
          <form id="feedback-form" class="p-3">
            <textarea id="feedback-text"
                      class="w-full h-20 border border-gray-300 rounded-lg p-2 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                      placeholder="Share your feedback..."></textarea>

            <!-- Screenshot preview -->
            <div id="feedback-screenshot-preview" class="hidden mb-2 relative">
              <img id="feedback-screenshot-img" class="w-full rounded border border-gray-200" />
              <button type="button" id="feedback-screenshot-remove"
                      class="absolute top-1 right-1 w-5 h-5 bg-red-500 text-white rounded-full text-xs flex items-center justify-center hover:bg-red-600">
                &times;
              </button>
            </div>

            <div class="flex items-center justify-between mt-2">
              <div class="flex items-center gap-2">
                <button type="button" id="feedback-screenshot-btn" title="Take screenshot"
                        class="text-gray-400 hover:text-purple-600 transition-colors">
                  <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>
                <label class="cursor-pointer text-gray-400 hover:text-purple-600 transition-colors flex items-center gap-1">
                  <input type="file" id="feedback-file" class="hidden" accept="image/*,video/*,.pdf,.doc,.docx,.txt" />
                  <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                  </svg>
                  <span id="feedback-filename" class="text-xs truncate max-w-16"></span>
                </label>
              </div>
              <button type="submit" class="px-3 py-1.5 bg-purple-600 hover:bg-purple-700 text-white text-sm font-medium rounded-lg transition-colors">
                Send
              </button>
            </div>
            <div id="feedback-status" class="hidden mt-2 text-xs"></div>
          </form>
          <div class="px-3 py-2 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
            <a href="/" class="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1">
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to App
            </a>
            <a href="/llama_bot/feedback" target="_blank" class="text-xs text-purple-600 hover:text-purple-800 hover:underline flex items-center gap-1">
              View all feedback
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>

        <!-- Messages Tab Content -->
        <div id="content-messages" class="hidden">
          <div id="conversations-list" class="max-h-64 overflow-y-auto">
            <div class="py-6 flex justify-center">
              <div class="w-5 h-5 border-2 border-purple-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          </div>
          <div class="px-3 py-2 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
            <a href="/" class="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1">
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to App
            </a>
            <a href="/llama_bot/conversations" target="_blank" class="text-xs text-purple-600 hover:text-purple-800 hover:underline flex items-center gap-1">
              Open messages
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>

        <!-- Notifications Tab Content -->
        <div id="content-notifications" class="hidden">
          <div id="notifications-list" class="max-h-64 overflow-y-auto">
            <div class="py-6 flex justify-center">
              <div class="w-5 h-5 border-2 border-purple-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          </div>
          <div class="px-3 py-2 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
            <a href="/" class="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1">
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to App
            </a>
            <div class="flex items-center gap-3">
              <button id="mark-all-read-btn" class="text-xs text-gray-500 hover:text-purple-600">Mark read</button>
              <a href="/llama_bot/notifications" target="_blank" class="text-xs text-purple-600 hover:text-purple-800 hover:underline flex items-center gap-1">
                View all
                <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
}

// Update notification badge
function updateBadge(count) {
  unreadCount = count;
  const badge = document.getElementById('notification-badge');
  const tabBadge = document.getElementById('notifications-tab-badge');

  // Main badge on trigger button
  if (badge) {
    if (count > 0) {
      badge.textContent = count > 99 ? '99+' : count;
      badge.classList.remove('hidden');
      badge.classList.add('flex');
    } else {
      badge.classList.add('hidden');
      badge.classList.remove('flex');
    }
  }

  // Tab badge (simple dot)
  if (tabBadge) {
    if (count > 0) {
      tabBadge.classList.remove('hidden');
    } else {
      tabBadge.classList.add('hidden');
    }
  }
}

// Switch tabs
function switchTab(tabName) {
  console.log('[FeedbackBubble] Switching to tab:', tabName);
  currentTab = tabName;
  const tabs = ['feedback', 'messages', 'notifications'];

  tabs.forEach(tab => {
    const tabBtn = document.getElementById(`tab-${tab}`);
    const content = document.getElementById(`content-${tab}`);

    if (!tabBtn || !content) {
      console.warn('[FeedbackBubble] Missing element for tab:', tab);
      return;
    }

    if (tab === tabName) {
      // Active tab
      tabBtn.classList.add('text-purple-600', 'border-purple-600', 'bg-white');
      tabBtn.classList.remove('text-gray-400', 'border-transparent', 'bg-gray-50');
      content.classList.remove('hidden');

      // Load data for the tab
      if (tab === 'messages') {
        console.log('[FeedbackBubble] Loading conversations...');
        loadConversations();
      }
      if (tab === 'notifications') {
        console.log('[FeedbackBubble] Loading notifications...');
        loadNotifications();
      }
    } else {
      // Inactive tab
      tabBtn.classList.remove('text-purple-600', 'border-purple-600', 'bg-white');
      tabBtn.classList.add('text-gray-400', 'border-transparent', 'bg-gray-50');
      content.classList.add('hidden');
    }
  });
}

// Load conversations
async function loadConversations() {
  const container = document.getElementById('conversations-list');
  if (!container) {
    console.error('[FeedbackBubble] conversations-list container not found');
    return;
  }

  try {
    const response = await fetch('/llama_bot/conversations.json', {
      headers: { 'Accept': 'application/json' },
      credentials: 'same-origin'
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const conversations = await response.json();
    console.log('[FeedbackBubble] Loaded conversations:', conversations);

    if (!conversations || conversations.length === 0) {
      container.innerHTML = `
        <div class="py-8 px-4 text-center">
          <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-purple-100 flex items-center justify-center">
            <svg class="w-6 h-6 text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
          </div>
          <p class="text-sm font-medium text-gray-700">No messages yet</p>
          <p class="text-xs text-gray-400 mt-1">Start a conversation from the messages page</p>
        </div>`;
      return;
    }

    container.innerHTML = conversations.slice(0, 5).map(conv => `
      <a href="/llama_bot/conversations/${conv.id}" target="_blank"
         class="block px-3 py-2.5 hover:bg-gray-50 border-b border-gray-100 ${conv.unread_count > 0 ? 'bg-purple-50' : ''}">
        <div class="flex items-center justify-between">
          <span class="font-medium text-sm text-gray-800 truncate">${escapeHtml(conv.title)}</span>
          ${conv.unread_count > 0 ? `<span class="px-1.5 py-0.5 bg-purple-600 text-white text-xs rounded-full">${conv.unread_count}</span>` : ''}
        </div>
        ${conv.last_message ? `<p class="text-xs text-gray-500 mt-0.5 truncate">${escapeHtml(conv.last_message.body)}</p>` : ''}
      </a>
    `).join('');
  } catch (error) {
    console.error('[FeedbackBubble] Failed to load conversations:', error);
    container.innerHTML = '<div class="p-4 text-center text-red-500 text-sm">Failed to load</div>';
  }
}

// Load notifications
async function loadNotifications() {
  const container = document.getElementById('notifications-list');
  if (!container) {
    console.error('[FeedbackBubble] notifications-list container not found');
    return;
  }

  try {
    const response = await fetch('/llama_bot/notifications.json', {
      headers: { 'Accept': 'application/json' },
      credentials: 'same-origin'
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    console.log('[FeedbackBubble] Loaded notifications:', data);

    updateBadge(data.unread_count || 0);

    if (!data.notifications || data.notifications.length === 0) {
      container.innerHTML = `
        <div class="py-8 px-4 text-center">
          <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-green-100 flex items-center justify-center">
            <svg class="w-6 h-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-sm font-medium text-gray-700">All caught up!</p>
          <p class="text-xs text-gray-400 mt-1">No new notifications</p>
        </div>`;
      return;
    }

    container.innerHTML = data.notifications.slice(0, 5).map(notif => `
      <div class="px-3 py-2.5 hover:bg-gray-50 border-b border-gray-100 cursor-pointer ${notif.read ? '' : 'bg-blue-50'}"
           onclick="handleNotificationClick(${notif.id}, '${notif.type}', ${JSON.stringify(notif.metadata || {}).replace(/"/g, '&quot;')})">
        <div class="flex items-start gap-2">
          <div class="flex-shrink-0 mt-0.5">${getNotificationIcon(notif.type)}</div>
          <div class="flex-1 min-w-0">
            <p class="text-sm text-gray-800 ${notif.read ? '' : 'font-medium'}">${escapeHtml(notif.message)}</p>
            <p class="text-xs text-gray-400 mt-0.5">${formatTimeAgo(notif.created_at)}</p>
          </div>
          ${notif.read ? '' : '<div class="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0 mt-1.5"></div>'}
        </div>
      </div>
    `).join('');
  } catch (error) {
    console.error('[FeedbackBubble] Failed to load notifications:', error);
    container.innerHTML = '<div class="p-4 text-center text-red-500 text-sm">Failed to load</div>';
  }
}

function getNotificationIcon(type) {
  const icons = {
    'new_message': '<svg class="w-4 h-4 text-purple-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>',
    'feedback_comment': '<svg class="w-4 h-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" /></svg>',
    'feedback_status_change': '<svg class="w-4 h-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>'
  };
  return icons[type] || '<svg class="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>';
}

// Global function for onclick handler
window.handleNotificationClick = async function(notificationId, type, metadata) {
  // Mark as read
  try {
    await fetch(`/llama_bot/notifications/${notificationId}/read`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': getCSRFToken() }
    });
    // Refresh the list to show read state
    loadNotifications();
  } catch (e) { console.error(e); }

  // Navigate in new tab
  if (type === 'new_message' && metadata.conversation_id) {
    window.open(`/llama_bot/conversations/${metadata.conversation_id}`, '_blank');
  } else if (type === 'feedback_comment' && metadata.feedback_id) {
    window.open(`/llama_bot/feedback/${metadata.feedback_id}`, '_blank');
  }
};

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

function formatTimeAgo(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);

  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

// Setup ActionCable subscription
function setupNotificationSubscription() {
  if (typeof ActionCable === 'undefined') {
    console.warn('[FeedbackBubble] ActionCable not available');
    return;
  }

  if (notificationSubscription) return;

  try {
    const cable = ActionCable.createConsumer();
    notificationSubscription = cable.subscriptions.create(
      { channel: 'LlamaBotRails::NotificationChannel' },
      {
        connected() {
          console.log('[FeedbackBubble] Connected to NotificationChannel');
        },
        disconnected() {
          console.log('[FeedbackBubble] Disconnected from NotificationChannel');
        },
        received(data) {
          console.log('[FeedbackBubble] Received:', data);

          if (data.unread_count !== undefined) {
            updateBadge(data.unread_count);
          }

          if (data.type === 'notification' || data.type === 'new_message') {
            // Refresh if panel is open on notifications tab
            if (!document.getElementById('content-notifications')?.classList.contains('hidden')) {
              loadNotifications();
            }
            // Show toast
            showToastNotification(data);
          }
        }
      }
    );
  } catch (e) {
    console.error('[FeedbackBubble] Failed to setup ActionCable:', e);
  }
}

function showToastNotification(data) {
  const message = data.notification?.message || data.message?.body || 'New notification';

  const toast = document.createElement('div');
  toast.className = 'fixed bottom-20 right-5 bg-white rounded-lg shadow-xl border border-gray-200 p-3 max-w-xs z-50';
  toast.style.animation = 'slideIn 0.3s ease-out';
  toast.innerHTML = `
    <div class="flex items-start gap-2">
      <div class="flex-shrink-0 w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
        <svg class="w-4 h-4 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm text-gray-800">${escapeHtml(message)}</p>
      </div>
      <button onclick="this.parentElement.parentElement.remove()" class="text-gray-400 hover:text-gray-600 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  `;

  // Add animation styles if not present
  if (!document.getElementById('toast-styles')) {
    const style = document.createElement('style');
    style.id = 'toast-styles';
    style.textContent = '@keyframes slideIn { from { opacity: 0; transform: translateX(100px); } to { opacity: 1; transform: translateX(0); } }';
    document.head.appendChild(style);
  }

  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transition = 'opacity 0.3s';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
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
  if (status) status.classList.add('hidden');
}

function togglePanel(show) {
  const panel = document.getElementById('feedback-panel');
  const trigger = document.getElementById('feedback-trigger');

  if (panel && trigger) {
    if (show) {
      panel.classList.remove('hidden');
      trigger.classList.add('bg-purple-600', 'opacity-100');
      trigger.classList.remove('bg-gray-400', 'opacity-60');

      // Fetch unread count
      fetchUnreadCount();
    } else {
      panel.classList.add('hidden');
      trigger.classList.remove('bg-purple-600', 'opacity-100');
      trigger.classList.add('bg-gray-400', 'opacity-60');
    }
    isFormOpen = show;
  }
}

async function fetchUnreadCount() {
  try {
    const response = await fetch('/llama_bot/notifications/unread_count.json');
    const data = await response.json();
    updateBadge(data.unread_count);
  } catch (e) { console.error(e); }
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
  const requestPath = window.request_path || '/';
  const viewPath = window.view_path || '';
  const pageContext = `\n\n---\nPage: ${requestPath}\nView: ${viewPath}`;
  const fullDescription = description + pageContext;

  const formData = new FormData();
  formData.append('user_feedback[title]', 'Quick Feedback');
  formData.append('user_feedback[description]', fullDescription);
  formData.append('user_feedback[feedback_type]', 'general');

  if (file) formData.append('user_feedback[attachments][]', file);
  if (screenshot && screenshot.blob) {
    const screenshotFile = new File([screenshot.blob], screenshot.filename, { type: 'image/png' });
    formData.append('user_feedback[attachments][]', screenshotFile);
  }

  const response = await fetch('/llama_bot/feedback', {
    method: 'POST',
    headers: { 'X-CSRF-Token': getCSRFToken(), 'Accept': 'text/html' },
    body: formData,
    redirect: 'manual'
  });

  if (response.type === 'opaqueredirect' || response.ok || (response.status >= 200 && response.status < 400)) {
    return { success: true };
  }
  throw new Error('Failed to submit feedback');
}

function attachEventListeners() {
  const trigger = document.getElementById('feedback-trigger');
  const form = document.getElementById('feedback-form');
  const fileInput = document.getElementById('feedback-file');
  const filenameDisplay = document.getElementById('feedback-filename');

  // Toggle panel
  if (trigger) {
    trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      togglePanel(!isFormOpen);
    });
  }

  // Tab switching - use event delegation on the tab container
  const tabFeedback = document.getElementById('tab-feedback');
  const tabMessages = document.getElementById('tab-messages');
  const tabNotifications = document.getElementById('tab-notifications');

  if (tabFeedback) {
    tabFeedback.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      switchTab('feedback');
    });
  }
  if (tabMessages) {
    tabMessages.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      switchTab('messages');
    });
  }
  if (tabNotifications) {
    tabNotifications.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      switchTab('notifications');
    });
  }

  // Mark all read
  const markAllReadBtn = document.getElementById('mark-all-read-btn');
  if (markAllReadBtn) {
    markAllReadBtn.addEventListener('click', async () => {
      try {
        await fetch('/llama_bot/notifications/mark_read', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': getCSRFToken() }
        });
        loadNotifications();
      } catch (e) { console.error(e); }
    });
  }

  // File input
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
      togglePanel(false);
      window.screenshotAnnotator?.startCapture((attachment) => {
        screenshotAttachment = attachment;
        const preview = document.getElementById('feedback-screenshot-preview');
        const img = document.getElementById('feedback-screenshot-img');
        if (preview && img && attachment.dataUrl) {
          img.src = attachment.dataUrl;
          preview.classList.remove('hidden');
        }
        togglePanel(true);
      });
    });
  }

  // Remove screenshot
  const removeScreenshotBtn = document.getElementById('feedback-screenshot-remove');
  if (removeScreenshotBtn) {
    removeScreenshotBtn.addEventListener('click', () => {
      screenshotAttachment = null;
      document.getElementById('feedback-screenshot-preview')?.classList.add('hidden');
    });
  }

  // Form submit
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
          togglePanel(false);
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
      togglePanel(false);
    }
  });
}

function initFeedbackBubble() {
  if (bubbleInitialized || !shouldShowBubble()) return;
  if (document.getElementById('llamapress-feedback-bubble')) return;

  const wrapper = document.createElement('div');
  wrapper.innerHTML = createBubbleHTML();
  document.body.appendChild(wrapper.firstElementChild);

  attachEventListeners();
  setupNotificationSubscription();
  fetchUnreadCount();

  bubbleInitialized = true;
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initFeedbackBubble);

// Handle Turbo navigation
document.addEventListener('turbo:load', () => {
  if (shouldShowBubble() && !document.getElementById('llamapress-feedback-bubble')) {
    bubbleInitialized = false;
    initFeedbackBubble();
  }
});
