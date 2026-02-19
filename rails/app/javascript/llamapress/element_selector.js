// Element Selector functionality
// Allows users to visually select elements in the page for the AI to reference

let elementSelectorEnabled = false;
let elementSelectorStyles = null;
let currentHighlightedElement = null;

export function enableElementSelector() {
    if (elementSelectorEnabled) return;

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
}

export function disableElementSelector() {
    if (!elementSelectorEnabled) return;

    elementSelectorEnabled = false;
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
}

function handleElementSelectorMouseMove(event) {
    const target = event.target;

    if (!target || target.tagName === 'HTML' || target.tagName === 'BODY') {
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

    // Extract text content for display
    let textContent = extractElementText(target);

    // Get the outerHTML for the LLM
    let outerHTML = target.outerHTML;

    // Send selected element data to parent
    window.parent.postMessage({
        source: 'element-selector',
        type: 'element-selected',
        text: textContent,
        html: outerHTML
    }, '*');

    // Visual feedback
    showSelectionFeedback(target);
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
