import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'export',
  transpilePackages: ['@dpip/common'],
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
