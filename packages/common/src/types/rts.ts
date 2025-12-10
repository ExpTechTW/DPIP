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
