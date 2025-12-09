export interface WaveformData {
  X: number[];
  Y: number[];
  Z: number[];
  id: number;
  time: number;
  precision: number;
  sampleRate: number;
}

export interface WebSocketConfig {
  wsUrl: string;
  token: string;
  topics: string[];
  stationIds: number[];
}

interface EncodedWaveform {
  data: Uint8Array;
  id: number;
  time: number;
  count: number;
}

function decodeWaveform(encoded: EncodedWaveform): WaveformData {
  const buffer = encoded.data;
  let offset = 0;

  const header = buffer[offset++];
  const precision = (header & 0x80) ? 4 : 2;

  const count = (buffer[offset++] << 8) | buffer[offset++];

  const divisor = precision === 2 ? 100 : 10000;

  const readValue = (): number => {
    let intValue: number;

    if (precision === 2) {
      const adjusted = (buffer[offset++] << 16) |
                      (buffer[offset++] << 8) |
                      buffer[offset++];
      intValue = adjusted - 524288;
    } else {
      const adjusted = (buffer[offset++] << 24) |
                      (buffer[offset++] << 16) |
                      (buffer[offset++] << 8) |
                      buffer[offset++];
      intValue = adjusted - 67108864;
    }

    return intValue / divisor;
  };

  const X: number[] = [];
  const Y: number[] = [];
  const Z: number[] = [];

  for (let i = 0; i < count; i++) X.push(readValue());
  for (let i = 0; i < count; i++) Y.push(readValue());
  for (let i = 0; i < count; i++) Z.push(readValue());

  const sampleRate = precision === 2 ? 20 : 50;

  return {
    X,
    Y,
    Z,
    id: encoded.id,
    time: encoded.time,
    precision,
    sampleRate
  };
}

function base64ToUint8Array(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export class WaveformWebSocket {
  private ws: WebSocket | null = null;
  private config: WebSocketConfig;
  private onWaveformCallback: ((data: WaveformData) => void) | null = null;
  private reconnectTimer: number | null = null;
  private reconnectDelay = 5000;

  constructor(config: WebSocketConfig) {
    this.config = config;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(this.config.wsUrl);

        this.ws.onopen = () => {
          this.subscribe();
          resolve();
        };

        this.ws.onerror = (error) => {
          reject(error);
        };

        this.ws.onclose = () => {
          this.scheduleReconnect();
        };

        this.ws.onmessage = (event) => {
          this.handleMessage(event);
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  private subscribe() {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    const message = {
      type: 'start',
      token: this.config.token,
      topic: this.config.topics,
      config: {
        [this.config.topics[0]]: this.config.stationIds
      },
      time: Date.now()
    };

    this.ws.send(JSON.stringify(message));
  }

  private handleMessage(event: MessageEvent) {
    try {
      const message = JSON.parse(event.data);

      switch (message.type) {
        case 'data':
          const payload = message.payload?.payload || message.payload;

          if (payload?.data && payload.data._type === 'Buffer') {
            const base64Data = payload.data.data;
            const buffer = base64ToUint8Array(base64Data);

            const waveform = decodeWaveform({
              data: buffer,
              id: payload.id,
              time: payload.time,
              count: payload.count
            });

            if (this.onWaveformCallback) {
              this.onWaveformCallback(waveform);
            }
          }
          break;
      }
    } catch (error) {
      // Silent error handling
    }
  }

  private scheduleReconnect() {
    if (this.reconnectTimer) return;

    this.reconnectTimer = window.setTimeout(() => {
      this.reconnectTimer = null;
      this.connect().catch(() => {});
    }, this.reconnectDelay);
  }

  onWaveform(callback: (data: WaveformData) => void) {
    this.onWaveformCallback = callback;
  }

  disconnect() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.ws) {
      this.ws.onopen = null;
      this.ws.onerror = null;
      this.ws.onclose = null;
      this.ws.onmessage = null;
      this.ws.close();
      this.ws = null;
    }

    this.onWaveformCallback = null;
  }
}
