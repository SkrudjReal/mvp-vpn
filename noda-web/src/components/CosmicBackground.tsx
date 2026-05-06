import { useEffect, useRef } from 'react';

type Star = { x: number; y: number; r: number; tw: number; ts: number };
type Comet = { x: number; y: number; vx: number; vy: number; life: number; maxLife: number; len: number };

export function CosmicBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const targetCanvas: HTMLCanvasElement = canvas;
    const context = canvas.getContext('2d');
    if (!context) return;
    const ctx = context;

    let width = 0;
    let height = 0;
    let dpr = Math.min(window.devicePixelRatio || 1, 2);
    let stars: Star[] = [];
    const comets: Comet[] = [];
    let frameId = 0;
    let lastComet = 0;

    function resize() {
      width = targetCanvas.clientWidth;
      height = targetCanvas.clientHeight;
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      targetCanvas.width = Math.floor(width * dpr);
      targetCanvas.height = Math.floor(height * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      const density = Math.floor((width * height) / 8500);
      stars = Array.from({ length: density }, () => ({
        x: Math.random() * width,
        y: Math.random() * height,
        r: Math.random() * 1.1 + 0.2,
        tw: Math.random() * Math.PI * 2,
        ts: 0.35 + Math.random() * 1.1,
      }));
    }

    function spawnComet() {
      const fromLeft = Math.random() < 0.5;
      const startY = Math.random() * height * 0.58;
      const startX = fromLeft ? -70 : width + 70;
      const angle = (Math.random() * 0.2 + 0.16) * (fromLeft ? 1 : -1);
      const speed = 3.7 + Math.random() * 2.2;
      comets.push({
        x: startX,
        y: startY,
        vx: Math.cos(angle) * speed * (fromLeft ? 1 : -1),
        vy: Math.sin(angle) * speed,
        life: 0,
        maxLife: 120 + Math.random() * 70,
        len: 110 + Math.random() * 100,
      });
    }

    function render(time: number) {
      ctx.clearRect(0, 0, width, height);

      for (const star of stars) {
        star.tw += 0.02 * star.ts;
        const alpha = 0.18 + (Math.sin(star.tw) * 0.5 + 0.5) * 0.42;
        ctx.beginPath();
        ctx.arc(star.x, star.y, star.r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(210,246,255,${alpha})`;
        ctx.fill();
      }

      if (time - lastComet > 2300 + Math.random() * 2600 && comets.length < 2) {
        spawnComet();
        lastComet = time;
      }

      for (let index = comets.length - 1; index >= 0; index -= 1) {
        const comet = comets[index];
        comet.x += comet.vx;
        comet.y += comet.vy;
        comet.life += 1;

        const length = Math.hypot(comet.vx, comet.vy);
        const tailX = comet.x - (comet.vx / length) * comet.len;
        const tailY = comet.y - (comet.vy / length) * comet.len;
        const life = 1 - comet.life / comet.maxLife;

        const gradient = ctx.createLinearGradient(comet.x, comet.y, tailX, tailY);
        gradient.addColorStop(0, `rgba(80,232,255,${0.9 * life})`);
        gradient.addColorStop(0.38, `rgba(0,212,255,${0.45 * life})`);
        gradient.addColorStop(1, 'rgba(0,212,255,0)');

        ctx.strokeStyle = gradient;
        ctx.lineWidth = 1.5;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(comet.x, comet.y);
        ctx.lineTo(tailX, tailY);
        ctx.stroke();

        if (comet.life >= comet.maxLife || comet.x < -220 || comet.x > width + 220 || comet.y > height + 220) {
          comets.splice(index, 1);
        }
      }

      frameId = requestAnimationFrame(render);
    }

    resize();
    window.addEventListener('resize', resize);
    frameId = requestAnimationFrame(render);

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener('resize', resize);
    };
  }, []);

  return (
    <div className="cosmic-background" aria-hidden>
      <div className="gradient-layer" />
      <div className="grid-layer" />
      <canvas ref={canvasRef} />
      <div className="vignette-layer" />
    </div>
  );
}
