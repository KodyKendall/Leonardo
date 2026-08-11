// Feedback element highlight
//
// A feedback item's "Open page" link carries the CSS selector of the element the
// reporter picked (?lp_feedback_element=...&lp_feedback_id=...). Without this, the link
// dropped you on the right page with no indication of WHICH element the feedback was
// about. This finds that element, scrolls to it and rings it, with a banner naming the
// feedback item. The link is built in llama_bot_rails FeedbackHelper#feedback_page_path.

export const ELEMENT_PARAM = 'lp_feedback_element';
export const FEEDBACK_ID_PARAM = 'lp_feedback_id';

const STYLE_ID = 'lp-feedback-highlight-styles';
const BANNER_ID = 'lp-feedback-highlight-banner';
const DISMISS_ID = 'lp-feedback-highlight-dismiss';
const HIGHLIGHT_CLASS = 'lp-feedback-highlight';

function injectStyles() {
  if (document.getElementById(STYLE_ID)) return;

  const style = document.createElement('style');
  style.id = STYLE_ID;
  style.textContent = `
    .${HIGHLIGHT_CLASS} {
      outline: 3px solid #7c3aed !important;
      outline-offset: 3px !important;
      border-radius: 3px;
      animation: lp-feedback-pulse 1.2s ease-out 3;
    }
    @keyframes lp-feedback-pulse {
      0%   { box-shadow: 0 0 0 0 rgba(124, 58, 237, 0.55); }
      100% { box-shadow: 0 0 0 14px rgba(124, 58, 237, 0); }
    }
    #${BANNER_ID} {
      position: fixed;
      top: 16px;
      left: 50%;
      transform: translateX(-50%);
      z-index: 2147483000;
      display: flex;
      align-items: center;
      gap: 12px;
      max-width: min(92vw, 640px);
      padding: 10px 14px;
      border-radius: 9999px;
      background: #4c1d95;
      color: #ffffff;
      font: 500 14px/1.35 system-ui, -apple-system, "Segoe UI", sans-serif;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
    }
    #${BANNER_ID} .lp-feedback-banner-text {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    #${DISMISS_ID} {
      flex: none;
      border: 0;
      border-radius: 9999px;
      padding: 4px 10px;
      background: rgba(255, 255, 255, 0.18);
      color: inherit;
      font: inherit;
      cursor: pointer;
    }
    #${DISMISS_ID}:hover { background: rgba(255, 255, 255, 0.3); }
  `;
  document.head.appendChild(style);
}

// A selector captured against an older version of the page may no longer parse, and an
// invalid argument to querySelector throws — never let that break the page.
function findElement(selector) {
  try {
    return document.querySelector(selector);
  } catch (error) {
    return null;
  }
}

function clearHighlight() {
  document.querySelectorAll(`.${HIGHLIGHT_CLASS}`)
    .forEach(el => el.classList.remove(HIGHLIGHT_CLASS));
  document.getElementById(BANNER_ID)?.remove();
}

function showBanner(message) {
  document.getElementById(BANNER_ID)?.remove();

  const banner = document.createElement('div');
  banner.id = BANNER_ID;

  const text = document.createElement('span');
  text.className = 'lp-feedback-banner-text';
  text.textContent = message;

  const dismiss = document.createElement('button');
  dismiss.id = DISMISS_ID;
  dismiss.type = 'button';
  dismiss.textContent = 'Dismiss';
  dismiss.addEventListener('click', clearHighlight);

  banner.appendChild(text);
  banner.appendChild(dismiss);
  document.body.appendChild(banner);
}

// Take our params back out of the address bar so a reload, a bookmark or a copied URL
// is just the page — the highlight is a one-shot arrival cue, not page state.
function stripOwnParams() {
  const url = new URL(window.location.href);
  url.searchParams.delete(ELEMENT_PARAM);
  url.searchParams.delete(FEEDBACK_ID_PARAM);
  window.history.replaceState({}, '', `${url.pathname}${url.search}${url.hash}`);
}

export function highlightFeedbackElement() {
  const params = new URLSearchParams(window.location.search);
  const selector = params.get(ELEMENT_PARAM);
  if (!selector) return;

  const feedbackId = params.get(FEEDBACK_ID_PARAM);
  const label = feedbackId ? `Feedback #${feedbackId}` : 'Feedback';
  stripOwnParams();
  injectStyles();

  const element = findElement(selector);
  if (!element) {
    showBanner(`${label}: couldn't find the element that was reported — the page may have changed.`);
    return;
  }

  element.classList.add(HIGHLIGHT_CLASS);
  if (typeof element.scrollIntoView === 'function') {
    element.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
  showBanner(`${label} was reported on this element.`);
}

document.addEventListener('DOMContentLoaded', highlightFeedbackElement);
document.addEventListener('turbo:load', highlightFeedbackElement);
