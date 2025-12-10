'use client';

import { useEffect, useRef, useCallback, useState } from 'react';
import { Map, GeoJSONSource } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { useRTS } from '../../contexts/RTSContext';
import type { StationGeoJSON } from '../../lib/rts';
import regionData from '../../data/region.json';
import boxDataRaw from '../../data/box.json';

const CORNER_POSITIONS = [
  { id: 'top-left', position: [119.7, 25.4] as [number, number] },
  { id: 'top-right', position: [122.2, 23.6] as [number, number] },
  { id: 'bottom-left', position: [119.7, 22] as [number, number] },
  { id: 'bottom-right', position: [121.6, 22] as [number, number] },
];

const TOOLTIP_OFFSETS: Record<string, { x: number; y: number }> = {
  'top-left': { x: -60, y: -35 },
  'top-right': { x: -70, y: -30 },
  'bottom-left': { x: -60, y: -45 },
  'bottom-right': { x: -50, y: -45 },
};

const INTENSITY_COLORS: Record<number, string> = {
  0: '#202020', 1: '#003264', 2: '#0064c8', 3: '#1e9632', 4: '#ffc800',
  5: '#ff9600', 6: '#ff6400', 7: '#ff0000', 8: '#c00000', 9: '#9600c8',
};

const INTENSITY_TEXT_COLORS: Record<number, string> = {
  0: '#fff', 1: '#fff', 2: '#fff', 3: '#fff', 4: '#000',
  5: '#000', 6: '#000', 7: '#fff', 8: '#fff', 9: '#fff',
};

const INTENSITY_LABELS = ['0', '1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7'];

interface AlertTooltip {
  stationId: string;
  stationCode: string;
  intensity: number;
  coordinates: [number, number];
  tooltipPosition: [number, number];
  cornerId: string;
}

interface BoxFeature {
  type: 'Feature';
  geometry: { type: 'Polygon'; coordinates: number[][][] };
  properties: { ID: number; intensity?: number; sortKey?: number };
}

const boxData = boxDataRaw as { type: 'FeatureCollection'; features: BoxFeature[] };

const regionNameCache: Record<string, string> = {};
const getRegionName = (code: string): string => {
  if (regionNameCache[code]) return regionNameCache[code];
  const codeNum = parseInt(code);
  for (const [city, towns] of Object.entries(regionData)) {
    for (const [town, info] of Object.entries(towns as Record<string, { code: number }>)) {
      if (info.code === codeNum) {
        regionNameCache[code] = `${city}${town}`;
        return regionNameCache[code];
      }
    }
  }
  regionNameCache[code] = code;
  return code;
};

const intensityToInt = (f: number): number =>
  f < 0 ? 0 : f < 4.5 ? Math.round(f) : f < 5 ? 5 : f < 5.5 ? 6 : f < 6 ? 7 : f < 6.5 ? 8 : 9;

const reusableBoxGeoJSON = { type: 'FeatureCollection' as const, features: [] as any[] };
const reusableLineGeoJSON = { type: 'FeatureCollection' as const, features: [] as any[] };

