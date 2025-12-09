export interface StationInfo {
  net: string;
  info: Array<{ code: number; lat: number; lon: number; time: string }>;
  work: boolean;
}

export interface RTSData {
  pga: number;
  pgv: number;
  i: number;
  I: number;
  alert?: number;
}

export interface RTSResponse {
  time: number;
  station: Record<string, RTSData>;
  int: any[];
  box: Record<string, any>;
}

export interface StationFeature {
  type: 'Feature';
  geometry: { type: 'Point'; coordinates: [number, number] };
  properties: {
    id: string;
    code: string;
    intensity: number;
    color: string;
    sortKey: number;
    hasAlert?: boolean;
    pga?: number;
    isConnected?: boolean;
  };
}

export interface StationGeoJSON {
  type: 'FeatureCollection';
  features: StationFeature[];
}

export interface ProcessedStationData {
  geojson: StationGeoJSON;
  time: number;
  int: any[];
  box: Record<string, any>;
}

const COLOR_STOPS = [
  { v: -3, c: '#0005d0' }, { v: -2, c: '#004bf8' }, { v: -1, c: '#009EF8' },
  { v: 0, c: '#79E5FD' }, { v: 1, c: '#49E9AD' }, { v: 2, c: '#44fa34' },
  { v: 3, c: '#beff0c' }, { v: 4, c: '#fff000' }, { v: 5, c: '#ff9300' },
  { v: 6, c: '#fc5235' }, { v: 7, c: '#b720e9' },
];

const hexToRgb = (hex: string): [number, number, number] => [
  parseInt(hex.slice(1, 3), 16),
  parseInt(hex.slice(3, 5), 16),
  parseInt(hex.slice(5, 7), 16),
];

const rgbToHex = (r: number, g: number, b: number): string =>
  '#' + [r, g, b].map(x => Math.round(x).toString(16).padStart(2, '0')).join('');

export function getIntensityColor(intensity: number): string {
  if (intensity <= COLOR_STOPS[0].v) return COLOR_STOPS[0].c;
  if (intensity >= COLOR_STOPS[COLOR_STOPS.length - 1].v) return COLOR_STOPS[COLOR_STOPS.length - 1].c;

  for (let i = 0; i < COLOR_STOPS.length - 1; i++) {
    const s1 = COLOR_STOPS[i], s2 = COLOR_STOPS[i + 1];
    if (intensity >= s1.v && intensity <= s2.v) {
      const t = (intensity - s1.v) / (s2.v - s1.v);
      const [r1, g1, b1] = hexToRgb(s1.c);
      const [r2, g2, b2] = hexToRgb(s2.c);
      return rgbToHex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t);
    }
  }
  return COLOR_STOPS[0].c;
}

const featurePool: StationFeature[] = [];
const reusableGeoJSON: StationGeoJSON = { type: 'FeatureCollection', features: [] };

function getFeature(index: number): StationFeature {
  if (index < featurePool.length) return featurePool[index];
  const f: StationFeature = {
    type: 'Feature',
    geometry: { type: 'Point', coordinates: [0, 0] },
    properties: { id: '', code: '', intensity: 0, color: '', sortKey: 0, hasAlert: false, pga: 0 },
  };
  featurePool.push(f);
  return f;
}

export function createStationGeoJSON(
  stationMap: Map<string, StationInfo>,
  rtsData: Record<string, RTSData>
): StationGeoJSON {
  let idx = 0;
  for (const [id, rts] of Object.entries(rtsData)) {
    const station = stationMap.get(id);
    if (!station?.work || !station.info.length) continue;

    const info = station.info[station.info.length - 1];
    const intensity = rts.alert ? rts.I : rts.i;
    const f = getFeature(idx++);
    f.geometry.coordinates[0] = info.lon;
    f.geometry.coordinates[1] = info.lat;
    f.properties.id = id;
    f.properties.code = info.code.toString();
    f.properties.intensity = intensity;
    f.properties.color = getIntensityColor(intensity);
    f.properties.sortKey = intensity;
    f.properties.hasAlert = rts.alert != undefined;
    f.properties.pga = rts.pga || 0;
  }
  reusableGeoJSON.features = featurePool.slice(0, idx);
  return reusableGeoJSON;
}
