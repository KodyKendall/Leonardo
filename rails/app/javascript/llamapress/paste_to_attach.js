// Paste-to-attach: an image on the clipboard, pasted into a text box, becomes a real
// file on that form's file input — no save-to-disk-then-browse round trip.
//
// Kept separate from the widgets that use it so the clipboard/DataTransfer handling is
// unit-testable (spec/javascript/llamapress/paste_to_attach.test.js).

// A clipboard *screenshot* arrives as a generic "image.png", so repeat pastes are
// indistinguishable in an attachment list — stamp those. But a file copied from the
// OS file manager (or a browser download) keeps its real name on the clipboard, and
// that name is how the user recognises which image they attached: keep it.
export function pastedFilename(mimeType, now = Date.now(), index = 0, originalName = '') {
  const ext = (mimeType?.split('/')[1] || 'png').replace('jpeg', 'jpg');
  const base = String(originalName || '').replace(/\.[^.]+$/, '').trim();

  // "image" is what every browser calls a nameless clipboard bitmap.
  if (base && base.toLowerCase() !== 'image') return `${base}.${ext}`;

  return `pasted-image-${now}${index ? `-${index}` : ''}.${ext}`;
}

// Returns the image files on a paste event's clipboard, renamed. Non-image pastes
// (plain text, HTML, a copied file that isn't an image) yield an empty array so the
// caller leaves the browser's normal paste alone.
export function imagesFromClipboard(clipboardData, now = Date.now()) {
  const items = Array.from(clipboardData?.items || []);
  return items
    .filter((item) => item.kind === 'file' && (item.type || '').startsWith('image/'))
    .map((item) => item.getAsFile())
    .filter(Boolean)
    .map((file, index) => new File([file], pastedFilename(file.type, now, index, file.name), { type: file.type }));
}

// Writes files onto a file input. Multi-file inputs keep what's already selected;
// a single-file input is replaced, matching what the browser itself would do.
export function addFilesToInput(input, files) {
  const transfer = new DataTransfer();
  if (input.multiple) Array.from(input.files || []).forEach((f) => transfer.items.add(f));
  files.forEach((f) => transfer.items.add(f));
  input.files = transfer.files;
  return input.files;
}

// Same file, picked twice, is one attachment — name+size+lastModified is as close to
// an identity as the browser gives us for a File.
function fileIdentity(file) {
  return `${file.name}:${file.size}:${file.lastModified}`
}

// A file picker REPLACES the input's selection: pick one image, pick another, and the
// first is gone. Screenshots and pastes go through addFilesToInput and accumulate, so
// only the picker loses files. Call this on the input's 'change' event with whatever
// was staged before the pick, and the two selections are merged instead.
export function mergePickedFiles(input, staged = []) {
  if (!input.multiple) return input.files

  const seen = new Set(staged.map(fileIdentity))
  const merged = staged.slice()
  Array.from(input.files || []).forEach((file) => {
    const identity = fileIdentity(file)
    if (seen.has(identity)) return
    seen.add(identity)
    merged.push(file)
  })

  const transfer = new DataTransfer()
  merged.forEach((file) => transfer.items.add(file))
  input.files = transfer.files
  return input.files
}

// Wires one text box to one file input. onAttach fires with the pasted files so the
// caller can refresh its own preview — setting .files programmatically does NOT fire
// the input's 'change' event, so previews will not update on their own.
export function enablePasteToAttach(textarea, fileInput, { onAttach } = {}) {
  if (!textarea || !fileInput) return;

  textarea.addEventListener('paste', (event) => {
    const images = imagesFromClipboard(event.clipboardData);
    if (!images.length) return;

    event.preventDefault();
    addFilesToInput(fileInput, images);
    if (onAttach) onAttach(images, fileInput);
  });
}
