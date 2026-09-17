// Screenshot Annotator
// Captures page regions and allows annotation with Fabric.js

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
    this.showSelectionOverlay();
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
        this.restoreFeedbackBubble();
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
    this.restoreFeedbackBubble();
  }

  // Capture a region using native Screen Capture API (getDisplayMedia)
  async captureRegion(x, y, width, height) {
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

      // Wait a moment for the stream to be ready
      await new Promise(resolve => setTimeout(resolve, 100));

      // Use ImageCapture to grab a frame
      const imageCapture = new ImageCapture(track);
      const bitmap = await imageCapture.grabFrame();

      // Stop the stream
      track.stop();
      stream.getTracks().forEach(t => t.stop());

      // Draw the full capture to an offscreen canvas
      const fullCanvas = document.createElement('canvas');
      fullCanvas.width = bitmap.width;
      fullCanvas.height = bitmap.height;
      const fullCtx = fullCanvas.getContext('2d');
      fullCtx.drawImage(bitmap, 0, 0);

      // Calculate the scaling factor between captured image and viewport
      const scaleX = bitmap.width / window.innerWidth;
      const scaleY = bitmap.height / window.innerHeight;

      // Crop to the selected region
      const cropCanvas = document.createElement('canvas');
      cropCanvas.width = width * scaleX;
      cropCanvas.height = height * scaleY;
      const cropCtx = cropCanvas.getContext('2d');

      cropCtx.drawImage(
        fullCanvas,
        x * scaleX, y * scaleY, width * scaleX, height * scaleY,
        0, 0, cropCanvas.width, cropCanvas.height
      );

      return cropCanvas.toDataURL('image/png');
    } catch (err) {
      console.error('Screen capture failed:', err);

      // Fall back to html2canvas if getDisplayMedia fails
      console.log('Falling back to html2canvas...');
      const canvas = await html2canvas(document.body, {
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
  }

  restoreFeedbackBubble() {
    const feedbackBubble = document.getElementById('llamapress-feedback-bubble');
    if (feedbackBubble) feedbackBubble.style.display = '';
  }

  // Show the annotation modal
  showAnnotationModal(imageData) {
    this.originalImageData = imageData;

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
    img.onload = () => {
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
    }
  }

  setupRectangleTool() {
    let isDrawing = false;
    let startX, startY;
    let rect;

    this.fabricCanvas.selection = false;
    this.fabricCanvas.defaultCursor = 'crosshair';

    this.fabricCanvas.on('mouse:down', (opt) => {
      if (opt.target) return;
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
        selectable: true
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

    this.fabricCanvas.on('mouse:down', (opt) => {
      if (opt.target) return;
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

    return new fabric.Group([line, head], { selectable: true });
  }

  setupTextTool() {
    this.fabricCanvas.selection = false;
    this.fabricCanvas.defaultCursor = 'text';

    this.fabricCanvas.on('mouse:down', (opt) => {
      if (opt.target) return;
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

  async attachScreenshot() {
    try {
      const { blob, dataUrl } = await this.getAnnotatedImage();

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const filename = `screenshot-${timestamp}.png`;

      if (this.onAttachCallback) {
        this.onAttachCallback({
          filename,
          mime_type: 'image/png',
          dataUrl,
          blob,
          size: blob.size
        });
      }

      this.closeModal();
    } catch (err) {
      console.error('Failed to attach screenshot:', err);
      alert('Failed to attach screenshot. Please try again.');
    }
  }

  closeModal() {
    if (this.fabricCanvas) {
      this.fabricCanvas.dispose();
      this.fabricCanvas = null;
    }
    if (this.modal) {
      this.modal.remove();
      this.modal = null;
    }
    this.restoreFeedbackBubble();
  }
}

// Export singleton instance
window.screenshotAnnotator = new ScreenshotAnnotator();
