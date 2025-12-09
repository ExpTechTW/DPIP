let latestDataTime = 0;

async function fetchRTSData(replayTime) {
  const url = replayTime === 0
    ? 'https://lb.exptech.dev/api/v1/trem/rts'
    : `https://api-1.exptech.dev/api/v2/trem/rts/${replayTime}`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  try {
    const response = await fetch(url, {
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    
    const data = await response.json();
    const responseTime = data.time || Date.now();

    if (responseTime <= latestDataTime) {
      throw new Error('Data is older than existing data');
    }

    latestDataTime = responseTime;

    return {
      time: responseTime,
      station: data.station || {},
      int: data.int || [],
      box: data.box || {},
    };
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

self.onmessage = async function(e) {
  const { type, data } = e.data;

  try {
    switch (type) {
      case 'FETCH_RTS_DATA':
        const rtsResponse = await fetchRTSData(data.replayTime);
        self.postMessage({
          type: 'RTS_DATA_SUCCESS',
          data: rtsResponse,
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
      type: 'DATA_ERROR',
      error: error.message,
    });
  }
};
