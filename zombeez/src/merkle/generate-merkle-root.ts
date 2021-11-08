import fs from 'fs'
import { parseBalanceMap } from './parse-balance-map'

const json = JSON.parse(fs.readFileSync("./whitelist.json", { encoding: 'utf8' }))

if (typeof json !== 'object') throw new Error('Invalid JSON')

console.log(JSON.stringify(parseBalanceMap(json)))

