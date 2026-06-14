// Element Selector functionality
// Allows users to visually select elements in the page for the AI to reference

let elementSelectorEnabled = false;
let elementSelectorStyles = null;
let currentHighlightedElement = null;
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
    `;
    document.head.appendChild(elementSelectorStyles);

    // Mark body as active
    document.body.classList.add('element-selector-active');

    // Add event listeners
    document.addEventListener('mousemove', handleElementSelectorMouseMove, true);
    document.addEventListener('click', handleElementSelectorClick, true);
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

    // Remove body class
    document.body.classList.remove('element-selector-active');

    // Remove highlight from current element
    if (currentHighlightedElement) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
        currentHighlightedElement = null;
    }

    // Remove event listeners
    document.removeEventListener('mousemove', handleElementSelectorMouseMove, true);
    document.removeEventListener('click', handleElementSelectorClick, true);
    document.removeEventListener('keydown', handleElementSelectorKeydown, true);
}

// Cancel selection mode on Escape (e.g. user changed their mind).
function handleElementSelectorKeydown(event) {
    if (event.key !== 'Escape') return;
    event.preventDefault();
    event.stopPropagation();
    const onCancel = onCancelCallback;
    disableElementSelector();
    if (onCancel) onCancel();
}

function handleElementSelectorMouseMove(event) {
    const target = event.target;

    if (!target || target.tagName === 'HTML' || target.tagName === 'BODY') {
        return;
    }

    // Never highlight the feedback bubble itself.
    if (target.closest('#llamapress-feedback-bubble')) {
        return;
    }

    // Remove highlight from previous element
    if (currentHighlightedElement && currentHighlightedElement !== target) {
        currentHighlightedElement.classList.remove('element-selector-highlight');
    }

    // Add highlight to current target
    target.classList.add('element-selector-highlight');
    currentHighlightedElement = target;
}

function handleElementSelectorClick(event) {
    event.preventDefault();
    event.stopPropagation();

    const target = event.target;

    if (!target || target.tagName === 'HTML' || target.tagName === 'BODY') {
        return;
    }

    // Ignore clicks on the feedback bubble itself.
    if (target.closest('#llamapress-feedback-bubble')) {
        return;
    }

    // Extract text content for display
    let textContent = extractElementText(target);

    // Get the outerHTML for the LLM
    let outerHTML = target.outerHTML;

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

    // Default: send selected element data to the parent window (chat flow)
    window.parent.postMessage({
        source: 'element-selector',
        type: 'element-selected',
        text: textContent,
        html: outerHTML,
        selector: selector
    }, '*');
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
