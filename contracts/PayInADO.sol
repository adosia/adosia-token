pragma solidity ^0.4.19;
// author - adosiawolf

// here we will accept payments in ADO for various Adosia products and subscription services

import './StandardToken.sol';
import './Ownable.sol';
import './SafeMath.sol';


// requires 1,440,000,000 ADO deposited into ADO safe address
contract PayInADO is Ownable {

  using SafeMath for uint256;

  event paymentReceived();

  mapping (address => uint256) public payment_due;
  mapping (address => string)  public adosia_uuid;
  mapping (address => uint256) public device_count;
  mapping (address => bool) public revoked;

  uint256 public constant exponent = 10**18;

  address public payToAddress;

  function PayInADO(address _payToAddress) public {

    // set address for
    payToAddress = _payToAddress;

    // TODO - will update this shortly - 2/26/2018 - adosiawolf


  }

}
