import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@dpip/common'],
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
