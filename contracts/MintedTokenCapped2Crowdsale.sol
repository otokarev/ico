/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./Crowdsale.sol";
import "./MintableToken.sol";

/**
 * ICO crowdsale contract that is capped by amout of tokens.
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract MintedTokenCapped2Crowdsale is Crowdsale {

  uint public constant MAX_TRANCHES = 10;

  /**
  * Define pricing schedule using tranches.
  */
  struct Tranche {

    // The date after which this tranche amount is unlocked
    uint startAt;

    // How many tokens will be unlocked while when startAt reached
    uint amount;
  }

  // Store tranches in a fixed array, so that it can be seen in a blockchain explorer
  // Tranche 0 is always (0, 0)
  // (TODO: change this when we confirm dynamic arrays are explorable)
  Tranche[10] public tranches;

  // How many active tranches we have
  uint public trancheCount;

  bool public isLastTrancheUnlocked = false;

  /* Maximum amount of tokens this crowdsale can sell. */
  uint public maximumSellableTokens;


  mapping(uint => string) public logs;
  uint public logsLength;

  function log(string str) internal {
    logs[logsLength] = str;
    logsLength += 1;
  }

  function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0) {
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }
    return string(bstr);
  }

  function MintedTokenCapped2Crowdsale(
    address _token,
    PricingStrategy _pricingStrategy,
    address _multisigWallet,
    uint _start,
    uint _end,
    uint _minimumFundingGoal,
    uint[] _sellableTokensTranches
  ) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
    // Need to have tuples, length check
    if(_sellableTokensTranches.length % 2 == 1 || _sellableTokensTranches.length >= MAX_TRANCHES * 2) {
      throw;
    }

    log("Start");

    trancheCount = _sellableTokensTranches.length / 2;

    uint highestAmount = 0;

    for(uint i = 0; i < _sellableTokensTranches.length / 2; i++) {
      tranches[i].startAt = _sellableTokensTranches[i * 2];
      tranches[i].amount = _sellableTokensTranches[i * 2 + 1];

      // No invalid steps
      if((highestAmount != 0) && (tranches[i].amount <= highestAmount)) {
        throw;
      }

      highestAmount = tranches[i].amount;
    }

    increaseMaximumSellableTokens();
  }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    log("isBreakingCap():");
    log(uint2str(weiAmount));
    log(uint2str(tokenAmount));
    log(uint2str(weiRaisedTotal));
    log(uint2str(tokensSoldTotal));
    return tokensSoldTotal > maximumSellableTokens;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    log("isCrowdsaleFull()");
    return tokensSold >= maximumSellableTokens;
  }

  /**
   * Unlock new tranche if it's time come
   */
  function increaseMaximumSellableTokens() internal {
    log("increase()");
    if (isLastTrancheUnlocked) {
        log("unlocked so return");
      return;
    }

    for(uint i = 0; i < tranches.length; i++) {
      if(tranches[i].startAt < now && tranches[i].amount > 0) {
        log(uint2str(tranches[i].amount));
        maximumSellableTokens = tranches[i].amount;
      }
    }

    if (tranches.length - 1 == i) {
      isLastTrancheUnlocked = true;
        log("set locked");
    }
  }

  /**
   * Dynamically create tokens and assign them to the investor.
   */
  function assignTokens(address receiver, uint tokenAmount) internal {
    log("Ping1");
    MintableToken mintableToken = MintableToken(token);
    log("Ping2");
    mintableToken.mint(receiver, tokenAmount);
    log("Ping3");
    increaseMaximumSellableTokens();
    log("Ping4");
  }
}
