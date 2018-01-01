import './webpack.ambient'

import * as autoprefixer from 'autoprefixer'
import * as ExtractTextPlugin from 'extract-text-webpack-plugin'
import * as path from 'path'
import * as UglifyJSPlugin from 'uglifyjs-webpack-plugin'
import * as webpack from 'webpack'

const config: webpack.Configuration = {
  bail: true,

  devtool: 'source-map',

  entry: {
    vendor: ['phoenix_html'],
    app: [path.resolve(__dirname, '../src/index.ts')],
  },

  output: {
    path: path.resolve(__dirname, '../../priv/static'),
    filename: 'js/[name].js',
    chunkFilename: 'js/[name].[chunkhash:8].chunk.js',
    publicPath: process.env.CADET_PROD_HOST,
    devtoolModuleFilenameTemplate: info =>
      path.relative(
        path.resolve(__dirname, '../src'),
        info.absoluteResourcePath,
      ),
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
      // Compile .tsx?
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
        oneOf: [],
        loader: ExtractTextPlugin.extract({
          fallback: require.resolve('style-loader'),
          use: [
            {
              loader: require.resolve('css-loader'),
              options: {
                importLoaders: 1,
                minimize: true,
                sourceMap: true,
              },
            },
            {
              loader: require.resolve('postcss-loader'),
              options: {
                ident: 'postcss',
                plugins: () => [
                  require('postcss-flexbugs-fixes'),
                  require('precss'),
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
            {
              loader: require.resolve('sass-loader'),
            },
          ],
        }),
      },
    ],
  },

  plugins: [
    new UglifyJSPlugin(),
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production'),
      },
    }),
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendor',
      minChunks: Infinity,
    }),
    new ExtractTextPlugin({
      filename: `css/${process.env.CADET_WEBPACK_ENTRY}.css`,
    }),
  ],

  node: {
    fs: 'empty',
    net: 'empty',
    tls: 'empty',
  },
}

export default config
