'use client';

import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { RTSWorkerManager } from '../lib/rts-worker';
import { type ProcessedStationData } from '../lib/rts';

interface RTSContextType {
  data: ProcessedStationData | null;
  isLoading: boolean;
  error: Error | null;
  lastUpdate: number;
  ntpTime: number;
}

const RTSContext = createContext<RTSContextType | undefined>(undefined);

export function RTSProvider({ children }: { children: React.ReactNode }) {
  const [data, setData] = useState<ProcessedStationData | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);
  const [lastUpdate, setLastUpdate] = useState<number>(0);
  const [ntpTime, setNtpTime] = useState<number>(0);
  const ntpOffsetRef = useRef<number>(0);
  const workerManagerRef = useRef<RTSWorkerManager | null>(null);
  const isMountedRef = useRef<boolean>(true);

  // Sync NTP time offset on mount and every 60 seconds
  useEffect(() => {
    const syncNtp = async () => {
      try {
        const beforeRequest = Date.now();
        const res = await fetch('https://lb.exptech.dev/ntp');
        const afterRequest = Date.now();
        const serverTime = parseInt(await res.text(), 10);
        const latency = (afterRequest - beforeRequest) / 2;
        ntpOffsetRef.current = serverTime - (beforeRequest + latency);
      } catch {
        ntpOffsetRef.current = 0;
      }
    };
    syncNtp();
    const ntpInterval = setInterval(syncNtp, 60000);
    return () => clearInterval(ntpInterval);
  }, []);

  useEffect(() => {
    isMountedRef.current = true;
    workerManagerRef.current = new RTSWorkerManager();

    const fetchData = async () => {
      if (!workerManagerRef.current || !isMountedRef.current) return;

      try {
        const newData = await workerManagerRef.current.fetchAndProcessStationData();
        if (isMountedRef.current) {
          setData(newData);
          setError(null);
        }
      } catch (err) {
        if (!isMountedRef.current) return;
        if (err instanceof Error && !err.message.includes('Data is older than existing data')) {
          setError(err);
        }
      } finally {
        if (isMountedRef.current) {
          setIsLoading(false);
          setLastUpdate(Date.now());
          setNtpTime(Date.now() + ntpOffsetRef.current);
        }
      }
    };

    fetchData();

    const interval = setInterval(fetchData, 1000);

    return () => {
      isMountedRef.current = false;
      clearInterval(interval);
      if (workerManagerRef.current) {
        workerManagerRef.current.destroy();
        workerManagerRef.current = null;
      }
    };
  }, []);

  return (
    <RTSContext.Provider value={{ data, isLoading, error, lastUpdate, ntpTime }}>
      {children}
    </RTSContext.Provider>
  );
}

export function useRTS() {
  const context = useContext(RTSContext);
  if (context === undefined) {
    throw new Error('useRTS must be used within a RTSProvider');
  }
  return context;
}
