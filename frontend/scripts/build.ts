import * as fs from 'fs'
import * as path from 'path'
import * as rimraf from 'rimraf'
import * as webpack from 'webpack'

import config from '../webpack/webpack.config.prod'

process.env.NODE_ENV = 'production'

// Delete build directories in priv/static
const staticPath = path.resolve(__dirname, '../../priv/static')

const buildDirectories = ['js', 'css']

buildDirectories.forEach(dir => rimraf.sync(path.join(staticPath, dir)))

// Run Webpack
webpack(config).run(err => {
  if (err) {
    throw err
  }
  process.exit(0)
})
