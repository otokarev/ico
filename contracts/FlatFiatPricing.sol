/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.12;

import "./PricingStrategy.sol";
import "./SafeMathLib.sol";

/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract FlatFiatPricing is PricingStrategy {

  address public owner;
  using SafeMathLib for uint;

  /* How much fiat money one token costs */
  uint public oneTokenInFiat;

  /* How many weis one fiat coin costs */
  uint public oneFiatInWeis;

  function FlatFiatPricing(uint _oneTokenInFiat) {
    owner = msg.sender;
    require(_oneTokenInFiat > 0);
    oneTokenInFiat = _oneTokenInFiat;
  }

  /** Interface declaration. */
  function isFlatFiatPricingStrategy() public constant returns (bool) {
    return true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * Owner can set a fiat coin price
   */
  function setOneFiatInWeis(uint _oneFiatInWeis) public onlyOwner {
    require(_oneFiatInWeis > 0);
    oneFiatInWeis = _oneFiatInWeis;
  }

  /**
   * Calculate the current price for buy in amount.
   *
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
    return value / oneFiatInWeis / oneTokenInFiat;
  }

}
