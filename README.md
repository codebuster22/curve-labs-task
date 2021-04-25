# Curve Labs Voting App

 ## Problem Statement
 URL to Problem Statement:- https://gist.github.com/kinspotting/d05a472fc74b1b28a99a9d39114bc4fc

## Overview

The application is mostly dependent on these 4 core contracts. I have streamlined the process of how state is updated.
State can only be updated in one direction. That is controller is the root, which will update the state at different contracts.
If the interaction involves state update, only controller can do that.

### Controller.sol

Master Controller. Every state update goes through this contract. It acts as a bridge between users and contracts for state update.

### Ballot.sol

This is like Agenda. Users can deploy different instances of Ballot, to have voting for different agendas.
For example. 
1) A company need to have voting Agenda A and Agenda B. 
2) The company will deploy two instances of Ballot using Controller. 
3) Now voting for Agenda A will be done at one contract.
4) Votign for Agenda B will be done at another contract.
5) Controller makes it easy to switch between ballots.

### SafeController.sol

This is a controller for Gnosis Safe. Users can create proposals for adding/removing owners from Gnosis Safe. It is a module which is enabled at Gnosis Safe Manager. The users can then vote on different agendas. Here the vote can be done for either Yes or No. So if any one option get's vote greater than 50%, the proposal is ended and it is exeecuted. 
For example:-
1) A user created a proposal to add Alice as an owner.
2) If the proposal gets more than 50% votes for Yes. It will stop accepting votes.
3) It will update the safe ownership.
4) As if votes for yes  > 50%, then votes for no < 50&.
5) Hence no need to continue voting.

### Storage.sol

This is the storage for Voters and Ballot details. The state is updated by Controller and also, the status of deployed ballot is updated by respective ballots only.

## Architecture:-
Coming Soon. [Diagrams in progress]

 ## Technology Stack
 1) Hardhat
 2) React
 3) Ethers.js
 4) Web3.js

 ## How to use
 1) Get some DAI/USDC tokens.
 2) Stake DAI/USDC token at below mentioned Balancer Pool.
 3) Register on the app.
 4) Woohoo! Welcome to the application!

 ## Note:-
 1) Only admins can create new ballot.
 2) Only admins can add proposals to ballots.
 3) Only admins can start/end voting process for Ballot.
 4) Anyone can create proposal to add/remove owners from the Gnosis Safe.
 5) The voting weight have 4 decimal points.

 ## URL:-
Balancer Pool URL - https://rinkeby.pools.balancer.exchange/#/pool/0x1A7F38418aF5AaBF0fcAe420Ea0b9BbF7bBfd34b

## Address
 Safe Manager - 0x6cCf1d097BBCE68D0A4a4Bb647349af423A2Ccb7
 Balancer Pool - 0x1A7F38418aF5AaBF0fcAe420Ea0b9BbF7bBfd34b
 DAI Token - 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
 USDC Token - 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b

 ## Deployment
Rinkeby:-
1) Controller.sol:- 0x1D4b99967E1990011A068daF24bBBCf02A439886
2) Storage.sol:- 0xcf4CC9f888Cc58B2D46b75d34159803BedAa033d
3) SafeController.sol:- 0xa7c8cF1C696DA8bC3d02b9068D3ed2872FE9E76F

Demo for the applicaton:- https://codebuster22.github.io/client-curve-labs-voting

## Future Scope:-
1) Add feature to add/remove admin using voting.
2) Improve UI
3) Improve UX
4) Create New Balancer Pool directly from application.
5) More interaction with Gnosis safe apps like enable/desable modules or integrate whole transaction builder functionality.

## References
Balancer Pool URL - https://rinkeby.pools.balancer.exchange/#/pool/0x1A7F38418aF5AaBF0fcAe420Ea0b9BbF7bBfd34b
Safe Manager URl - https://rinkeby.gnosis-safe.io/app/#/safes/0x6cCf1d097BBCE68D0A4a4Bb647349af423A2Ccb7