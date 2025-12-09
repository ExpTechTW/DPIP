const path = require('path');
const webpack = require('webpack');
const { merge } = require('webpack-merge');
const TerserPlugin = require('terser-webpack-plugin');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
const baseConfig = require('./webpack.config.base.cjs');
const webpackNodeExternals = require('webpack-node-externals');

const rootPath = path.join(__dirname, '../..');

const configuration = {
  devtool: 'source-map',

  mode: 'production',

  target: 'electron-main',

  entry: {
    main: path.join(rootPath, 'electron/main.ts'),
    preload: path.join(rootPath, 'electron/preload.ts'),
  },

  output: {
    filename: '[name].cjs',
    library: {
      type: 'commonjs2',
    },
  },

  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        parallel: true,
      }),
    ],
  },

  plugins: [
    new BundleAnalyzerPlugin({
      analyzerMode: process.env.ANALYZE === 'true' ? 'server' : 'disabled',
      analyzerPort: 8888,
    }),

    new webpack.EnvironmentPlugin({
      NODE_ENV: 'production',
      DEBUG_PROD: false,
    }),
  ],

  externals: [
    webpackNodeExternals({
      allowlist: [/^electron-/],
    }),
  ],

  node: {
    __dirname: false,
    __filename: false,
  },
};

module.exports = merge(baseConfig, configuration);
