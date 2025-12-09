'use client';

import { Github } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useState, useEffect } from 'react';
import { useElectronUpdater } from '@/hooks/useElectronUpdater';

export default function Footer() {
  const { currentVersion, openExternal, isElectron } = useElectronUpdater();
  const [version, setVersion] = useState('');

  useEffect(() => {
    if (currentVersion) {
      setVersion(currentVersion);
    } else {
      setVersion('1.0.0');
    }
  }, [currentVersion]);

  const handleGithubClick = async () => {
    try {
      await openExternal('https://github.com/ExpTechTW/eq-rts-map');
    } catch (error) {
      console.error('Failed to open URL:', error);
    }
  };

  return (
    <footer className="fixed bottom-3 left-3 z-50">
      <div className="bg-background/90 backdrop-blur-sm border border-border/50 rounded-md px-2.5 py-1.5 shadow-md flex items-center gap-2">
        <p className="text-[10px] text-muted-foreground font-medium">
          {version || '1.0.0'}
        </p>
        <div className="w-px h-3 bg-border/60" />
        <Button
          variant="ghost"
          size="icon"
          onClick={handleGithubClick}
          className="h-5 w-5 hover:bg-accent/50 transition-colors"
          title="GitHub Repository"
        >
          <Github className="h-2 w-2" />
        </Button>
      </div>
    </footer>
  );
}