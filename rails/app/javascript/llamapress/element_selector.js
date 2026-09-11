// Element Selector functionality
// Allows users to visually select elements in the page for the AI to reference
//
// Input is handled with POINTER events, not mouse events. Pointer events are the one
// path that covers mouse, touch and pen; the mouse-only version of this file was
// unusable on a phone (SI: Nicole Haldis / Jennie Morgan, 2026-09-11). It only ever
// appeared to work on Android Chrome because Chromium synthesises a compatibility
// mousemove + click from a tap — WebKit does not do that for a tap on a plain <p>,
// and no engine gives you hover on a finger.
//
// Two interaction shapes fall out of that, and both are deliberate:
//   * mouse/pen  — hover highlights, one click commits. Unchanged from before.
//   * touch      — first tap highlights, a second tap on the SAME element (or the
//                  banner's "Use this") commits. There is no hover on a finger, so
//                  committing on the first tap would pick whatever the finger landed
//                  on before the user could see it.
// The banner is not optional on either input: enabling the selector used to draw
// nothing at all while the caller had already hidden the feedback panel, and Escape
// was the only exit. On a phone that is an invisible mode you escape by reloading.

import { capPayload, MAX_SELECTED_ELEMENT_BYTES } from "llamapress/payload_caps"

const BANNER_ID = 'llamapress-element-selector-banner';

let elementSelectorEnabled = false;
let elementSelectorStyles = null;
let elementSelectorBanner = null;
let currentHighlightedElement = null;
let previousTouchAction = '';
// When set, the selected element is delivered to this callback locally instead of
// being posted to the parent window (used by the in-app feedback bubble).
let onSelectCallback = null;
let onCancelCallback = null;

// enableElementSelector() with no args keeps the original behavior (postMessage to
// the parent window, driven by the chat iframe via message_handler.js).
// Passing { onSelect, onCancel } switches to local delivery for same-document callers.
export function enableElementSelector(options = {}) {
    if (elementSelectorEnabled) return;

    onSelectCallback = options.onSelect || null;
    onCancelCallback = options.onCancel || null;

    elementSelectorEnabled = true;
    console.log('Element selector enabled');

    // Inject styles for hover highlighting
    elementSelectorStyles = document.createElement('style');
    elementSelectorStyles.id = 'element-selector-styles';
    elementSelectorStyles.textContent = `
        .element-selector-highlight {
            outline: 2px solid #4CAF50 !important;
            outline-offset: 2px !important;
            background-color: rgba(76, 175, 80, 0.1) !important;
            cursor: crosshair !important;
        }
        .element-selector-active * {
            cursor: crosshair !important;
        }
        #${BANNER_ID} {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 2147483647;
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            box-sizing: border-box;
            font: 500 14px/1.3 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            color: #fff;
            background: #6d28d9;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.25);
            cursor: default !important;
        }
        #${BANNER_ID} * { cursor: pointer !important; }
        #${BANNER_ID} .llamapress-es-text {
            flex: 1 1 auto;
            min-width: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            cursor: default !important;
        }
        #${BANNER_ID} button {
            flex: 0 0 auto;
            border: 0;
            border-radius: 6px;
            padding: 8px 14px;
            font: inherit;
            font-weight: 600;
        }
        #${BANNER_ID} button[data-element-selector-confirm] {
            background: #fff;
            color: #6d28d9;
        }
        #${BANNER_ID} button[data-element-selector-confirm][disabled] {
            opacity: 0.45;
        }
        #${BANNER_ID} button[data-element-selector-cancel] {
            background: rgba(255, 255, 255, 0.18);
            color: #fff;
        }
    `;
    document.head.appendChild(elementSelectorStyles);

    // Mark body as active
    document.body.classList.add('element-selector-active');

    // A drag during selection must not scroll the page out from under the finger.
    previousTouchAction = document.body.style.touchAction;
    document.body.style.touchAction = 'none';

    buildBanner();

    // Add event listeners. Pointer events carry mouse, touch and pen alike; the
    // click listener is here only to swallow the click so picking a link or a
    // button does not also navigate or submit.
    document.addEventListener('pointermove', handleElementSelectorPointerMove, true);
    document.addEventListener('pointerup', handleElementSelectorPointerUp, true);
    document.addEventListener('click', swallowClick, true);
    document.addEventListener('keydown', handleElementSelectorKeydown, true);
}

