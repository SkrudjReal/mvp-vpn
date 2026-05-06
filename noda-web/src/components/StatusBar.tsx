export function StatusBar() {
  return (
    <div className="status-bar">
      <div className="status-lines">
        <span>tunnel · <em>idle</em></span>
        <span>nl-amst-04 · 12.4ms</span>
        <strong>reality · tcp</strong>
      </div>
      <div className="signal-bars" aria-hidden>
        {[6, 9, 12, 16].map((height) => (
          <i key={height} style={{ height }} />
        ))}
      </div>
    </div>
  );
}
