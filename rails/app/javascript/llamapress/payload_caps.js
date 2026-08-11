// Byte caps for the payloads this app sends to the chat (SupportIncident #246).
//
// A page that inlines a lot of content — meeting transcripts, long tables, a big
// list — has a `document.documentElement.outerHTML` in the multi-megabyte range.
// It was being sent whole on EVERY chat message (10.6 MB on the reported box),
// as was the entire `outerHTML` of whatever the element picker was pointed at
// (375 KB). Neither is useful at that size: the agent reads `view_path` /
// `request_path` out of the debug payload, and a picked element is context, not
// a document to be reproduced.
//
// LlamaBot caps these again on ingestion (`app/websocket/payload_limits.py`) and
// that server-side cap is the load-bearing one — it ships in the image and no
// client can bypass it. This exists so the bytes don't cross the wire at all.

export const MAX_PAGE_HTML_BYTES = 64 * 1024;
export const MAX_SELECTED_ELEMENT_BYTES = 24 * 1024;

function byteLength(text) {
  try {
    return new TextEncoder().encode(text).length;
  } catch {
    return text.length;
  }
}

// Same wording the backend uses, so a truncation looks identical wherever the
// agent runs into it.
function marker(omitted) {
  return `\n... [truncated: ${omitted} bytes omitted] ...\n`;
}

// Keep the head (the document/element opening, which says WHAT this is) and the
// tail (its closing markup), and say plainly what was dropped in between.
export function capPayload(text, maxBytes) {
  if (typeof text !== 'string') return text;
  const size = byteLength(text);
  if (size <= maxBytes) return text;

  let headChars = Math.floor(maxBytes * 0.7);
  let tailChars = Math.floor(maxBytes * 0.2);
  let result = '';
  for (let i = 0; i < 8; i++) {
    const head = text.slice(0, headChars);
    const tail = tailChars > 0 ? text.slice(text.length - tailChars) : '';
    result = head + marker(size - byteLength(head) - byteLength(tail)) + tail;
    if (byteLength(result) <= maxBytes) return result;
    headChars = Math.floor(headChars * 0.7);
    tailChars = Math.floor(tailChars * 0.7);
  }
  return result;
}
