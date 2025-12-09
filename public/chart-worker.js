const DISPLAY_DURATION = 60;
const STATION_IDS = [4812424, 6126556, 11336952, 11334880, 1480496];
const CHART_LENGTH = 50 * DISPLAY_DURATION;

const TOTAL_HEIGHT = 630;
const NUM_CHANNELS = 5;
const TOP_BOTTOM_GAP_REDUCTION = 50;
const CHANNEL_LABEL_OFFSETS = [30, 45, 50, 60, 70];

const BASE_GAP = TOTAL_HEIGHT / (NUM_CHANNELS + 1);
const TOP_GAP = BASE_GAP - TOP_BOTTOM_GAP_REDUCTION;
const MIDDLE_GAP_EXTRA = (TOP_BOTTOM_GAP_REDUCTION * 2) / 4;
const MIDDLE_GAP = BASE_GAP + MIDDLE_GAP_EXTRA;

class SOSStage {
  constructor(b0, b1, b2, a1, a2) {
    this.b0 = b0;
    this.b1 = b1;
    this.b2 = b2;
    this.a1 = a1;
    this.a2 = a2;
    this.z1 = 0;
    this.z2 = 0;
  }
}

class BPFFilter {
  constructor(num, den) {
    if (num.length !== den.length) {
      throw new Error('num/den length mismatch');
    }

    this.stages = num.map((numCoeffs, i) => {
      const [b0, b1, b2] = numCoeffs;
      const [a0, a1, a2] = den[i];

      if (a0 !== 1.0) {
        return new SOSStage(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
      }

      return new SOSStage(b0, b1, b2, a1, a2);
    });
  }

  apply(x) {
    let y = x;
    for (let i = 0; i < this.stages.length; i++) {
      const stage = this.stages[i];
      const out = stage.b0 * y + stage.z1;
      stage.z1 = stage.b1 * y - stage.a1 * out + stage.z2;
      stage.z2 = stage.b2 * y - stage.a2 * out;
      y = out;
    }
    return y;
  }

  applyBuffer(x) {
    return x.map((val) => this.apply(val));
  }

  reset() {
    for (const stage of this.stages) {
      stage.z1 = 0;
      stage.z2 = 0;
    }
  }
}

const NUM_LPF = [
  [0.8063260828207, 0, 0],
  [1, -0.3349099821478, 1],
  [0.8764452158503, 0, 0],
  [1, -0.08269016387548, 1],
  [0.8131516681065, 0, 0],
  [1, 0.5521204464881, 1],
  [1.228277124762, 0, 0],
  [1, 1.705652561121, 1],
  [0.00431639855615, 0, 0],
  [1, -0.4218227257396, 1],
  [1, 0, 0],
];

const DEN_LPF = [
  [1, 0, 0],
  [1, -0.6719798550872, 0.938845023254],
  [1, 0, 0],
  [1, -0.8264759910073, 0.8561761588872],
  [1, 0, 0],
  [1, -1.10962299915, 0.7141202529829],
  [1, 0, 0],
  [1, -1.413006561919, 0.5638384962434],
  [1, 0, 0],
  [1, -0.6139497794955, 0.9834048810788],
  [1, 0, 0],
];

const NUM_HPF = [
  [0.9769037485204, 0, 0],
  [1, -2, 1],
  [0.9424328308459, 0, 0],
  [1, -2, 1],
  [0.9149691441131, 0, 0],
  [1, -2, 1],
  [0.8959987277275, 0, 0],
  [1, -2, 1],
  [0.8863374802187, 0, 0],
  [1, -2, 1],
  [1, 0, 0],
];

const DEN_HPF = [
  [1, 0, 0],
  [1, -1.946073828052, 0.9615411660298],
  [1, 0, 0],
  [1, -1.877404882092, 0.8923264412918],
  [1, 0, 0],
  [1, -1.822694925196, 0.837181651256],
  [1, 0, 0],
  [1, -1.78490427193, 0.7990906389804],
  [1, 0, 0],
  [1, -1.765658260281, 0.7796916605933],
  [1, 0, 0],
];

const MAX_FILTER_CACHE_SIZE = 10;
const filterCache = new Map();
const filterAccessOrder = [];

function getBPFFilter(stationId) {
  if (!filterCache.has(stationId)) {
    if (filterCache.size >= MAX_FILTER_CACHE_SIZE) {
      const oldestStationId = filterAccessOrder.shift();
      if (oldestStationId !== undefined) {
        filterCache.delete(oldestStationId);
      }
    }
    
    const hpf = new BPFFilter(NUM_HPF, DEN_HPF);
    const lpf = new BPFFilter(NUM_LPF, DEN_LPF);
    filterCache.set(stationId, { hpf, lpf });
  }
  
  const index = filterAccessOrder.indexOf(stationId);
  if (index > -1) {
    filterAccessOrder.splice(index, 1);
  }
  filterAccessOrder.push(stationId);
  
  return filterCache.get(stationId);
}

function clearUnusedFilters(activeStationIds) {
  const activeSet = new Set(activeStationIds);
  const toDelete = [];
  
  filterCache.forEach((_, stationId) => {
    if (!activeSet.has(stationId)) {
      toDelete.push(stationId);
    }
  });
  
  toDelete.forEach(stationId => {
    filterCache.delete(stationId);
    const index = filterAccessOrder.indexOf(stationId);
    if (index > -1) {
      filterAccessOrder.splice(index, 1);
    }
  });
}

function applyBPF(data, stationId) {
  if (!data || data.length === 0) return data;
  
  const { hpf, lpf } = getBPFFilter(stationId);
  const result = [];
  
  for (let i = 0; i < data.length; i++) {
    const value = data[i];
    
    if (value === null || value === undefined) {
      result.push(null);
    } else {
      const hpfValue = hpf.apply(value);
      const filteredValue = lpf.apply(hpfValue);
      result.push(filteredValue);
    }
  }
  
  return result;
}

function generateColorFromId(id) {
  let hash = 0;
  const str = id.toString();
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }

