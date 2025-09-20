import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prototypes--global"
export default class extends Controller {
  static targets = ["mobileMenu", "overlay", "panel", "fadeIn"]

  toggle() {
    this.mobileMenuTarget.classList.toggle("hidden")
    
    this.overlayTarget.classList.toggle("opacity-0")
    this.overlayTarget.classList.toggle("opacity-100")

    this.panelTarget.classList.toggle("-translate-x-full")
    this.panelTarget.classList.toggle("translate-x-0")
  }

  connect() {
    if (this.hasFadeInTarget) {
      // Initial state: invisible and slightly down
      this.fadeInTarget.classList.add("opacity-0", "translate-y-4");
      setTimeout(() => {
        this.fadeInTarget.classList.remove("opacity-0", "translate-y-4");
        this.fadeInTarget.classList.add("opacity-100", "translate-y-0", "transition", "duration-700");
      }, 20);
    }
  }

  confetti() {
    const canvas = document.getElementById("confettiCanvas");
    if (!canvas) return;
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    canvas.style.display = "block";
    const ctx = canvas.getContext("2d");
    const confettiCount = 120;
    const confettis = [];
    const colors = ["#FFC700","#FF0000","#2E3191","#41BBC7","#7DF57B","#FF62C6"];
    for (let i = 0; i < confettiCount; i++) {
      confettis.push({
        x: Math.random() * canvas.width,
        y: Math.random() * -canvas.height,
        r: 5 + Math.random() * 7,
        d: Math.random() * confettiCount + 10,
        color: colors[Math.floor(Math.random() * colors.length)],
        tilt: Math.floor(Math.random() * 10) - 10,
        tiltAngleIncremental: (Math.random() * 0.07) + .05,
        tiltAngle: 0
      });
    }
    let angle = 0;
    let tiltAngle = 0;
    function drawConfetti() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      confettis.forEach(c => {
        ctx.beginPath();
        ctx.lineWidth = c.r;
        ctx.strokeStyle = c.color;
        ctx.moveTo(c.x + c.tilt + (c.r/3), c.y);
        ctx.lineTo(c.x + c.tilt, c.y + c.tilt + (c.r/5));
        ctx.stroke();
      });
      updateConfetti();
    }
    function updateConfetti() {
      angle += 0.01;
      tiltAngle += 0.1;
      for(let i = 0; i < confettis.length; i++) {
        let c = confettis[i];
        c.y += (Math.cos(angle + c.d) + 3 + c.r/2) / 2;
        c.x += Math.sin(angle);
        c.tiltAngle += c.tiltAngleIncremental;
        c.tilt = Math.sin(c.tiltAngle) * 15;
        // Recycle confetti off bottom
        if (c.y > canvas.height) {
          confettis[i] = {
            ...c,
            x: Math.random() * canvas.width,
            y: -10,
            tilt: Math.floor(Math.random() * 10) - 10
          };
        }
      }
    }
    let frame = 0;
    function animate() {
      drawConfetti();
      frame++;
      if(frame < 85) {
        requestAnimationFrame(animate);
      } else {
        canvas.style.display = "none";
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    }
    animate();
  }
}