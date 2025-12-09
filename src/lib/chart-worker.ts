export interface ChartWorkerMessage {
  type: string;
  data?: any;
  error?: string;
}

export interface ChartData {
  labels: string[];
  datasets: any[];
}

export interface ChannelConfig {
  baseline: number;
  color: string;
}

export class ChartWorkerManager {
  private worker: Worker | null = null;
  private messageHandlers: Map<string, (data: any) => void> = new Map();
  private errorHandlers: Map<string, (error: string) => void> = new Map();

  constructor() {
    this.initWorker();
  }

  private initWorker() {
    if (typeof Worker !== 'undefined') {
      this.worker = new Worker('/chart-worker.js');
      
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
        console.error('Chart Worker error:', error);
        this.errorHandlers.forEach((handler) => {
          handler(error.message || 'Unknown chart worker error');
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

  postMessage(type: string, data?: any) {
    if (this.worker) {
      this.worker.postMessage({ type, data });
    }
  }

  processChartData(waveformData: Record<number, (number | null)[]>, stationConfigs: Record<number, { sampleRate: number; dataLength: number; scale: number }>): Promise<ChartData> {
    return new Promise((resolve, reject) => {
      const successHandler = (data: ChartData) => {
        this.messageHandlers.delete('CHART_DATA_SUCCESS');
        this.errorHandlers.delete('ERROR');
        resolve(data);
      };

      const errorHandler = (error: string) => {
        this.messageHandlers.delete('CHART_DATA_SUCCESS');
        this.errorHandlers.delete('ERROR');
        reject(new Error(error));
      };

      this.onMessage('CHART_DATA_SUCCESS', successHandler);
      this.onError('ERROR', errorHandler);

      this.postMessage('PROCESS_CHART_DATA', { waveformData, stationConfigs });
    });
  }

  generateTimeLabels(length: number, sampleRate: number): Promise<string[]> {
    return new Promise((resolve, reject) => {
      const successHandler = (data: string[]) => {
        this.messageHandlers.delete('TIME_LABELS_SUCCESS');
        this.errorHandlers.delete('ERROR');
        resolve(data);
      };

      const errorHandler = (error: string) => {
        this.messageHandlers.delete('TIME_LABELS_SUCCESS');
        this.errorHandlers.delete('ERROR');
        reject(new Error(error));
      };

      this.onMessage('TIME_LABELS_SUCCESS', successHandler);
      this.onError('ERROR', errorHandler);

      this.postMessage('GENERATE_TIME_LABELS', { length, sampleRate });
    });
  }

  generateChannelConfigs(): Promise<ChannelConfig[]> {
    return new Promise((resolve, reject) => {
      const successHandler = (data: ChannelConfig[]) => {
        this.messageHandlers.delete('CHANNEL_CONFIGS_SUCCESS');
        this.errorHandlers.delete('ERROR');
        resolve(data);
      };

      const errorHandler = (error: string) => {
        this.messageHandlers.delete('CHANNEL_CONFIGS_SUCCESS');
        this.errorHandlers.delete('ERROR');
        reject(new Error(error));
      };

      this.onMessage('CHANNEL_CONFIGS_SUCCESS', successHandler);
      this.onError('ERROR', errorHandler);

      this.postMessage('GENERATE_CHANNEL_CONFIGS');
    });
  }

  destroy() {
    if (this.worker) {
      this.worker.onmessage = null;
      this.worker.onerror = null;
      this.worker.terminate();
      this.worker = null;
    }
    this.messageHandlers.clear();
    this.errorHandlers.clear();
  }
}