  hash = Math.abs(hash);

  const hue = hash % 360;
  const saturation = 85 + (hash % 15);
  const lightness = 50 + (hash % 10);

  const h = hue / 360;
  const s = saturation / 100;
  const l = lightness / 100;

  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs((h * 6) % 2 - 1));
  const m = l - c / 2;

  let r, g, b;
  if (h < 1/6) {
    r = c; g = x; b = 0;
  } else if (h < 2/6) {
    r = x; g = c; b = 0;
  } else if (h < 3/6) {
    r = 0; g = c; b = x;
  } else if (h < 4/6) {
    r = 0; g = x; b = c;
  } else if (h < 5/6) {
    r = x; g = 0; b = c;
  } else {
    r = c; g = 0; b = x;
  }

  r = Math.round((r + m) * 255);
  g = Math.round((g + m) * 255);
  b = Math.round((b + m) * 255);

  return `rgb(${r}, ${g}, ${b})`;
}

function generateTimeLabels(length, sampleRate) {
  return Array.from({ length }, (_, i) => {
    const position = length - i;
    const timeInSeconds = position / sampleRate;
    const interval = sampleRate * 10;
    const offset = sampleRate * 5;

    if (position % interval === offset && timeInSeconds > 0 && timeInSeconds <= 60) {
      return timeInSeconds.toString();
    }
    return '';
  });
}

function generateChannelConfigs() {
  return [
    { baseline: TOTAL_HEIGHT - TOP_GAP, color: generateColorFromId(STATION_IDS[0]) },
    { baseline: TOTAL_HEIGHT - TOP_GAP - MIDDLE_GAP, color: generateColorFromId(STATION_IDS[1]) },
    { baseline: TOTAL_HEIGHT - TOP_GAP - (MIDDLE_GAP * 2), color: generateColorFromId(STATION_IDS[2]) },
    { baseline: TOTAL_HEIGHT - TOP_GAP - (MIDDLE_GAP * 3), color: generateColorFromId(STATION_IDS[3]) },
    { baseline: TOTAL_HEIGHT - TOP_GAP - (MIDDLE_GAP * 4), color: generateColorFromId(STATION_IDS[4]) },
  ];
}

