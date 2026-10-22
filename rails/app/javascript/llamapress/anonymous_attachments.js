// What a signed-out visitor may attach to feedback: images only (PNG, JPEG, WebP, GIF),
// at most 3, at most 5 MB each. This mirrors the server's rule in llama_bot_rails'
// UserFeedbacksController#attach_anonymous_images, which is the real control (it checks
// the file's bytes). The browser applies it too so a file the server would drop is
// refused here with a visible reason, instead of looking attached and then vanishing.
//
// Kept separate from feedback_bubble.js so it is unit-testable
// (spec/javascript/llamapress/feedback_bubble_anonymous_media.test.js).

export const ANON_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/webp', 'image/gif']
export const ANON_IMAGE_LIMIT = 3
export const ANON_IMAGE_MAX_BYTES = 5 * 1024 * 1024

// Splits files into the ones to keep and "name: reason" lines for the rest, in order,
// so the first three acceptable images win.
export function screenAnonymousFiles(files) {
  const accepted = []
  const refused = []

  Array.from(files || []).forEach((file) => {
    let reason = null
    if (!ANON_IMAGE_TYPES.includes(file.type)) reason = 'not an image'
    else if (file.size > ANON_IMAGE_MAX_BYTES) reason = 'over 5 MB'
    else if (accepted.length >= ANON_IMAGE_LIMIT) reason = `only ${ANON_IMAGE_LIMIT} images allowed`

    if (reason) refused.push(`${file.name}: ${reason}`)
    else accepted.push(file)
  })

  return { accepted, refused }
}
