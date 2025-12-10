'use client';

import { useState, useEffect } from 'react';
import packageJson from '../../package.json';
import { ExpTech } from '../lib/exptech';

export function Footer() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userEmail, setUserEmail] = useState<string | null>(null);

  const exptech = ExpTech.getInstance();

  useEffect(() => {
    const data = exptech.getLoginData();
    if (data) {
      setIsLoggedIn(data.isLoggedIn);
      setUserEmail(data.userEmail);
    }
  }, []);

  const handleAuthAction = async () => {
    if (isLoggedIn) {
      exptech.handleLogout();
      setIsLoggedIn(false);
      setUserEmail(null);
    } else {
      try {
        const result = await exptech.handleLogin();
        if (result) {
          setIsLoggedIn(true);
          setUserEmail(result.email);
        }
      } catch (error: any) {
        alert(`登入失敗: ${error.message}`);
      }
    }
  };

  return (
    <div className="fixed bottom-3 left-3 z-50 flex items-baseline space-x-2">
      <div className="bg-black/70 backdrop-blur-md rounded-lg px-3 py-1.5 border border-white/10 shadow-lg">
        <span className="text-white/90 text-xs font-medium tracking-wide">v{packageJson.version}</span>
      </div>
      {isLoggedIn && (
        <div className="bg-black/70 backdrop-blur-md rounded-lg px-3 py-1.5 border border-white/10 shadow-lg">
          <span className="text-white/90 text-xs font-medium tracking-wide">{`已登入: ${userEmail?.split('@')[0]} (${userEmail})`}</span>
        </div>
      )}
      <button
        onClick={handleAuthAction}
        className="bg-black/70 backdrop-blur-md rounded-lg px-3 py-1.5 border border-white/10 shadow-lg text-white/90 text-xs font-medium tracking-wide"
      >
        {isLoggedIn ? '登出 ExpTech' : '登入 ExpTech'}
      </button>
    </div>
  );
}