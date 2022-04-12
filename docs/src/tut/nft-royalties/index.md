# {#tut} Transferable-Royalty NFT

This tutorial walks through the creation of a decentralized application where we create an NFT for which the initial creator is paid a royalty with each purchase. It assumes that you have already completed the [Reach tutorial *Rock, Paper, Scissors!*](https://docs.reach.sh/tut/rps/#tut).

## {#tut-1} Install and Initialize
In case you haven't installed Reach yet, go to the [installation step](https://docs.reach.sh/tut/rps/#tut-1).

## {#tut-2} Setup
For now, we'll keep it simple and have only two parties involved in our application. The creator of the NFT *Alice* and the new owner *Bob*.

We start by setting up the `index.rsh` file. It's the same as what we have already seen in the [*Rock, Paper, Scissors!*](https://docs.reach.sh/tut/rps/#tut-2) setup, a shell of a program that we will extend in the upcoming steps.

```
load: /examples/nft-royal-1-setup/index.rsh
```

+ Line 1 indicates that this is a Reach program. You'll always have this at the top of every program.
+ Line 3 defines the main export from the program. When you compile, this is what the compiler will look at.
+ Line 4 through 6 specify the creator, *Alice*.
+ Line 7 through 9 specify the owner, *Bob*.
+ Line 10 marks the deployment of the Reach program, which allows the program to start doing things.

Next, let's create a shell for our JavaScript frontend code, which we name `index.mjs`.

```
load: /examples/nft-royal-1-setup/index.mjs
```

+ Line 1 imports the Reach standard library loader.
+ Line 2 imports your backend, which `./reach compile` will produce.
+ Line 3 loads the standard library dynamically based on the `REACH_CONNECTOR_MODE` environment variable.
+ Line 5 defines a quantity of network tokens as the starting balance for each test account.
+ Lines 6 and 7 create test accounts with initial endowments for the creator *Alice* and the new owner *Bob*. This will only work on the Reach-provided developer testing network.
+ Line 9 has the creator *Alice* deploy the application.
:::note
The program defined in [`nft-royalties-1-setup/index.rsh`](@{REPO}/examples/nft-royalties-1-setup/index.rsh) will only begin to run after it has been deployed via [nft-royalties-1-setup/index.mjs](@{REPO}/examples/nft-royalties-1-setup/index.mjs).
:::

+ Line 10 has the new owner *Bob* attach to it.
+ Lines 13 through 15 initialize a backend for *Alice*.
+ Lines 16 through 18 initialize a backend for *Bob*.
+ Line 12 waits for the backends to complete.