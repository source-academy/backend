import * as autoprefixer from 'autoprefixer'
import * as path from 'path'
import * as webpack from 'webpack'

import './webpack.ambient'

import { CheckerPlugin } from 'awesome-typescript-loader'

const publicPath = `http://${process.env.CADET_HOST}:${process.env
  .CADET_WEBPACK_PORT}/`

const config: webpack.Configuration = {
  devtool: 'cheap-module-eval-source-map',

  entry: {
    [process.env.CADET_WEBPACK_ENTRY!]: [
      require.resolve('webpack-dev-server/client') + '?' + publicPath,
      require.resolve('webpack/hot/only-dev-server'),
      path.resolve(__dirname, '../src/index.ts'),
    ],
  },

  output: {
    pathinfo: true,
    filename: '[name].js',
    chunkFilename: '[name].[id].chunk.js',
    publicPath,
    devtoolModuleFilenameTemplate: info =>
      path.resolve(info.absoluteResourcePath),
  },

  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx', 'json'],
    modules: ['node_modules'],
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        loader: require.resolve('source-map-loader'),
        enforce: 'pre',
      },
      {
        test: /\.(ts|tsx)$/,
        use: [
          {
            loader: require.resolve('awesome-typescript-loader'),
            options: {
              useBabel: true,
              useCache: true,
            },
          },
        ],
      },
      {
        test: [/\.ttf$/, /\.eot$/, /\.woff$/],
        loader: require.resolve('file-loader'),
        options: {
          name: 'static/media/[name].[hash:8].[ext]',
        },
      },
      {
        test: [/\.bmp$/, /\.gif$/, /\.jpe?g$/, /\.png$/],
        loader: require.resolve('url-loader'),
        options: {
          limit: 10000,
          name: 'static/media/[name].[hash:8].[ext]',
        },
      },
      {
        test: /\.css$/,
        use: [require.resolve('style-loader'), require.resolve('css-loader')],
      },
      {
        test: /\.scss$/,
        use: [
          require.resolve('style-loader'),
          {
            loader: require.resolve('css-loader'),
            options: {
              importLoaders: 1,
            },
          },
          {
            loader: require.resolve('postcss-loader'),
            options: {
              ident: 'postcss',
              plugins: () => [
                require('precss'),
                require('postcss-flexbugs-fixes'),
                autoprefixer({
                  browsers: [
                    '>1%',
                    'last 4 versions',
                    'Firefox ESR',
                    'not ie < 9',
                  ],
                  flexbox: 'no-2009',
                }),
              ],
            },
          },
          require.resolve('sass-loader'),
        ],
      },
    ],
  },

  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('development'),
      },
    }),
    new CheckerPlugin(),
    new webpack.HotModuleReplacementPlugin(),
  ],

  node: {
    fs: 'empty',
    net: 'empty',
    tls: 'empty',
  },

  performance: {
    hints: false,
  },
}

export default config
