# {#tut} Transferable-Royalty NFT

This tutorial walks through the creation of a decentralized application where we create an NFT for which the initial creator is paid a royalty with each purchase. It assumes that you have already completed the [Reach tutorial *Rock, Paper, Scissors!*](https://docs.reach.sh/tut/rps/#tut), but you can also jump to the tutorial steps when needed.

## {#tut-1} Install and Initialize
In case you haven't installed Reach yet, go to the [installation step](https://docs.reach.sh/tut/rps/#tut-1).

## {#tut-2} Setup
For creating and transfering an NFT in our application, we need two parties, the *Creator* and an *Owner*. While there is always only one *Creator*, the *Owner* can change over time.

We start by setting up the `index.rsh` file. It's very similar to what we have already seen in the [*Rock, Paper, Scissors!*](https://docs.reach.sh/tut/rps/#tut-2) setup, a shell of a program that we will extend in the next steps.

```
load: /examples/nft-royal-1-setup/index.rsh
```

+ Line 1 indicates that this is a Reach program. You'll always have this at the top of every program.
+ Line 3 defines the main export from the program. When you compile, this is what the compiler will look at.
+ Line 4 through 6 specify the *Creator* participant.
+ Line 7 through 9 specify the *Owner* as a participant class, because an NFT can have many owners (but only one at a time).
+ Line 10 marks the deployment of the Reach program, which allows the program to start doing things.

Next, let's create a shell for our JavaScript frontend code, which we name `index.mjs`.

```
load: /examples/nft-royal-1-setup/index.mjs
```

+ Line 1 imports the Reach standard library loader.
+ Line 2 imports your backend, which `./reach compile` will produce.
+ Line 3 loads the standard library dynamically based on the `REACH_CONNECTOR_MODE` environment variable.
+ Line 5 defines a quantity of network tokens as the starting balance for each test account.
+ Lines 6 and 7 create test accounts with initial endowments for the *Creator* and an *Owner*. Remember that there can be different owners over time. For now, we create only one instance of an owner, which will be the first owner.
This will only work on the Reach-provided developer testing network.
+ Line 9 has the *Creator* deploy the application.
:::note
The program defined in [`nft-royalties-1-setup/index.rsh`](@{REPO}/examples/nft-royalties-1-setup/index.rsh) will only begin to run after it has been deployed via [nft-royalties-1-setup/index.mjs](@{REPO}/examples/nft-royalties-1-setup/index.mjs).
:::

+ Line 10 has an *Owner* attach to it.
+ Lines 13 through 15 initialize a backend for the *Creator*.
+ Lines 16 through 18 initialize a backend for an *Owner*.
+ Line 12 waits for the backends to complete.