export function BaseMap({ onMapLoaded, onCleanup }: { onMapLoaded?: (map: Map) => void; onCleanup?: () => void }) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<Map | null>(null);
  const sourceInitializedRef = useRef(false);
  const connectedStationsRef = useRef(new Set<string>());

  const { data: rtsData, lastUpdate, ntpTime } = useRTS();

  const [dataTime, setDataTime] = useState(0);
  const [displayTime, setDisplayTime] = useState(0);
  const [maxIntensity, setMaxIntensity] = useState(-3);
  const [isMapReady, setIsMapReady] = useState(false);
  const [boxVisible, setBoxVisible] = useState(true);
  const [tooltipSwitchIndex, setTooltipSwitchIndex] = useState(0);
  const [tooltips, setTooltips] = useState<AlertTooltip[]>([]);
  const [alertStations, setAlertStations] = useState<AlertTooltip[]>([]);
  const [isStale, setIsStale] = useState(false);
  const lastReceivedTimeRef = useRef(0);

  const formatTime = (ts: number) => {
    if (!ts) return '';
    const d = new Date(ts);
    return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, '0')}/${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`;
  };

  const updateBoxGeoJSON = useCallback(() => {
    if (!rtsData?.box) return null;
    reusableBoxGeoJSON.features.length = 0;
    for (const feature of boxData.features) {
      const intensity = rtsData.box[feature.properties.ID];
      if (intensity !== undefined) {
        feature.properties.intensity = intensity;
        feature.properties.sortKey = intensity;
        reusableBoxGeoJSON.features.push(feature);
      }
    }
    return reusableBoxGeoJSON;
  }, [rtsData?.box]);

  const assignTooltipPositions = useCallback((stations: AlertTooltip[]): AlertTooltip[] => {
    if (stations.length === 0) return [];
    return stations
      .slice()
      .sort((a, b) => b.intensity - a.intensity)
      .slice(0, 4)
      .map((s, i) => ({ ...s, tooltipPosition: CORNER_POSITIONS[i].position, cornerId: CORNER_POSITIONS[i].id }));
  }, []);

  const initializeMapSource = useCallback((map: Map, geojson: StationGeoJSON) => {
    if (sourceInitializedRef.current) return;
    if (map.getSource('stations')) return;

    map.addSource('stations', { type: 'geojson', data: geojson });
    map.addSource('tooltip-lines', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
    map.addSource('boxes', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });

    map.addLayer({
      id: 'box-outlines', type: 'line', source: 'boxes',
      layout: { 'line-sort-key': ['get', 'sortKey'] },
      paint: {
        'line-color': ['case', ['<', ['get', 'intensity'], 2], '#00DB00', ['<', ['get', 'intensity'], 4], '#EAC100', '#FF0000'],
        'line-width': 2,
      },
    });
    map.addLayer({
      id: 'tooltip-lines', type: 'line', source: 'tooltip-lines',
      paint: { 'line-color': '#ffffff', 'line-width': 1, 'line-opacity': 0.8 },
    });
    map.addLayer({
      id: 'station-circles', type: 'circle', source: 'stations',
      layout: { 'circle-sort-key': ['get', 'sortKey'] },
      paint: {
        'circle-radius': 4, 'circle-color': ['get', 'color'],
        'circle-stroke-width': ['case', ['get', 'isConnected'], 3, 1], 'circle-stroke-color': '#ffffff',
      },
    });
    sourceInitializedRef.current = true;
  }, []);

  const updateStationSource = useCallback(() => {
    if (!mapRef.current || !sourceInitializedRef.current || !rtsData?.geojson) return;
    const source = mapRef.current.getSource('stations') as GeoJSONSource;
    if (!source?.setData) return;
    const ids = connectedStationsRef.current;
    for (const f of rtsData.geojson.features) f.properties.isConnected = ids.has(f.properties.id);
    source.setData(rtsData.geojson);
  }, [rtsData?.geojson]);

  const updateBoxSource = useCallback(() => {
    if (!mapRef.current || !sourceInitializedRef.current) return;
    const source = mapRef.current.getSource('boxes') as GeoJSONSource;
    const data = updateBoxGeoJSON();
    if (source?.setData && data) source.setData(data);
  }, [updateBoxGeoJSON]);

  const updateTooltipLines = useCallback((items: AlertTooltip[]) => {
    if (!mapRef.current || !sourceInitializedRef.current) return;
    const source = mapRef.current.getSource('tooltip-lines') as GeoJSONSource;
    if (!source?.setData) return;
    reusableLineGeoJSON.features.length = 0;
    for (const t of items) {
      reusableLineGeoJSON.features.push({
        type: 'Feature',
        geometry: { type: 'LineString', coordinates: [t.coordinates, t.tooltipPosition] },
        properties: { stationId: t.stationId, cornerId: t.cornerId },
      });
    }
    source.setData(reusableLineGeoJSON);
  }, []);

  useEffect(() => {
    if (mapContainerRef.current === null) return;

    const map = new Map({
      container: mapContainerRef.current,
      style: {
        version: 8,
        name: 'ExpTech Studio',
        sources: {
          map: {
            type: 'vector',
            url: 'https://lb.exptech.dev/api/v1/map/tiles/tiles.json',
          },
        },
        sprite: '',
        glyphs: 'https://glyphs.geolonia.com/{fontstack}/{range}.pbf',
        layers: [
          { id: 'background', type: 'background', paint: { 'background-color': '#1f2025' } },
          { id: 'county', type: 'fill', source: 'map', 'source-layer': 'city', paint: { 'fill-color': '#3F4045' } },
          { id: 'county-outline', type: 'line', source: 'map', 'source-layer': 'city', paint: { 'line-color': '#a9b4bc' } },
          { id: 'town', type: 'fill', source: 'map', 'source-layer': 'town', paint: { 'fill-color': 'transparent' } },
        ],
      },
      center: [121.6, 23.5],
      zoom: 6.8,
      attributionControl: false,
      pitchWithRotate: false,
      dragRotate: false,
      maxZoom: 12,
      minZoom: 4,
    });

    mapRef.current = map;

    const MAP_BOUNDS = [[118.0, 21.2], [124.0, 25.8]] as [[number, number], [number, number]];
    void map.fitBounds(MAP_BOUNDS, { padding: 20, duration: 0 });

    map.on('load', () => {
      setIsMapReady(true);
      if (onMapLoaded) onMapLoaded(map);
    });

    map.on('error', () => void 0);

    return () => {
      sourceInitializedRef.current = false;
      connectedStationsRef.current.clear();
      if (onCleanup) onCleanup();
      map.remove();
    };
  }, []);

  // Check stale status and update display time (triggered by RTSContext's 1s interval)
  useEffect(() => {
    if (lastUpdate === 0) return;
    const now = Date.now();
    const stale = lastReceivedTimeRef.current > 0 && now - lastReceivedTimeRef.current > 3000;
    setIsStale(stale);
    // If stale, show last rts.time; otherwise show NTP time
    setDisplayTime(stale ? dataTime : ntpTime);
  }, [lastUpdate, ntpTime, dataTime]);

  // Process RTS data when it updates
  useEffect(() => {
    if (!rtsData) return;
    setDataTime(rtsData.time);
    lastReceivedTimeRef.current = Date.now();
    setIsStale(false);
    let max = -3;
    const alerts: AlertTooltip[] = [];
    for (const f of rtsData.geojson.features) {
      if (f.properties.intensity > max) max = f.properties.intensity;
      if (f.properties.hasAlert) {
        alerts.push({
          stationId: f.properties.id, stationCode: f.properties.code, intensity: f.properties.intensity,
          coordinates: f.geometry.coordinates, tooltipPosition: [0, 0], cornerId: '',
        });
      }
    }
    setMaxIntensity(max);
    setAlertStations(alerts);
  }, [rtsData]);

  // Update tooltip positions
  useEffect(() => {
    connectedStationsRef.current.clear();
    if (alertStations.length === 0) { setTooltips([]); return; }
    const positioned = assignTooltipPositions(alertStations);
    setTooltips(positioned);
    for (const t of positioned) connectedStationsRef.current.add(t.stationId);
  }, [alertStations, tooltipSwitchIndex, assignTooltipPositions]);

  // Update map sources when data changes
  useEffect(() => {
    if (!rtsData || !isMapReady || !sourceInitializedRef.current) return;
    updateStationSource();
    updateTooltipLines(tooltips);
  }, [rtsData, tooltips, isMapReady, updateStationSource, updateTooltipLines]);

  // Initialize map sources
  useEffect(() => {
    if (isMapReady && rtsData?.geojson && mapRef.current) {
      initializeMapSource(mapRef.current, rtsData.geojson);
    }
  }, [isMapReady, rtsData?.geojson, initializeMapSource]);

  // Tooltip switch interval
  useEffect(() => {
    const id = setInterval(() => setTooltipSwitchIndex(p => p + 1), 3000);
    return () => clearInterval(id);
  }, []);

  // Box visibility toggle
  useEffect(() => {
    const id = setInterval(() => setBoxVisible(p => !p), 1000);
    return () => clearInterval(id);
  }, []);

  // Update box visibility
  useEffect(() => {
    if (!mapRef.current || !sourceInitializedRef.current) return;
    const map = mapRef.current;
    if (map.getLayer('box-outlines')) map.setLayoutProperty('box-outlines', 'visibility', boxVisible ? 'visible' : 'none');
  }, [boxVisible]);

  // Update box source
  useEffect(() => {
    if (rtsData && isMapReady && sourceInitializedRef.current) updateBoxSource();
  }, [rtsData, isMapReady, updateBoxSource]);

  return (
    <div className="h-full w-full relative">
      <div ref={mapContainerRef} className="h-full w-full outline-none" />

      {/* Alert tooltips */}
      {tooltips.map((t) => {
        if (!mapRef.current) return null;
        const pixel = mapRef.current.project(t.tooltipPosition);
        const offset = TOOLTIP_OFFSETS[t.cornerId];
        const container = mapContainerRef.current;
        if (!container) return null;
        const left = Math.max(5, Math.min(container.offsetWidth - 95, pixel.x + offset.x));
        const top = Math.max(5, Math.min(container.offsetHeight - 75, pixel.y + offset.y));
        const int = intensityToInt(t.intensity);

        return (
          <div key={`${t.stationId}-${t.cornerId}`} className="absolute z-50 pointer-events-none" style={{ left, top }}>
            <div className="bg-gradient-to-br from-slate-900/98 to-gray-800/98 backdrop-blur-lg rounded-[5px] p-2 border border-white/30 min-w-[90px] shadow-lg">
              <div className="text-white text-xs font-medium mb-1.5">{getRegionName(t.stationCode)}</div>
              <div className="flex items-center gap-1">
                <span className="text-white/70 text-xs">震度</span>
                <span className="rounded px-1.5 py-0.5 text-xs font-bold" style={{ backgroundColor: INTENSITY_COLORS[int], color: INTENSITY_TEXT_COLORS[int] }}>
                  {INTENSITY_LABELS[int]}
                </span>
              </div>
            </div>
          </div>
        );
      })}

      {/* Intensity legend and time display */}
      {displayTime > 0 && (
        <div className="absolute bottom-3 right-3 z-50 flex flex-col gap-2 items-end">
          <div className="backdrop-blur-sm rounded-md p-2">
            <div className="flex items-start gap-1.5">
              <div className="flex flex-col text-[9px] text-white/90 font-medium text-right" style={{ height: 180, justifyContent: 'space-between' }}>
                {[7,6,5,4,3,2,1,0,-1,-2,-3].map(n => <span key={n} style={{ lineHeight: '9px' }}>{n}</span>)}
              </div>
              <div className="relative" style={{ height: 180 }}>
                <div className="w-1.5 h-full rounded-full" style={{
                  background: 'linear-gradient(180deg, #b720e9 0%, #fc5235 10%, #ff9300 20%, #fff000 30%, #beff0c 40%, #44fa34 50%, #49E9AD 60%, #79E5FD 70%, #009EF8 80%, #004bf8 90%, #0005d0 100%)',
                  boxShadow: '0 0 4px rgba(0,0,0,0.3)'
                }} />
                <div className="absolute -right-3 text-white text-[10px] transition-all duration-300" style={{
                  top: `${((7 - maxIntensity) / 10) * 100}%`, transform: 'translateY(-50%)', filter: 'drop-shadow(0 1px 2px rgba(0,0,0,0.8))'
                }}>◀</div>
              </div>
            </div>
          </div>
          <div className="bg-black/70 backdrop-blur-md rounded-lg px-3 py-1.5 border border-white/10 shadow-lg flex items-center gap-1.5">
            <div className={`w-2 h-2 rounded-full animate-pulse ${isStale ? 'bg-red-500' : 'bg-emerald-400'}`} />
            <span className="text-white/90 text-xs font-medium tracking-wide">{formatTime(displayTime)}</span>
          </div>
        </div>
      )}
    </div>
  );
}
