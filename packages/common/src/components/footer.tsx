import packageJson from '../../package.json';

export function Footer() {
  return (
    <div className="fixed bottom-3 left-3 z-50">
      <div className="bg-black/70 backdrop-blur-md rounded-lg px-3 py-1.5 border border-white/10 shadow-lg">
        <span className="text-white/90 text-xs font-medium tracking-wide">v{packageJson.version}</span>
      </div>
    </div>
  );
}