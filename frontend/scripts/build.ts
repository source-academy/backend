import * as fs from 'fs'
import * as path from 'path'
import * as rimraf from 'rimraf'
import * as webpack from 'webpack'

import config from '../webpack/webpack.config.prod'

process.env.NODE_ENV = 'production'

// Recreate priv/static directory
const staticPath = path.resolve(__dirname, '../../priv/static')
rimraf.sync(staticPath)
fs.mkdirSync(staticPath)

// Run Webpack
webpack(config).run(err => {
  if (err) {
    throw err
  }
  process.exit(0)
})
