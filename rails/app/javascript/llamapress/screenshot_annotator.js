// Screenshot Annotator
// Captures page regions and allows annotation with Fabric.js

// fabric.js and html2canvas used to arrive as <script> tags, but only
// layouts/application.html.erb ever carried them. This module comes in through the
// importmap, so it loads under EVERY layout — and an app with its own layouts
// (prototypes, admin, portal, super_admin, whatever Leo wrote next) had no `fabric`
// at all. The annotate modal opened blank and Attach dead-ended on "Failed to attach
// screenshot" (SI#479; 155 of 155 running boxes).
//
// Adding the tags to more layouts is what broke: it regresses the moment Leo writes
// the next layout, and Leo writes layouts constantly. The annotator fetches what it
// needs itself, which no new layout can undo.
const ANNOTATOR_DEPENDENCIES = [
  { global: 'html2canvas', src: 'https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js' },
  { global: 'fabric', src: 'https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.1/fabric.min.js' }
];

const loadedScripts = new Map();

// One in-flight request per URL, so several capture attempts don't each append their
// own copy of fabric.
function loadScriptOnce(src) {
  if (loadedScripts.has(src)) return loadedScripts.get(src);

  // Deliberately no "a tag for this src already exists, wait on it" branch: a layout
  // tag that already finished loading fires no further load event, so waiting on it
  // hangs forever. Callers only get here when the global is still missing, and
  // re-running these two UMD bundles just redefines the global.
  const promise = new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = src;
    script.async = true;
    script.addEventListener('load', () => resolve());
    script.addEventListener('error', () => reject(new Error(`Failed to load ${src}`)));
    document.head.appendChild(script);
  });

  // A failed load must NOT be cached as done — a blocked CDN or a flaky network
  // would otherwise disable the tool for the life of the page.
  promise.catch(() => loadedScripts.delete(src));
  loadedScripts.set(src, promise);
  return promise;
}

// How long an arrow drawn by a click with no drag comes out, in canvas px.
const DEFAULT_ARROW_LENGTH = 40;

class ScreenshotAnnotator {
  constructor() {
    this.fabricCanvas = null;
    this.modal = null;
    this.currentTool = 'pen';
    this.currentColor = '#ff4444';
    this.brushWidth = 3;
    this.onAttachCallback = null;
    this.originalImageData = null;
  }

  // Start the capture process
  async startCapture(onAttach) {
    this.onAttachCallback = onAttach;
    // Loaded on the button CLICK, not on the region mouseup: getDisplayMedia needs
    // that mouseup's user activation, and an await in front of it would spend the
    // gesture. By the time the user finishes dragging, both libraries are here.
    await this.ensureDependencies();
    this.showSelectionOverlay();
  }

  // A missing library is not fatal — capture degrades to an unannotated screenshot —
  // so a rejection here is logged and the capture goes ahead.
  async ensureDependencies() {
    await Promise.all(ANNOTATOR_DEPENDENCIES.map(async ({ global, src }) => {
      if (window[global]) return;
      try {
        await loadScriptOnce(src);
      } catch (err) {
        console.error(`Screenshot annotator: could not load ${global} from ${src}`, err);
      }
    }));
  }

