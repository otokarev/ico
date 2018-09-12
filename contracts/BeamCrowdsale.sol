/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./Crowdsale.sol";
import "./MintableToken.sol";
import "./FlatFiatPricing.sol";
import "./KYCPayloadDeserializer.sol";

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
contract BeamCrowdsale is Crowdsale, KYCPayloadDeserializer {

  /* Server holds the private key to this address to sign incoming buy payloads to signal we have KYC records in the books for these users. */
  address public signerAddress;

  /* A new server-side signer key was set to be effective */
  event SignerChanged(address signer);

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

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId);

    return tokenAmount;
  }

  /**
   * A token purchase with anti-money laundering
   *
   * ©return tokenAmount How many tokens where bought
   */
  function buyWithKYCData(bytes32 dataframe, uint8 v, bytes32 r, bytes32 s) public payable returns(address result) {

    uint _tokenAmount;
    uint multiplier = 10 ** 18;

    // User comes through the server, check that the signature to ensure ther server
    // side KYC has passed for this customer id and whitelisted Ethereum address

    //bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    //bytes32 hash = sha3(prefix, dataframe);
    bytes32 hash = sha3(dataframe);

    //var (whitelistedAddress, customerId, minETH, maxETH, pricingInfo) = getKYCPayload(dataframe);

    // Check that the KYC data is signed by our server
    //require(ecrecover(hash, v, r, s) == signerAddress);

    // Only whitelisted address can participate the transaction
    //require(whitelistedAddress == msg.sender);

    // Server gives us information what is the buy price for this user
    //uint256 tokensTotal = calculateTokens(msg.value, pricingInfo);

    //_tokenAmount = buyTokens(msg.sender, customerId, tokensTotal);

    address addr =  ecrecover(hash, v, r, s);
    return addr;
  }

  /// @dev This function can set the server side address
  /// @param _signerAddress The address derived from server's private key
  function setSignerAddress(address _signerAddress) onlyOwner {
    signerAddress = _signerAddress;
    SignerChanged(signerAddress);
  }
}
