import { useEffect, useState, useCallback } from 'react';

interface UpdateInfo {
  version: string;
  releaseDate: string;
  releaseNotes?: string;
}

interface DownloadProgress {
  bytesPerSecond: number;
  percent: number;
  transferred: number;
  total: number;
}

interface ElectronAPI {
  checkForUpdates: () => Promise<{ success: boolean; updateInfo?: UpdateInfo; error?: string }>;
  downloadUpdate: () => Promise<{ success: boolean; error?: string }>;
  installUpdate: () => void;
  getAppVersion: () => Promise<string>;
  onUpdateChecking: (callback: () => void) => void;
  onUpdateAvailable: (callback: (info: UpdateInfo) => void) => void;
  onUpdateNotAvailable: (callback: (info: UpdateInfo) => void) => void;
  onUpdateError: (callback: (error: string) => void) => void;
  onUpdateDownloadProgress: (callback: (progress: DownloadProgress) => void) => void;
  onUpdateDownloaded: (callback: (info: UpdateInfo) => void) => void;
  removeUpdateListeners: () => void;
  openExternal: (url: string) => Promise<{ success: boolean; error?: string }>;
  getAudioPath: (audioFile: string) => Promise<string>;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}

export function useElectronUpdater() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [updateInfo, setUpdateInfo] = useState<UpdateInfo | null>(null);
  const [checking, setChecking] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [downloadProgress, setDownloadProgress] = useState<DownloadProgress | null>(null);
  const [updateDownloaded, setUpdateDownloaded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentVersion, setCurrentVersion] = useState<string>('');

  const isElectron = typeof window !== 'undefined' && window.electronAPI !== undefined;

  useEffect(() => {
    if (!isElectron) return;

    const electronAPI = window.electronAPI!;

    electronAPI.getAppVersion().then(setCurrentVersion);

    electronAPI.onUpdateChecking(() => {
      setChecking(true);
      setError(null);
    });

    electronAPI.onUpdateAvailable((info) => {
      setChecking(false);
      setUpdateAvailable(true);
      setUpdateInfo(info);
    });

    electronAPI.onUpdateNotAvailable(() => {
      setChecking(false);
      setUpdateAvailable(false);
    });

    electronAPI.onUpdateError((err) => {
      setChecking(false);
      setDownloading(false);
      setError(err);
    });

    electronAPI.onUpdateDownloadProgress((progress) => {
      setDownloadProgress(progress);
    });

    electronAPI.onUpdateDownloaded((info) => {
      setDownloading(false);
      setUpdateDownloaded(true);
      setUpdateInfo(info);
    });

    return () => {
      electronAPI.removeUpdateListeners();
    };
  }, [isElectron]);

  const checkForUpdates = useCallback(async () => {
    if (!isElectron) {
      console.warn('Not running in Electron environment');
      return;
    }

    setChecking(true);
    setError(null);

    const result = await window.electronAPI!.checkForUpdates();

    if (!result.success) {
      setError(result.error || 'Failed to check for updates');
      setChecking(false);
    }
  }, [isElectron]);

  const downloadUpdate = useCallback(async () => {
    if (!isElectron) {
      console.warn('Not running in Electron environment');
      return;
    }

    setDownloading(true);
    setError(null);

    const result = await window.electronAPI!.downloadUpdate();

    if (!result.success) {
      setError(result.error || 'Failed to download update');
      setDownloading(false);
    }
  }, [isElectron]);

  const installUpdate = useCallback(() => {
    if (!isElectron) {
      console.warn('Not running in Electron environment');
      return;
    }

    window.electronAPI!.installUpdate();
  }, [isElectron]);

  const openExternal = useCallback(async (url: string) => {
    if (!isElectron) {
      window.open(url, '_blank');
      return;
    }

    await window.electronAPI!.openExternal(url);
  }, [isElectron]);

  const getAudioPath = useCallback(async (audioFile: string) => {
    if (!isElectron) {
      return `/audios/${audioFile}`;
    }

    return await window.electronAPI!.getAudioPath(audioFile);
  }, [isElectron]);

  return {
    isElectron,
    currentVersion,
    updateAvailable,
    updateInfo,
    checking,
    downloading,
    downloadProgress,
    updateDownloaded,
    error,
    checkForUpdates,
    downloadUpdate,
    installUpdate,
    openExternal,
    getAudioPath,
  };
}
