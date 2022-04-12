import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

await Promise.all([
  ctcAlice.p.Creator({
    getId: () => {
      const nft = stdlib.randomUInt();
      console.log(`Alice mints the NFT #${nft}.`);
      return nft; 
    }
  }),
  ctcAlice.p.Owner({
    newOwner: () => {
      console.log(`Alice trades to Bob.`);
      return accBob;
    }
  }),
]);