'use client';

import React, { useRef, useState, useEffect } from 'react';
import { useRTS } from '@/contexts/RTSContext';

const AlertManager = React.memo(() => {
  const { data } = useRTS();
  const [hasAlert, setHasAlert] = useState<boolean>(false);
  const [previousHasAlert, setPreviousHasAlert] = useState<boolean>(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const isMountedRef = useRef<boolean>(true);

  useEffect(() => {
    isMountedRef.current = true;
    audioRef.current = new Audio('/audios/alarm.wav');

    return () => {
      isMountedRef.current = false;
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.src = '';
        audioRef.current.load();
        audioRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!isMountedRef.current) return;
    
    if (!data) {
      setPreviousHasAlert(hasAlert);
      setHasAlert(false);
      return;
    }

    const shouldAlert = data.box && Object.keys(data.box).length > 0;
    setPreviousHasAlert(hasAlert);
    setHasAlert(shouldAlert);
  }, [data, hasAlert]);

  useEffect(() => {
    if (!isMountedRef.current) return;
    
    if (!hasAlert) {
      audioRef.current?.pause();
      if (audioRef.current) {
        audioRef.current.currentTime = 0;
      }
      return;
    }

    const isFirstAlert = !previousHasAlert && hasAlert;
    
    const playAlarmAndFocus = () => {
      if (!isMountedRef.current || !audioRef.current) return;
      audioRef.current.play().catch(() => {});
      
      if (isFirstAlert && window.electronAPI) {
        (window.electronAPI as any).showWindow().catch(() => {});
      }
    };

    playAlarmAndFocus();
    const interval = setInterval(() => {
      if (!isMountedRef.current || !audioRef.current) return;
      audioRef.current.play().catch(() => {});
    }, 3000);

    return () => {
      clearInterval(interval);
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.currentTime = 0;
      }
    };
  }, [hasAlert, previousHasAlert]);

  return null;
});

AlertManager.displayName = 'AlertManager';

export default AlertManager;