export function disableElementSelector() {
    if (!elementSelectorEnabled) return;

    elementSelectorEnabled = false;
    onSelectCallback = null;
    onCancelCallback = null;
    console.log('Element selector disabled');

    // Remove styles
    if (elementSelectorStyles) {
        elementSelectorStyles.remove();
        elementSelectorStyles = null;
    }

    removeBanner();

    // Remove body class
    document.body.classList.remove('element-selector-active');
    document.body.style.touchAction = previousTouchAction;
    previousTouchAction = '';

    // Remove highlight from current element
    if (currentHighlightedElement) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
        currentHighlightedElement = null;
    }

    // Remove event listeners
    document.removeEventListener('pointermove', handleElementSelectorPointerMove, true);
    document.removeEventListener('pointerup', handleElementSelectorPointerUp, true);
    document.removeEventListener('keydown', handleElementSelectorKeydown, true);

    // The click that trails the committing tap has not been delivered yet — a touch
    // engine can take a few hundred ms to synthesise it. Keep swallowing until it
    // arrives (or clearly is not coming) so picking a link does not then follow it.
    releaseClickSwallowerSoon();
}

// The banner is the visible half of the fix: the mode announces itself and offers a
// way out that does not require a keyboard.
function buildBanner() {
    const banner = document.createElement('div');
    banner.id = BANNER_ID;
    banner.setAttribute('role', 'toolbar');

    const text = document.createElement('span');
    text.className = 'llamapress-es-text';
    text.setAttribute('data-element-selector-text', '');
    banner.appendChild(text);

    const confirm = document.createElement('button');
    confirm.type = 'button';
    confirm.setAttribute('data-element-selector-confirm', '');
    confirm.textContent = 'Use this';
    confirm.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        if (currentHighlightedElement) commitSelection(currentHighlightedElement);
    });
    banner.appendChild(confirm);

    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.setAttribute('data-element-selector-cancel', '');
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        cancelSelection();
    });
    banner.appendChild(cancel);

    document.body.appendChild(banner);
    elementSelectorBanner = banner;
    updateBanner();
}

function removeBanner() {
    if (elementSelectorBanner) {
        elementSelectorBanner.remove();
        elementSelectorBanner = null;
    }
    // Belt and braces: a caller that rebuilt the DOM under us could have orphaned it.
    document.getElementById(BANNER_ID)?.remove();
}

function updateBanner() {
    if (!elementSelectorBanner) return;

    const text = elementSelectorBanner.querySelector('[data-element-selector-text]');
    const confirm = elementSelectorBanner.querySelector('[data-element-selector-confirm]');
    const armed = !!currentHighlightedElement;

    if (text) {
        text.textContent = armed
            ? 'Tap again or “Use this” to attach this element'
            : 'Tap the part of the page you want to point at';
    }
    if (confirm) {
        confirm.disabled = !armed;
    }
}

// Cancel selection mode on Escape (e.g. user changed their mind).
function handleElementSelectorKeydown(event) {
    if (event.key !== 'Escape') return;
    event.preventDefault();
    event.stopPropagation();
    cancelSelection();
}

function cancelSelection() {
    const onCancel = onCancelCallback;
    disableElementSelector();
    if (onCancel) onCancel();
}

// Elements this tool must never pick: the feedback bubble that launched it, and its
// own banner.
function isSelectable(target) {
    if (!target || target.nodeType !== 1) return false;
    if (target.tagName === 'HTML' || target.tagName === 'BODY') return false;
    if (typeof target.closest !== 'function') return false;
    if (target.closest('#llamapress-feedback-bubble')) return false;
    if (target.closest(`#${BANNER_ID}`)) return false;
    return true;
}

function highlight(target) {
    if (currentHighlightedElement === target) return;

    if (currentHighlightedElement) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
    }
    target.classList.add('element-selector-highlight');
    currentHighlightedElement = target;
    updateBanner();
}

// A finger has no hover, so pointermove only drives the highlight for devices that
// actually have one. (A touch pointermove only arrives mid-drag, after the user has
// already committed to a spot.)
function handleElementSelectorPointerMove(event) {
    if (isTouchLike(event)) return;
    const target = event.target;
    if (!isSelectable(target)) return;
    highlight(target);
}

function handleElementSelectorPointerUp(event) {
    const target = event.target;
    if (!isSelectable(target)) return;

    event.preventDefault();
    event.stopPropagation();

    if (!isTouchLike(event)) {
        // Mouse/pen: the user saw the hover highlight, so one click commits.
        commitSelection(target);
        return;
    }

    // Touch: first tap arms, a second tap on the same element confirms.
    if (currentHighlightedElement === target) {
        commitSelection(target);
        return;
    }
    highlight(target);
}

