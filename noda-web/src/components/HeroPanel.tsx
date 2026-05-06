import { Shield } from 'lucide-react';
import { StatusBar } from './StatusBar';

type HeroPanelProps = {
  eyebrow: string;
  titleTop: string;
  titleAccent: string;
  description: string;
};

export function HeroPanel({ eyebrow, titleTop, titleAccent, description }: HeroPanelProps) {
  return (
    <section className="hero-panel">
      <Logo />

      <div className="hero-copy">
        <div className="eyebrow">
          <span />
          {eyebrow}
        </div>
        <h1>
          <span>{titleTop}</span>
          <em>{titleAccent}</em>
        </h1>
        <p>{description}</p>
      </div>

      <StatusBar />
    </section>
  );
}

function Logo() {
  return (
    <div className="logo" aria-label="noda">
      <span className="logo-mark"><Shield size={17} /></span>
      <span className="logo-text">noda.</span>
    </div>
  );
}
