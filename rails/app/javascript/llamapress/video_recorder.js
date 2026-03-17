// Video Recorder for Feedback Bubble
// Captures screen with microphone audio using MediaRecorder API

class VideoRecorder {
  constructor() {
    this.mediaRecorder = null;
    this.recordedChunks = [];
    this.stream = null;
    this.displayStream = null;
    this.micStream = null;
    this.isRecording = false;
    this.startTime = null;
    this.timerInterval = null;
    this.onStopCallback = null;
  }

  /**
   * Start screen recording with optional microphone audio
   * @param {Function} onTimerUpdate - Callback with formatted time string (MM:SS)
   * @param {Function} onStop - Callback when recording stops
   */
  async startRecording(onTimerUpdate, onStop) {
    // Request screen capture (720p @ 15fps)
    // Simplified options: prefer current tab, hide other options when possible
    const displayConstraints = {
      audio: false,
      video: {
        width: { ideal: 1280, max: 1280 },
        height: { ideal: 720, max: 720 },
        frameRate: { ideal: 15 },
        displaySurface: 'browser'  // Prefer browser tab over window/monitor
      },
      preferCurrentTab: true,      // Chrome 94+: prefer current tab
      selfBrowserSurface: 'include', // Include current tab in options
      surfaceSwitching: 'exclude', // Hide "share this tab instead" button during recording
      monitorTypeSurfaces: 'exclude' // Hide monitor/screen options, show only tabs/windows
    };

    const displayStream = await navigator.mediaDevices.getDisplayMedia(displayConstraints);

    // Request microphone audio (graceful fallback if denied)
    let micStream = null;
    try {
      micStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
    } catch (err) {
      console.warn('[VideoRecorder] Microphone access denied, recording without audio:', err.message);
    }

    // Combine streams
    const tracks = [...displayStream.getVideoTracks()];
    if (micStream) {
      tracks.push(...micStream.getAudioTracks());
    }

    this.stream = new MediaStream(tracks);
    this.displayStream = displayStream;
    this.micStream = micStream;
    this.onStopCallback = onStop;

    const options = {
      mimeType: 'video/webm; codecs=vp9',
      videoBitsPerSecond: 1000000 // 1 Mbps
    };

    this.mediaRecorder = new MediaRecorder(this.stream, options);
    this.recordedChunks = [];

    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) {
        this.recordedChunks.push(e.data);
      }
    };

    // Start timer
    this.startTime = Date.now();
    this.timerInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
      const mins = String(Math.floor(elapsed / 60)).padStart(2, '0');
      const secs = String(elapsed % 60).padStart(2, '0');
      if (onTimerUpdate) {
        onTimerUpdate(`${mins}:${secs}`);
      }
    }, 1000);

    this.mediaRecorder.start();
    this.isRecording = true;

    // Handle stream ending (user clicks "Stop sharing" in browser UI)
    this.displayStream.getVideoTracks().forEach(track => {
      track.onended = () => {
        this.stopRecording();
      };
    });
  }

  /**
   * Stop recording and return the blob
   * @returns {Promise<Blob|null>} The recorded video blob
   */
  stopRecording() {
    return new Promise((resolve) => {
      if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
        this.isRecording = false;
        resolve(null);
        return;
      }

      clearInterval(this.timerInterval);
      this.timerInterval = null;

      this.mediaRecorder.onstop = () => {
        const blob = new Blob(this.recordedChunks, { type: 'video/webm' });

        // Stop all streams
        this.stream?.getTracks().forEach(t => t.stop());
        this.displayStream?.getTracks().forEach(t => t.stop());
        this.micStream?.getTracks().forEach(t => t.stop());

        this.isRecording = false;
        this.recordedChunks = [];
        this.displayStream = null;
        this.micStream = null;

        if (this.onStopCallback) {
          this.onStopCallback(blob);
        }

        resolve(blob);
      };

      this.mediaRecorder.stop();
    });
  }

  /**
   * Show preview modal with video playback and attach/cancel options
   * @param {Blob} blob - The recorded video blob
   * @param {Function} onAttach - Callback when user clicks Attach
   * @param {Function} onCancel - Callback when user cancels (optional)
   */
  showPreviewModal(blob, onAttach, onCancel) {
    if (!blob) return;

    const videoUrl = URL.createObjectURL(blob);

    // Create modal
    const modal = document.createElement('div');
    modal.id = 'video-preview-modal';
    modal.innerHTML = `
      <div class="video-preview-backdrop">
        <div class="video-preview-content">
          <h3 class="video-preview-title">Recording Preview</h3>
          <video controls autoplay class="video-preview-player"></video>
          <div class="video-preview-actions">
            <button class="video-preview-cancel">Cancel</button>
            <button class="video-preview-attach">Attach to Feedback</button>
          </div>
        </div>
      </div>
    `;

    // Add styles
    const style = document.createElement('style');
    style.textContent = `
      #video-preview-modal .video-preview-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.85);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 100003;
        animation: videoModalFadeIn 0.2s ease-out;
      }
      @keyframes videoModalFadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      #video-preview-modal .video-preview-content {
        background: #1a1a1a;
        border-radius: 12px;
        max-width: 90vw;
        max-height: 90vh;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        border: 1px solid #333;
        animation: videoModalSlideUp 0.2s ease-out;
      }
      @keyframes videoModalSlideUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
      }
      #video-preview-modal .video-preview-title {
        color: white;
        font-weight: 500;
        font-size: 16px;
        padding: 12px 16px;
        margin: 0;
        border-bottom: 1px solid #333;
      }
      #video-preview-modal .video-preview-player {
        max-width: 100%;
        max-height: 60vh;
        background: #000;
      }
      #video-preview-modal .video-preview-actions {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        padding: 12px 16px;
        border-top: 1px solid #333;
      }
      #video-preview-modal .video-preview-cancel {
        padding: 8px 16px;
        background: #333;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
      }
      #video-preview-modal .video-preview-cancel:hover {
        background: #444;
      }
      #video-preview-modal .video-preview-attach {
        padding: 8px 16px;
        background: #8b5cf6;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 500;
      }
      #video-preview-modal .video-preview-attach:hover {
        background: #7c3aed;
      }
    `;
    modal.appendChild(style);

    // Set video src
    const video = modal.querySelector('video');
    video.src = videoUrl;

    // Attach handler
    modal.querySelector('.video-preview-attach').addEventListener('click', () => {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const filename = `recording-${timestamp}.webm`;

      if (onAttach) {
        onAttach({
          filename,
          mime_type: 'video/webm',
          blob,
          size: blob.size
        });
      }

      URL.revokeObjectURL(videoUrl);
      modal.remove();
    });

    // Cancel handler
    modal.querySelector('.video-preview-cancel').addEventListener('click', () => {
      URL.revokeObjectURL(videoUrl);
      modal.remove();
      if (onCancel) onCancel();
    });

    // Close on backdrop click
    modal.querySelector('.video-preview-backdrop').addEventListener('click', (e) => {
      if (e.target === e.currentTarget) {
        URL.revokeObjectURL(videoUrl);
        modal.remove();
        if (onCancel) onCancel();
      }
    });

    document.body.appendChild(modal);
  }
}

// Export singleton instance
window.videoRecorder = new VideoRecorder();
