import { ProcessedStationData, StationInfo, RTSResponse, createStationGeoJSON } from './rts';

export interface WorkerMessage {
  type: string;
  data?: any;
  error?: string;
}

export class RTSWorkerManager {
  private worker: Worker | null = null;
  private messageHandlers: Map<string, (data: any) => void> = new Map();
  private errorHandlers: Map<string, (error: string) => void> = new Map();
  private replayTime = 0;
  private stationMapCache: Map<string, StationInfo> | null = null;
  private stationMapLastFetch = 0;
  private pendingRequests = new Map<string, AbortController>();

  constructor() {
    this.initWorker();
  }

  private initWorker() {
    if (typeof Worker !== 'undefined') {
      this.worker = new Worker('/rts-worker.js');
      
      this.worker.onmessage = (e) => {
        const { type, data, error } = e.data;
        
        if (error) {
          const errorHandler = this.errorHandlers.get(type);
          if (errorHandler) {
            errorHandler(error);
          }
        } else {
          const messageHandler = this.messageHandlers.get(type);
          if (messageHandler) {
            messageHandler(data);
          }
        }
      };

      this.worker.onerror = (error) => {
        console.error('Worker error:', error);
        this.errorHandlers.forEach((handler) => {
          handler(error.message || 'Unknown worker error');
        });
      };
    }
  }

  onMessage(type: string, handler: (data: any) => void) {
    this.messageHandlers.set(type, handler);
  }

  onError(type: string, handler: (error: string) => void) {
    this.errorHandlers.set(type, handler);
  }

  offMessage(type: string) {
    this.messageHandlers.delete(type);
  }

  offError(type: string) {
    this.errorHandlers.delete(type);
  }

  postMessage(type: string, data?: any) {
    if (this.worker) {
      this.worker.postMessage({ type, data });
    }
  }

  async fetchRTSData(timeout = 10000): Promise<RTSResponse> {
    return new Promise((resolve, reject) => {
      const requestId = `rts-${Date.now()}`;
      const abortController = new AbortController();

      const timeoutId = setTimeout(() => {
        cleanup();
        reject(new Error('Request timeout'));
      }, timeout);

      const cleanup = () => {
        clearTimeout(timeoutId);
        this.messageHandlers.delete('RTS_DATA_SUCCESS');
        this.errorHandlers.delete('DATA_ERROR');
        this.pendingRequests.delete(requestId);
      };

      const successHandler = (data: any) => {
        cleanup();
        resolve({
          time: data.time,
          station: data.station,
          int: data.int,
          box: data.box,
        });
      };

      const errorHandler = (error: string) => {
        cleanup();
        reject(new Error(error));
      };

      if (abortController.signal.aborted) {
        cleanup();
        reject(new Error('Request aborted'));
        return;
      }

      this.onMessage('RTS_DATA_SUCCESS', successHandler);
      this.onError('DATA_ERROR', errorHandler);
      this.pendingRequests.set(requestId, abortController);

      this.postMessage('FETCH_RTS_DATA', { replayTime: this.replayTime });

      if (this.replayTime !== 0) {
        this.replayTime += 1;
      }
    });
  }

  async fetchAndProcessStationData(): Promise<ProcessedStationData> {
    const [stationMap, rtsResponse] = await Promise.all([
      this.fetchStationInfo(),
      this.fetchRTSData(),
    ]);

    const geojson = createStationGeoJSON(stationMap, rtsResponse.station);

    return {
      geojson,
      time: rtsResponse.time,
      int: rtsResponse.int,
      box: rtsResponse.box,
    };
  }

  async fetchStationInfo(): Promise<Map<string, StationInfo>> {
    const now = Date.now();
    const shouldRefresh = !this.stationMapCache || (now - this.stationMapLastFetch) > 600000;

    if (shouldRefresh) {
      const response = await fetch('https://api-1.exptech.dev/api/v1/trem/station');
      const data = await response.json();

      if (this.stationMapCache) {
        this.stationMapCache.clear();
      }

      const stationMap = new Map<string, StationInfo>();

      for (const [uuid, station] of Object.entries(data)) {
        stationMap.set(uuid, station as StationInfo);
      }

      this.stationMapCache = stationMap;
      this.stationMapLastFetch = now;
    }

    return this.stationMapCache!;
  }

  setReplayTime(replayTime: number) {
    this.replayTime = replayTime;
  }

  abortPendingRequests() {
    this.pendingRequests.forEach((controller) => controller.abort());
    this.pendingRequests.clear();
  }

  destroy() {
    this.abortPendingRequests();

    if (this.worker) {
      this.worker.onmessage = null;
      this.worker.onerror = null;
      this.worker.terminate();
      this.worker = null;
    }

    this.messageHandlers.clear();
    this.errorHandlers.clear();

    if (this.stationMapCache) {
      this.stationMapCache.clear();
      this.stationMapCache = null;
    }
  }
}
