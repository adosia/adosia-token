pragma solidity ^0.4.19;
// author - adosiawolf


//work in progress - addresses not yet added


import './StandardToken.sol';
import './Ownable.sol';
import './SafeMath.sol';


// requires 1,440,000,000 ADO deposited into ADO safe address
contract ADOVault is Ownable {

  using SafeMath for uint256;

  event Revoked(address revoked);
  event Released(address releastedTO, uint256 releasedAmount);

  uint256 public unlockDate;
  uint256 public start;
  uint256 public end;
  uint8 public unlockPercent;

  mapping (address => uint256) public allocated;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  uint256[] allocations;

  address public ADO;
  uint256 public constant exponent = 10**18;

  function ADOVault(address _ADO, address[] _allocated, uint256 _start) public {

    ADO = _ADO;
    //transferOwnership(ADO);

    allocations = [750000000, 50000000, 360000000, 200000000, 40000000, 40000000];

    if (_start == 0)
      start = now + 120 seconds;

    else
      start = _start;

    // loop through _allocated array and set allocted mapping
    for (uint i = 0; i < _allocated.length; i++) {
      allocated[_allocated[i]] = allocations[i];
       released[_allocated[i]] = 0;
    }



    // set to unlock first batch at 180 days from sale launch
    unlockDate = now + 6 * 30 minutes;          // ~6 months

    // when all vault tokens should be available for release
    end = unlockDate + 18 * 30 minutes;         // ~24 months
  }


  // transfer vested tokens to pre-specified beneficiary addres

  function release() public {

      // don't even fuck with calls coming from non hard-coded addresses
      require(allocated[msg.sender] > 0);
      //assert(allocated[msg.sender]);

      uint256 unreleased = releasableAmount(msg.sender);
      require(unreleased > 0);
      released[msg.sender] = released[msg.sender].add(unreleased);

      if (!StandardToken(ADO).transfer(msg.sender, unreleased)) {
        revert();
      }

      Released(msg.sender, unreleased);
  }

  // allow owner to revoke token vesting
  function revoke(address addr) public onlyOwner {

      require(allocated[addr] > 0);
      require(!revoked[addr]);

      uint256 balance = released[addr];

      uint256 unreleased = releasableAmount(addr);
      uint256 refund = balance.sub(unreleased);

      revoked[addr] = true;
      if (!StandardToken(ADO).transfer(owner, refund)) {
        revert();
      }

      Revoked(addr);
  }

  // calculates the amount that has already vested but hasn't been released
  function releasableAmount(address recipient) public constant returns (uint256) {
      return vestedAmount(recipient).sub(released[recipient]);
  }


  // calculates the amount of token that have already vested
  function vestedAmount(address recipient) public constant returns (uint256) {

      if (now < unlockDate) {
        // tokens revoked before cliff, so no vested tokens can be returned
        return 0;
      }
      else if (now >= end || revoked[recipient]) {

        // all tokens have vested so return entire amount
        return allocated[recipient] * exponent;

      }

      else {

        // token vesting period has not ended
        // now we need calculate the total vested ADO tokens (we don't care here whether or not they have been released)

        uint256 duration = now.sub(start);

        if      (duration >= 630 days)  { return allocated[recipient].mul(875).div(1000); }
        else if (duration >= 540 days)  { return allocated[recipient].mul(75).div(100);  }
        else if (duration >= 450 days)  { return allocated[recipient].mul(625).div(1000); }
        else if (duration >= 360 days)  { return allocated[recipient].mul(50).div(100);  }
        else if (duration >= 270 days)  { return allocated[recipient].mul(375).div(1000); }
        else if (now >= unlockDate)     { return allocated[recipient].mul(25).div(100);  }

      }

    }

}
