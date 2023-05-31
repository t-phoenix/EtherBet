# EtherBet
Etherbet is a simple crypto dapp which uses Chainlink VRF (Verifyable Random Function) to determine the raffle winner on random basis. The contract is owned and managed by the DAO Governor Contract for Etherbet, to adopt decentralisation.




## Tech Overview

- EtherBet ERC20 token Contract bootstraping the dapp ecosystem
- EtherBet Governor - To enable decentralisation using DAO mechanism.
- Crowdsale Contract - Participants need to buy Etherbet token to participate in the raffle. These tokens will also be used to manage the DAO.
- Gambling Contract - Raffle dapp, enabled by Etherbet ERC20 token, Governor Contract and Chainlink VRF.
- Chainlink VRF - To fetch a random number in using chainlink oracle services.


# Roadmap

- Deploy Etherbet ERC20 Contract
- Deploy Gambling Contract with token Address.
- Deploy Governor Contract with timelock and token address.
- Deploy Crowdsale Factory to deploy Crowdsale contracts.
- Transfer ownership of Gambling and Crowdsale Factory to Governor.