  // Show overlay for region selection
  showSelectionOverlay() {
    // Hide feedback bubble during selection
    const feedbackBubble = document.getElementById('llamapress-feedback-bubble');
    if (feedbackBubble) feedbackBubble.style.display = 'none';

    const overlay = document.createElement('div');
    overlay.id = 'screenshot-selection-overlay';
    overlay.innerHTML = `
      <div style="position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
                  background: rgba(0,0,0,0.8); color: white; padding: 12px 24px;
                  border-radius: 8px; font-size: 14px; z-index: 100001;
                  display: flex; align-items: center; gap: 16px;">
        <span>Click and drag to select area</span>
        <button id="screenshot-cancel" style="background: rgba(255,255,255,0.2); border: none;
                color: white; padding: 6px 12px; border-radius: 4px; cursor: pointer;">
          Cancel
        </button>
      </div>
    `;
    overlay.style.cssText = `
      position: fixed; inset: 0; z-index: 100000;
      background: rgba(0,0,0,0.2); cursor: crosshair;
    `;

    let isDrawing = false;
    let startX, startY;
    let selectionBox = null;

    overlay.addEventListener('mousedown', (e) => {
      if (e.target.id === 'screenshot-cancel') {
        this.cancelCapture(overlay);
        return;
      }
      if (e.target.tagName === 'BUTTON') return;

      isDrawing = true;
      startX = e.clientX;
      startY = e.clientY;

      selectionBox = document.createElement('div');
      selectionBox.style.cssText = `
        position: fixed; border: 2px solid #8b5cf6;
        background: rgba(139, 92, 246, 0.1);
        pointer-events: none; box-shadow: 0 0 0 9999px rgba(0,0,0,0.3);
      `;
      overlay.appendChild(selectionBox);
    });

    overlay.addEventListener('mousemove', (e) => {
      if (!isDrawing || !selectionBox) return;

      const left = Math.min(startX, e.clientX);
      const top = Math.min(startY, e.clientY);
      const width = Math.abs(e.clientX - startX);
      const height = Math.abs(e.clientY - startY);

      selectionBox.style.left = left + 'px';
      selectionBox.style.top = top + 'px';
      selectionBox.style.width = width + 'px';
      selectionBox.style.height = height + 'px';
    });

    overlay.addEventListener('mouseup', async () => {
      if (!isDrawing || !selectionBox) return;
      isDrawing = false;

      const rect = selectionBox.getBoundingClientRect();
      if (rect.width < 10 || rect.height < 10) {
        selectionBox.remove();
        return;
      }

      overlay.remove();

      try {
        const imageData = await this.captureRegion(rect.left, rect.top, rect.width, rect.height);
        this.showAnnotationModal(imageData);
      } catch (err) {
        console.error('Failed to capture region:', err);
        this.finishWithoutAttachment();
      }
    });

    document.body.appendChild(overlay);

    // Add cancel button listener
    setTimeout(() => {
      document.getElementById('screenshot-cancel')?.addEventListener('click', () => {
        this.cancelCapture(overlay);
      });
    }, 0);
  }

  cancelCapture(overlay) {
    overlay.remove();
    this.finishWithoutAttachment();
  }

  // Capture a region using native Screen Capture API (getDisplayMedia)
  async captureRegion(x, y, width, height) {
    let cropBox = null;
    try {
      // Use getDisplayMedia for pixel-perfect screenshot
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: {
          displaySurface: 'browser',
        },
        preferCurrentTab: true,
        selfBrowserSurface: 'include',
        systemAudio: 'exclude'
      });

      // Get video track
      const track = stream.getVideoTracks()[0];

      // This app runs inside the chat's preview iframe, but getDisplayMedia
      // captures the whole TAB — chat panel included — while x/y came from a
      // drag in THIS frame. Same numbers, different origins: the crop landed
      // one chat-panel to the left of what the user selected, which is how the
      // chat kept turning up in people's screenshots. Region Capture trims the
      // stream to an element's box, putting both back in one coordinate space.
      if (this.isFramed()) {
        cropBox = this.addViewportCropBox();
        if (!(await this.cropTrackToElement(track, cropBox))) {
          // No Region Capture (non-Chromium): the capture can't be trusted to
          // line up, so render the region rather than crop the wrong pixels.
          this.stopStream(stream);
          return await this.captureRegionWithHtml2Canvas(x, y, width, height);
        }
      }

      // Wait a moment for the stream to be ready (and any crop to take effect)
      await new Promise(resolve => setTimeout(resolve, 100));

      // Use ImageCapture to grab a frame
      const imageCapture = new ImageCapture(track);
      const bitmap = await imageCapture.grabFrame();

      // Stop the stream
      this.stopStream(stream);

      // Draw the full capture to an offscreen canvas
      const fullCanvas = document.createElement('canvas');
      fullCanvas.width = bitmap.width;
      fullCanvas.height = bitmap.height;
      const fullCtx = fullCanvas.getContext('2d');
      fullCtx.drawImage(bitmap, 0, 0);

      // Scale from the box the capture actually covers — the crop box when the
      // stream was trimmed, this frame's viewport when it wasn't. Measuring
      // against window.innerHeight instead cost us the bottom of every shot on
      // a page shorter (or taller) than the box that was really captured.
      const box = this.capturedBox(cropBox);
      const scaleX = bitmap.width / box.width;
      const scaleY = bitmap.height / box.height;