function processWaveformData(waveformData, stationConfigs) {
  const channelDataArrays = [];
  const channelConfigs = generateChannelConfigs();

  channelConfigs.forEach((config, index) => {
    let data;

    if (index < STATION_IDS.length) {
      const stationId = STATION_IDS[index];
      const stationConfig = stationConfigs[stationId];

      if (!stationConfig) {
        data = Array(CHART_LENGTH).fill(null);
      } else {
        let stationWaveform = waveformData[stationId] || Array(stationConfig.dataLength).fill(null);
        
        stationWaveform = applyBPF(stationWaveform, stationId);

        if (stationConfig.sampleRate === 20) {
          data = [];
          for (let i = 0; i < stationWaveform.length; i++) {
            const value = stationWaveform[i];
            if (value !== null) {
              const scaledValue = (value * stationConfig.scale) + config.baseline;
              data.push(scaledValue);
              data.push(scaledValue);
              if (i % 2 === 0) data.push(scaledValue);
            } else {
              data.push(null);
              data.push(null);
              if (i % 2 === 0) data.push(null);
            }
          }
        } else {
          data = stationWaveform.map(value =>
            value !== null ? (value * stationConfig.scale) + config.baseline : null
          );
        }

        while (data.length < CHART_LENGTH) {
          data.unshift(null);
        }
        while (data.length > CHART_LENGTH) {
          data.shift();
        }
      }
    } else {
      data = Array(CHART_LENGTH).fill(null);
    }

    channelDataArrays.push({ index, data });
  });

  return channelDataArrays;
}

function calculateChannelMaxValues(channelDataArrays) {
  const channelConfigs = generateChannelConfigs();
  const channelMaxValues = [];

  channelDataArrays.forEach(({index, data}) => {
    const config = channelConfigs[index];
    let maxAbsDeviation = 0;

    data.forEach(value => {
      if (value !== null) {
        const deviation = Math.abs(value - config.baseline);
        maxAbsDeviation = Math.max(maxAbsDeviation, deviation);
      }
    });

    channelMaxValues.push({ index, maxAbsDeviation });
  });

  channelMaxValues.sort((a, b) => a.maxAbsDeviation - b.maxAbsDeviation);

  const indexToOrder = {};
  channelMaxValues.forEach((item, order) => {
    indexToOrder[item.index] = order;
  });

  return indexToOrder;
}

function generateChartDatasets(channelDataArrays, indexToOrder) {
  const channelConfigs = generateChannelConfigs();
  const datasets = [];

  channelDataArrays.forEach(({index, data}) => {
    const config = channelConfigs[index];
    const orderRank = indexToOrder[index] || 0;
    const baseOrder = orderRank * 2;

    datasets.push({
      label: `Station ${STATION_IDS[index] || index} (White)`,
      data: data,
      borderColor: 'rgba(255, 255, 255, 0.3)',
      backgroundColor: 'transparent',
      borderWidth: 0.8,
      pointRadius: 0,
      tension: 0,
      fill: false,
      spanGaps: false,
      order: baseOrder,
    });

    datasets.push({
      label: `Station ${STATION_IDS[index] || index}`,
      data: data,
      borderColor: config.color,
      backgroundColor: 'transparent',
      borderWidth: 1.5,
      pointRadius: 0,
      tension: 0,
      fill: false,
      spanGaps: false,
      order: baseOrder,
    });
  });

  return datasets;
}

function processChartData(waveformData, stationConfigs) {
  const activeStationIds = Object.keys(waveformData).map(id => parseInt(id));
  clearUnusedFilters(activeStationIds);
  
  const channelDataArrays = processWaveformData(waveformData, stationConfigs);
  const indexToOrder = calculateChannelMaxValues(channelDataArrays);
  const datasets = generateChartDatasets(channelDataArrays, indexToOrder);
  const timeLabels = generateTimeLabels(CHART_LENGTH, 50);

  return {
    labels: timeLabels,
    datasets: datasets,
  };
}

self.onmessage = function(e) {
  const { type, data } = e.data;

  try {
    switch (type) {
      case 'PROCESS_CHART_DATA':
        const chartData = processChartData(data.waveformData, data.stationConfigs);
        self.postMessage({
          type: 'CHART_DATA_SUCCESS',
          data: chartData,
        });
        break;
      
      case 'GENERATE_TIME_LABELS':
        const timeLabels = generateTimeLabels(data.length, data.sampleRate);
        self.postMessage({
          type: 'TIME_LABELS_SUCCESS',
          data: timeLabels,
        });
        break;
      
      case 'GENERATE_CHANNEL_CONFIGS':
        const channelConfigs = generateChannelConfigs();
        self.postMessage({
          type: 'CHANNEL_CONFIGS_SUCCESS',
          data: channelConfigs,
        });
        break;
      
      default:
        self.postMessage({
          type: 'ERROR',
          error: 'Unknown message type',
        });
    }
  } catch (error) {
    self.postMessage({
      type: 'ERROR',
      error: error.message,
    });
  }
};
