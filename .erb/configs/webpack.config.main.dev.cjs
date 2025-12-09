const path = require('path');
const webpack = require('webpack');
const { merge } = require('webpack-merge');
const baseConfig = require('./webpack.config.base.cjs');
const webpackNodeExternals = require('webpack-node-externals');

const rootPath = path.join(__dirname, '../..');

const configuration = {
  devtool: 'inline-source-map',

  mode: 'development',

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

  plugins: [
    new webpack.EnvironmentPlugin({
      NODE_ENV: 'development',
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