      // Crop to the selected region
      const cropCanvas = document.createElement('canvas');
      cropCanvas.width = width * scaleX;
      cropCanvas.height = height * scaleY;
      const cropCtx = cropCanvas.getContext('2d');

      cropCtx.drawImage(
        fullCanvas,
        (x - box.left) * scaleX, (y - box.top) * scaleY, width * scaleX, height * scaleY,
        0, 0, cropCanvas.width, cropCanvas.height
      );

      return cropCanvas.toDataURL('image/png');
    } catch (err) {
      console.error('Screen capture failed:', err);

      // Fall back to html2canvas if getDisplayMedia fails
      console.log('Falling back to html2canvas...');
      return await this.captureRegionWithHtml2Canvas(x, y, width, height);
    } finally {
      cropBox?.remove();
    }
  }

  // Region Capture crops to an ELEMENT's box, and document.documentElement is
  // the whole PAGE: taller than the window on a long page, shorter on a short
  // one, and offset by the scroll position. A transparent fixed div is the one
  // box that always matches what a selection's coordinates are measured from.
  addViewportCropBox() {
    const box = document.createElement('div');
    box.id = 'screenshot-crop-box';
    box.style.cssText = 'position:fixed;inset:0;pointer-events:none;background:transparent;z-index:2147483646';
    document.body.appendChild(box);
    return box;
  }

  // The area of this page the captured pixels cover.
  capturedBox(cropBox) {
    if (cropBox) {
      const rect = cropBox.getBoundingClientRect();
      return { left: rect.left, top: rect.top, width: rect.width, height: rect.height };
    }
    return { left: 0, top: 0, width: window.innerWidth, height: window.innerHeight };
  }

  // Is this page running inside a frame (the chat's app preview) rather than as
  // the whole tab? Decides whether captured pixels need trimming to this frame.
  isFramed() {
    try {
      return window.self !== window.top;
    } catch (err) {
      // Cross-origin parents can throw on access — if we can't tell, assume the
      // preview, which is where this code actually runs.
      return true;
    }
  }

  // Region Capture (Chromium): ask the browser to trim the captured stream down
  // to one element's box, so the frames ARE the preview and nothing around it.
  async cropTrackToElement(track, element) {
    const CropTargetCtor = window.CropTarget;
    if (!track || typeof track.cropTo !== 'function') return false;
    if (!CropTargetCtor || typeof CropTargetCtor.fromElement !== 'function') return false;

    try {
      await track.cropTo(await CropTargetCtor.fromElement(element));
      return true;
    } catch (err) {
      console.warn('Region Capture unavailable; screenshot falls back to html2canvas:', err?.message);
      return false;
    }
  }

  stopStream(stream) {
    stream.getTracks().forEach(t => t.stop());
  }

  // html2canvas renders THIS document, so a region's coordinates are already
  // right — there is no surrounding tab to offset them against.
  async captureRegionWithHtml2Canvas(x, y, width, height) {
    // A bare `html2canvas` here threw ReferenceError on any layout that did not
    // ship the script tag, turning a merely DENIED screen-share into a dead end.
    if (!window.html2canvas) {
      throw new Error('Screen capture failed and html2canvas is unavailable');
    }
    const canvas = await window.html2canvas(document.body, {
      x: x + window.scrollX,
      y: y + window.scrollY,
      width: width,
      height: height,
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      ignoreElements: (el) => {
        return el.id === 'screenshot-selection-overlay' ||
               el.id === 'llamapress-feedback-bubble';
      }
    });

    return canvas.toDataURL('image/png');
  }

  restoreFeedbackBubble() {
    const feedbackBubble = document.getElementById('llamapress-feedback-bubble');
    if (feedbackBubble) feedbackBubble.style.display = '';
  }

  // Every way out of a capture that isn't a successful attach ends here. The
  // feedback bubble hides its panel before startCapture() and only reopens it
  // from the callback, so an exit that skips the callback strands the user on a
  // hidden panel, draft and all. null means "reopen, nothing to add".
  finishWithoutAttachment() {
    const callback = this.onAttachCallback;
    this.onAttachCallback = null;
    this.restoreFeedbackBubble();
    callback?.(null);
  }

  // Show the annotation modal
  showAnnotationModal(imageData) {
    this.originalImageData = imageData;

    // No fabric (CDN blocked, offline, CSP) means no drawing tools, but the capture
    // itself is still good. Attaching it beats a modal that can't paint and an
    // Attach button that can only fail.
    if (typeof fabric === 'undefined') {
      console.warn('Screenshot annotator: fabric.js unavailable, attaching capture without annotation');
      this.attachWithoutAnnotation(imageData);
      return;
    }

    this.modal = document.createElement('div');
    this.modal.id = 'screenshot-annotation-modal';
    this.modal.innerHTML = `
      <div style="position: fixed; inset: 0; background: rgba(0,0,0,0.9);
                  display: flex; align-items: center; justify-content: center; z-index: 100002;">
        <div style="background: #1a1a1a; border-radius: 12px; max-width: 95vw; max-height: 95vh;
                    display: flex; flex-direction: column; overflow: hidden; border: 1px solid #333;">

          <!-- Header -->
          <div style="display: flex; align-items: center; justify-content: space-between;
                      padding: 12px 16px; border-bottom: 1px solid #333;">
            <span style="color: white; font-weight: 500;">Annotate Screenshot</span>
            <button id="annotation-close" style="background: none; border: none; color: #888;
                    font-size: 20px; cursor: pointer; padding: 4px 8px;">&times;</button>
          </div>

          <!-- Toolbar -->
          <div style="display: flex; align-items: center; gap: 8px; padding: 8px 16px;
                      border-bottom: 1px solid #333; background: #222;">
            <button class="tool-btn active" data-tool="pen" title="Pen">
              <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a.996.996 0 0 0 0-1.41l-2.34-2.34a.996.996 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
              </svg>
            </button>
            <button class="tool-btn" data-tool="rectangle" title="Rectangle">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <rect x="3" y="3" width="18" height="18" rx="2"/>
              </svg>
            </button>
            <button class="tool-btn" data-tool="arrow" title="Arrow">
              <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z"/>
              </svg>
            </button>
            <button class="tool-btn" data-tool="text" title="Text">
              <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                <path d="M5 4v3h5.5v12h3V7H19V4z"/>
              </svg>
            </button>
            <button class="tool-btn" data-tool="move" title="Move / resize annotations">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"
                   stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                <path d="M12 3v18M3 12h18M12 3l-3 3M12 3l3 3M12 21l-3-3M12 21l3-3M3 12l3-3M3 12l3 3M21 12l-3-3M21 12l-3 3"/>
              </svg>
            </button>
            <div style="width: 1px; height: 24px; background: #444; margin: 0 4px;"></div>
            <input type="color" id="annotation-color" value="#ff4444"
                   style="width: 32px; height: 32px; border: none; cursor: pointer;
                          background: transparent; padding: 0;">
            <button id="annotation-undo" class="tool-btn" title="Undo">
              <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12.5 8c-2.65 0-5.05.99-6.9 2.6L2 7v9h9l-3.62-3.62c1.39-1.16 3.16-1.88 5.12-1.88 3.54 0 6.55 2.31 7.6 5.5l2.37-.78C21.08 11.03 17.15 8 12.5 8z"/>
              </svg>
            </button>
          </div>

          <!-- Canvas Container -->
          <div id="annotation-canvas-container" style="flex: 1; overflow: auto; padding: 16px;
                                                        display: flex; align-items: center;
                                                        justify-content: center; background: #111;">
            <canvas id="annotation-canvas"></canvas>
          </div>

          <!-- Actions -->
          <div style="display: flex; justify-content: flex-end; gap: 12px; padding: 12px 16px;
                      border-top: 1px solid #333;">
            <button id="annotation-cancel" style="padding: 8px 16px; background: #333; color: white;
                    border: none; border-radius: 6px; cursor: pointer;">Cancel</button>
            <button id="annotation-attach" style="padding: 8px 16px; background: #8b5cf6; color: white;
                    border: none; border-radius: 6px; cursor: pointer; font-weight: 500;">Attach</button>
          </div>
        </div>
      </div>
    `;

    // Add tool button styles
    const style = document.createElement('style');
    style.textContent = `
      #screenshot-annotation-modal .tool-btn {
        width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;
        background: transparent; border: none; border-radius: 6px; color: #888; cursor: pointer;
        transition: all 0.15s;
      }
      #screenshot-annotation-modal .tool-btn:hover {
        background: rgba(255,255,255,0.1); color: #fff;
      }
      #screenshot-annotation-modal .tool-btn.active {
        background: rgba(139,92,246,0.3); color: #a78bfa;
      }
    `;
    this.modal.appendChild(style);

    document.body.appendChild(this.modal);

    // Initialize Fabric.js canvas
    this.initFabricCanvas(imageData);
    this.attachModalListeners();
  }

  initFabricCanvas(imageData) {
    const img = new Image();
    // Anything thrown in here used to be swallowed by the image-load callback — it
    // fires on a later task, so it escaped the caller's try/catch and left a modal
    // with an empty canvas and no clue why.
    img.onload = () => {
      try {
        // Scale to fit viewport
        const maxWidth = window.innerWidth * 0.85;
        const maxHeight = window.innerHeight * 0.7;
        const scale = Math.min(maxWidth / img.width, maxHeight / img.height, 1);

        const canvasEl = document.getElementById('annotation-canvas');
        canvasEl.width = img.width * scale;
        canvasEl.height = img.height * scale;

        this.fabricCanvas = new fabric.Canvas('annotation-canvas', {
          width: img.width * scale,
          height: img.height * scale
        });

        // Set background image
        fabric.Image.fromURL(imageData, (fabricImg) => {
          fabricImg.scaleToWidth(this.fabricCanvas.width);
          this.fabricCanvas.setBackgroundImage(fabricImg, this.fabricCanvas.renderAll.bind(this.fabricCanvas));
        });

        // Set initial tool
        this.setTool('pen');
      } catch (err) {
        console.error('Screenshot annotator: failed to build the annotation canvas', err);
        this.teardownModal();
        this.attachWithoutAnnotation(imageData);
      }
    };
    img.onerror = () => {
      console.error('Screenshot annotator: captured image could not be decoded');
      this.teardownModal();
      this.finishWithoutAttachment();
    };
    img.src = imageData;
  }

  attachModalListeners() {
    // Tool buttons
    this.modal.querySelectorAll('.tool-btn[data-tool]').forEach(btn => {
      btn.addEventListener('click', () => {
        this.modal.querySelectorAll('.tool-btn[data-tool]').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.setTool(btn.dataset.tool);
      });
    });

    // Color picker
    document.getElementById('annotation-color')?.addEventListener('change', (e) => {
      this.currentColor = e.target.value;
      if (this.fabricCanvas?.freeDrawingBrush) {
        this.fabricCanvas.freeDrawingBrush.color = this.currentColor;
      }
    });

    // Undo
    document.getElementById('annotation-undo')?.addEventListener('click', () => {
      this.undo();
    });

    // Close/Cancel
    document.getElementById('annotation-close')?.addEventListener('click', () => this.closeModal());
    document.getElementById('annotation-cancel')?.addEventListener('click', () => this.closeModal());

    // Attach
    document.getElementById('annotation-attach')?.addEventListener('click', () => this.attachScreenshot());
  }

  setTool(tool) {
    this.currentTool = tool;
    if (!this.fabricCanvas) return;

    // Reset canvas state
    this.fabricCanvas.isDrawingMode = false;
    this.fabricCanvas.selection = true;
    this.fabricCanvas.defaultCursor = 'default';
    this.fabricCanvas.off('mouse:down');
    this.fabricCanvas.off('mouse:move');
    this.fabricCanvas.off('mouse:up');

    // While a drawing tool is armed, annotations are scenery. Leaving them evented
    // is what let Fabric claim a mouse-down that landed on one and drag it instead
    // of drawing — and what made the tools refuse to draw over them at all.
    // The Move tool is the deliberate way back.
    this.setObjectsInteractive(tool === 'move' || tool === 'select');

    switch (tool) {
      case 'pen':
        this.fabricCanvas.isDrawingMode = true;
        this.fabricCanvas.freeDrawingBrush = new fabric.PencilBrush(this.fabricCanvas);
        this.fabricCanvas.freeDrawingBrush.color = this.currentColor;
        this.fabricCanvas.freeDrawingBrush.width = this.brushWidth;
        break;

      case 'rectangle':
        this.setupRectangleTool();
        break;

      case 'arrow':
        this.setupArrowTool();
        break;

      case 'text':
        this.setupTextTool();
        break;

      case 'move':
      case 'select':
        // Nothing to arm: the reset above already restored selection, and
        // setObjectsInteractive() has handed the objects back to Fabric.
        break;
    }
  }

  // Fabric decides whether a mouse-down belongs to an object or to the canvas by
  // hit-testing evented objects. Toggling both flags together is what makes
  // "drawing tools draw, the move tool moves" true rather than aspirational.
  setObjectsInteractive(interactive) {
    if (!this.fabricCanvas) return;

    this.fabricCanvas.getObjects().forEach(obj => {
      obj.selectable = interactive;
      obj.evented = interactive;
    });

    if (!interactive) {
      this.fabricCanvas.discardActiveObject();
    }
    this.fabricCanvas.renderAll();
  }

  setupRectangleTool() {
    let isDrawing = false;
    let startX, startY;
    let rect;

    this.fabricCanvas.selection = false;
    this.fabricCanvas.defaultCursor = 'crosshair';

    // No `if (opt.target) return` guard: a drawing tool draws wherever you press,
    // including on top of a mark you already made.
    this.fabricCanvas.on('mouse:down', (opt) => {
      isDrawing = true;
      const pointer = this.fabricCanvas.getPointer(opt.e);
      startX = pointer.x;
      startY = pointer.y;

      rect = new fabric.Rect({
        left: startX,
        top: startY,
        width: 0,
        height: 0,
        fill: 'transparent',
        stroke: this.currentColor,
        strokeWidth: 3,
        selectable: false,
        evented: false
      });
      this.fabricCanvas.add(rect);
    });

    this.fabricCanvas.on('mouse:move', (opt) => {
      if (!isDrawing || !rect) return;
      const pointer = this.fabricCanvas.getPointer(opt.e);

      const left = Math.min(startX, pointer.x);
      const top = Math.min(startY, pointer.y);
      const width = Math.abs(pointer.x - startX);
      const height = Math.abs(pointer.y - startY);

      rect.set({ left, top, width, height });
      this.fabricCanvas.renderAll();
    });

    this.fabricCanvas.on('mouse:up', () => {
      isDrawing = false;
      if (rect && rect.width < 5 && rect.height < 5) {
        this.fabricCanvas.remove(rect);
      }
      rect = null;
    });
  }

  setupArrowTool() {
    let isDrawing = false;
    let startX, startY;
    let arrow;

    this.fabricCanvas.selection = false;
    this.fabricCanvas.defaultCursor = 'crosshair';

    // Same as the rectangle: press anywhere, including over an existing arrow.
    this.fabricCanvas.on('mouse:down', (opt) => {
      isDrawing = true;
      const pointer = this.fabricCanvas.getPointer(opt.e);
      startX = pointer.x;
      startY = pointer.y;
    });

    this.fabricCanvas.on('mouse:move', (opt) => {
      if (!isDrawing) return;
      const pointer = this.fabricCanvas.getPointer(opt.e);

      if (arrow) {
        this.fabricCanvas.remove(arrow);
      }
      arrow = this.createArrow(startX, startY, pointer.x, pointer.y);
      this.fabricCanvas.add(arrow);
      this.fabricCanvas.renderAll();
    });

    this.fabricCanvas.on('mouse:up', () => {
      // A click with no drag produced nothing at all, which reads as a broken tool.
      // Leave a short arrow pointing up-left at the spot instead.
      if (isDrawing && !arrow) {
        arrow = this.createArrow(startX - DEFAULT_ARROW_LENGTH, startY - DEFAULT_ARROW_LENGTH, startX, startY);
        this.fabricCanvas.add(arrow);
        this.fabricCanvas.renderAll();
      }
      isDrawing = false;
      arrow = null;
    });
  }

  createArrow(x1, y1, x2, y2) {
    const headLength = 15;
    const angle = Math.atan2(y2 - y1, x2 - x1);

    const line = new fabric.Line([x1, y1, x2, y2], {
      stroke: this.currentColor,
      strokeWidth: 3,
      selectable: false
    });

    const headX1 = x2 - headLength * Math.cos(angle - Math.PI / 6);
    const headY1 = y2 - headLength * Math.sin(angle - Math.PI / 6);
    const headX2 = x2 - headLength * Math.cos(angle + Math.PI / 6);
    const headY2 = y2 - headLength * Math.sin(angle + Math.PI / 6);

    const head = new fabric.Polygon([
      { x: x2, y: y2 },
      { x: headX1, y: headY1 },
      { x: headX2, y: headY2 }
    ], {
      fill: this.currentColor,
      selectable: false
    });

    return new fabric.Group([line, head], { selectable: false, evented: false });
  }

  setupTextTool() {
    this.fabricCanvas.selection = false;
    this.fabricCanvas.defaultCursor = 'text';

    // Same as the other shape tools: place text wherever you press.
    this.fabricCanvas.on('mouse:down', (opt) => {
      const pointer = this.fabricCanvas.getPointer(opt.e);

      const text = new fabric.IText('Type here', {
        left: pointer.x,
        top: pointer.y,
        fontSize: 20,
        fill: this.currentColor,
        fontFamily: 'Arial',
        selectable: true,
        editable: true
      });

      this.fabricCanvas.add(text);
      this.fabricCanvas.setActiveObject(text);
      text.enterEditing();
      text.selectAll();
      this.fabricCanvas.renderAll();

      // Switch to select mode after adding text
      setTimeout(() => {
        this.modal.querySelector('.tool-btn[data-tool="pen"]')?.classList.remove('active');
        this.setTool('select');
      }, 100);
    });
  }

  undo() {
    const objects = this.fabricCanvas?.getObjects();
    if (objects && objects.length > 0) {
      this.fabricCanvas.remove(objects[objects.length - 1]);
      this.fabricCanvas.renderAll();
    }
  }

  async getAnnotatedImage() {
    if (!this.fabricCanvas) return null;

    this.fabricCanvas.discardActiveObject();
    this.fabricCanvas.renderAll();

    const dataUrl = this.fabricCanvas.toDataURL({
      format: 'png',
      quality: 1
    });

    // Convert to blob
    const response = await fetch(dataUrl);
    const blob = await response.blob();

    return { blob, dataUrl };
  }

  // Hand the raw capture straight to the caller, skipping annotation.
  async attachWithoutAnnotation(imageData) {
    try {
      const blob = await (await fetch(imageData)).blob();
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);

      const callback = this.onAttachCallback;
      this.onAttachCallback = null;
      this.restoreFeedbackBubble();
      callback?.({
        filename: `screenshot-${timestamp}.png`,
        mime_type: 'image/png',
        dataUrl: imageData,
        blob,
        size: blob.size
      });
    } catch (err) {
      console.error('Screenshot annotator: failed to attach the raw capture', err);
      this.finishWithoutAttachment();
    }
  }

  // Drop the modal WITHOUT restoring the bubble or firing the callback — whoever
  // called this is taking over both.
  teardownModal() {
    if (this.fabricCanvas) {
      try { this.fabricCanvas.dispose(); } catch (_) { /* half-built canvas */ }
      this.fabricCanvas = null;
    }
    if (this.modal) {
      this.modal.remove();
      this.modal = null;
    }
  }

  async attachScreenshot() {
    try {
      // getAnnotatedImage() returns null when the canvas never came up. Destructuring
      // that threw a TypeError, so Attach alerted and the modal stayed on screen over
      // a hidden feedback panel — no way out but a reload, losing the typed draft.
      const annotated = await this.getAnnotatedImage();
      if (!annotated) {
        this.teardownModal();
        await this.attachWithoutAnnotation(this.originalImageData);
        return;
      }
      const { blob, dataUrl } = annotated;

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const filename = `screenshot-${timestamp}.png`;

      const callback = this.onAttachCallback;
      this.onAttachCallback = null;
      this.teardownModal();
      this.restoreFeedbackBubble();
      callback?.({
        filename,
        mime_type: 'image/png',
        dataUrl,
        blob,
        size: blob.size
      });
    } catch (err) {
      console.error('Failed to attach screenshot:', err);
      alert('Failed to attach screenshot. Please try again.');
      // The alert used to be the end of it: the modal stayed up over a hidden
      // feedback panel, so "try again" meant reloading and losing the draft.
      this.teardownModal();
      this.finishWithoutAttachment();
    }
  }

  closeModal() {
    this.teardownModal();
    this.finishWithoutAttachment();
  }
}

// Export singleton instance
window.screenshotAnnotator = new ScreenshotAnnotator();
