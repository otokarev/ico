/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./Crowdsale.sol";
import "./MintableToken.sol";
import "./FlatFiatPricing.sol";


/**
 * Uncapped ICO crowdsale contract.
 *
 *
 * Intended usage
 *
 * - A short time window
 * - Flat price
 * - No cap
 *
 */
contract BeamCrowdsale is Crowdsale {

  function BeamCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {

  }

  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

    if(!FlatFiatPricing(pricingStrategy).isFlatFiatPricingStrategy()) {
      throw;
    }
  }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    return false;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    // Uncle Scrooge
    return false;
  }

  function assignTokens(address receiver, uint tokenAmount) internal {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }

  /**
   * @dev Make an investment.
   *
   * Crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   * @param customerId (optional) UUID v4 to track the successful payments on the server side'
   * @param fiatAmount Amount of fiat coins which be credited to receiver
   *
   * @return tokensBought How mony tokens were bought
   */
  function buyTokensForFiat(address receiver, uint128 customerId, uint fiatAmount) stopInEmergency onlyOwner public returns(uint tokensBought) {

    // Determine if it's a good time to accept investment from this participant
    if(getState() == State.PreFunding) {
      // Are we whitelisted for early deposit
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
      // Retail participants can only come in when the crowdsale is running
      // pass
    } else {
      // Unwanted state
      throw;
    }

    FlatFiatPricing pricing = FlatFiatPricing(pricingStrategy);
    uint weiAmount = pricing.oneFiatInWeis() * fiatAmount;
    uint tokenAmount = pricing.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, receiver, token.decimals());

    // Dust transaction
    require(tokenAmount != 0);

    if(investedAmountOf[receiver] == 0) {
      // A new investor
      investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

    // Update totals
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    if(pricingStrategy.isPresalePurchase(receiver)) {
      presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
    }

    // Check that we did not bust the cap
    require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

    assignTokens(receiver, tokenAmount);

    // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our multisig
    if(!multisigWallet.send(weiAmount)) throw;

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId);

    return tokenAmount;
  }
}
