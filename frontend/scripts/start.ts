import * as webpack from 'webpack'
import * as WebpackDevServer from 'webpack-dev-server'

import config from '../webpack/webpack.config.dev'

process.env.NODE_ENV = 'development'

const devServerConfig: WebpackDevServer.Configuration = {
  hot: true,
  compress: true,
  publicPath: config.output!.publicPath,
  quiet: true,
  watchOptions: {
    ignored: /node_modules/,
  },
  overlay: false,
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    'Access-Control-Allow-Headers':
      'X-Requested-With, content-type, Authorization',
  },
}

const compiler = webpack(config)
const devServer = new WebpackDevServer(compiler, devServerConfig)

const close = () => {
  devServer.close()
  process.exit()
}

devServer.listen(4001, err => {
  if (err) {
    throw err
  }
})

process.on('SIGINT', close)
process.on('SIGTERM', close)
process.stdin.on('end', close)

process.stdin.resume()
