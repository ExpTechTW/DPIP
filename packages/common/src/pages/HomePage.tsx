'use client';
import { BaseMap } from '../components/map/base';
import { useState } from 'react';
import { Map } from 'maplibre-gl';

export default function HomePage() {
  const [map, setMap] = useState<Map | null>(null);
  return (
    <div className="h-full w-full">
      <BaseMap onMapLoaded={(map: Map) => setMap(map)} />
    </div>
  );
}