function isTouchLike(event) {
    // pointerType is absent on a synthesised/legacy event; treat that as a mouse,
    // which is the behaviour this file had before pointer events.
    return event.pointerType === 'touch' || event.pointerType === 'pen';
}

function commitSelection(target) {
    if (!isSelectable(target)) return;

    // Extract text content for display
    let textContent = extractElementText(target);

    // Get the outerHTML for the LLM. Capped: picking a <section> on a
    // content-heavy page produced a 375 KB block inside a single chat message,
    // which no amount of conversation compaction could ever reclaim.
    let outerHTML = capPayload(target.outerHTML, MAX_SELECTED_ELEMENT_BYTES);

    // Build a CSS selector path for the element
    let selector = buildCssSelector(target);

    // Visual feedback
    showSelectionFeedback(target);

    if (onSelectCallback) {
        // Local delivery (e.g. feedback bubble). Capture the callback before
        // disabling, since disableElementSelector() clears it.
        const cb = onSelectCallback;
        disableElementSelector();
        cb({ text: textContent, html: outerHTML, selector });
        return;
    }

    disableElementSelector();

    // Default: send selected element data to the parent window (chat flow)
    window.parent.postMessage({
        source: 'element-selector',
        type: 'element-selected',
        text: textContent,
        html: outerHTML,
        selector: selector
    }, '*');
}

function swallowClick(event) {
    // The banner's own buttons are the one thing that still needs its click: this
    // listener is on document in the CAPTURE phase, so stopping propagation here
    // would stop "Use this" and "Cancel" from ever firing.
    const target = event.target;
    if (target && typeof target.closest === 'function' && target.closest(`#${BANNER_ID}`)) return;

    event.preventDefault();
    event.stopPropagation();
}

let clickSwallowerTimer = null;

function releaseClickSwallowerSoon() {
    if (clickSwallowerTimer) clearTimeout(clickSwallowerTimer);
    clickSwallowerTimer = setTimeout(() => {
        clickSwallowerTimer = null;
        // Re-arming while the timer was pending must not strip the live listener.
        if (elementSelectorEnabled) return;
        document.removeEventListener('click', swallowClick, true);
    }, 700);
}

// Build a reasonably-specific CSS selector path for an element by walking up
// ancestors until an id is found or the body is reached.
function buildCssSelector(element) {
    if (!element || !element.tagName) return '';

    const parts = [];
    let el = element;

    while (el && el.nodeType === 1 && el.tagName !== 'BODY' && el.tagName !== 'HTML') {
        let part = el.tagName.toLowerCase();

        if (el.id) {
            // An id is unique enough to stop here.
            parts.unshift(`#${CSS.escape(el.id)}`);
            break;
        }

        const className = (el.className && typeof el.className === 'string')
            ? el.className.trim().split(/\s+/).filter(Boolean)[0]
            : null;
        if (className) {
            part += `.${CSS.escape(className)}`;
        }

        // Disambiguate among siblings of the same tag.
        const parent = el.parentElement;
        if (parent) {
            const sameTag = Array.from(parent.children).filter(c => c.tagName === el.tagName);
            if (sameTag.length > 1) {
                part += `:nth-of-type(${sameTag.indexOf(el) + 1})`;
            }
        }

        parts.unshift(part);
        el = el.parentElement;
    }

    return parts.join(' > ');
}

function extractElementText(element) {
    // Get text content and clean it up
    let text = element.textContent || element.innerText || '';
    text = text.trim();

    // If text is too long, truncate it
    if (text.length > 200) {
        text = text.substring(0, 200) + '...';
    }

    // If element has no text, try to describe it
    if (!text) {
        const tagName = element.tagName.toLowerCase();
        const className = element.className ? `.${element.className.split(' ')[0]}` : '';
        const id = element.id ? `#${element.id}` : '';
        text = `${tagName}${id}${className} element`;
    }

    return text;
}

function showSelectionFeedback(element) {
    const originalOutline = element.style.outline;
    const originalBackground = element.style.backgroundColor;

    element.style.outline = '3px solid #4CAF50';
    element.style.backgroundColor = 'rgba(76, 175, 80, 0.3)';

    setTimeout(() => {
        element.style.outline = originalOutline;
        element.style.backgroundColor = originalBackground;
    }, 300);
}
