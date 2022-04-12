import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accCreator = await stdlib.newTestAccount(startingBalance);
const accOwner = await stdlib.newTestAccount(startingBalance);

const ctcCreator = accCreator.contract(backend);
const ctcOwner = accOwner.contract(backend, ctcCreator.getInfo());

await Promise.all([
  ctcCreator.p.Creator({
    // implement the Creator's interact object here
  }),
  ctcOwner.p.Owner({
    // implement the Owner's interact object here
  }),
]);