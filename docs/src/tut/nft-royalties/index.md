# {#tut-nft} Transferable-Royalty NFT

This tutorial walks through the creation of a decentralized application where we create an NFT for which the initial creator is paid a royalty with each purchase. It assumes that you have already completed the [Reach tutorial Rock, Paper, Scissors!](https://docs.reach.sh/tut/rps/#tut).

## {#tut-nft-1} Install and Initialize
In case you haven't installed Reach yet, go to the [installation step](https://docs.reach.sh/tut/rps/#tut-nft-1).

## {#tut-nft-2} Setup
For now, we'll keep it simple and have only two parties involved in our application. The creator of the NFT *Alice* and the new owner *Bob*.

We start by setting up the `index.rsh` file. It's very similar to what we have already seen in the [Rock, Paper, Scissors!](https://docs.reach.sh/tut/rps/#tut-nft-2) setup, a shell of a program that we will extend in the upcoming steps.

In the following, we'll only go through the steps that are relevant for this application. If you need a reminder of what specific parts of a Reach program are needed for, you can go back to the [Rock, Paper, Scissors! setup](https://docs.reach.sh/tut/rps/#tut-nft-2).

```
load: /examples/nft-royalties-1-setup/index.rsh
```

+ Line 5 through 7 specify the Creator participant.
+ Line 8 through 10 specify the Owner participant.

:::note
Have you seen the `'use strict'` in Line 2? It enables unused variables checks. If you want to learn more, you can read about it in the Reach documentation for ['use strict'](https://docs.reach.sh/rsh/compute/#use-strict).
:::

Next, let's create a shell for our JavaScript frontend code, which we name `index.mjs`.

```
load: /examples/nft-royalties-1-setup/index.mjs
```

+ Lines 6 and 7 create test accounts with initial endowments for the creator *Alice* and the new owner *Bob*. This will only work on the Reach-provided developer testing network.
+ Line 9 has the creator Alice deploy the application.
+ Line 10 has the new owner Bob attach to it.
+ Lines 13 through 15 initialize a backend for Alice as the creator.
+ Lines 16 through 18 initialize a backend for Alice as the owner, since she will be holding the NFT when minted.
+ Line 12 waits for the backends to complete.

:::note
Remember, you can also create the file shells for a new project by running:
```cmd
$ ./reach init
```
:::

With this setup, we can already compile and run our application using:

```cmd
$ ./reach run
```

It doesn't do anything yet, so the output won't be interesting. 

In the [next step](##tut-nft-3), we'll implement a simple logic for creating and transfering an NFT.

## {#tut-nft-3} Create and Transfer

In this section, Alice will create an NFT by deploying the application and setting an ID. She will then transfer it to Bob.

:::note
Algorand users are used to NFTs being an Algorand Standard Asset (ASA). But in general, NFTs are more of a concept and the technology behind them can differ. In the case of this application, the NFT will be the Smart Contract itself.
:::

```
load: /examples/nft-royalties-2-create/index.rsh
range: 4-11
```

+ Lines 4 through 6 define the participant interact interface of the creator. It provides the method `getId`, which returns a number.
+ Lines 7 through 10 define the participant interact interface of the owner. It provides the method `newOwner`, which returns an address.

Before we proceed with the Reach application, we'll implement the `getId` and `newOwner` methods in our JavaScript frontend interface.

```
load: /examples/nft-royalties-2-create/index.mjs
range: 12-26
```
+ Lines 13 through 19 instantiate the implementation for Alice as the creator and implement the `getId` method.
+ Lines 20 through 25 instantiate the implementation for Alice as the owner and implement the `newOwner` method.

You might have already noticed that Bob doesn't do anything so far. For now, Alice just gifts him the NFT because she, as the owner and creator, has the right to do whatever she wants with her NFT.

Now, let's go back to our backend code and implement the NFT creation and the change of ownership in our Reach application.

```
load: /examples/nft-royalties-2-create/index.rsh
range: 13-23
```

+ Lines 13 through 15 get the ID of the NFT from the creator through the `getId` interaction method.
+ Lines 16 and 17 publish the ID to the consensus network and commit the state.
+ Lines 19 through 21 get the new owner from the owner.
+ Lines 22 and 23 publish the new owner to the consensus network and commit the state.

Running the program by using
```
$ ./reach run
```
will give an output similar to this:
```
Alice mints the NFT #1927187340676650346.
Alice trades to Bob.
```
Only the ID of the NFT should differ. Just looking at the output, it looks like it worked as intended. However, our Reach application has a major flaw.

In our frontend code, we make Alice deploy the contract as the creator and then she also joins it as the owner to be able to transfer it. However, nothing stops Bob from joining the application as the owner to steal the NFT from Alice. We will address this issue in the [next step].

## {#tut-nft-4} Validating Ownership
To make sure that no malicious user steals the NFT, we have to ensure that only the actual owner of the NFT can send it to another user.