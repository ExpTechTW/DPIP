'use client';

import React from 'react';
import MapSection from '@/components/MapSection';
import ChartSection from '@/components/ChartSection';
import AlertManager from '@/components/AlertManager';
import { RTSProvider } from '@/contexts/RTSContext';

export default function Home() {
  return (
    <RTSProvider>
      <div className="flex h-screen w-full">
        <AlertManager />
        <MapSection />
        <ChartSection />
      </div>
    </RTSProvider>
  );
}