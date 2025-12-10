import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@dpip/common'],
  output: 'standalone',
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
