pragma solidity ^0.4.19;
// author - adosiawolf

// hey Kyle here - coments in grey explain the code functionality
// find me on git or twitter (@adosiawolf) with questions, comments or feedback


import './StandardToken.sol';
import './Pausable.sol';
import './Ownable.sol';

contract ADOToken is StandardToken, Ownable, Pausable {
  using SafeMath for uint256;

  string public constant name = "Adosia";
  string public constant symbol = "ADO";
  uint8 public constant decimals = 18;
  uint256 public totalSupply           = 8000000000 * (uint256(10) ** decimals);             // total ADO supply
  uint256 public constant publicSupply = 5962500000 * (uint256(10) ** decimals);             // reserve ADO supply for public token sale
  uint256 public constant privateRSVP  =  437500000 * (uint256(10) ** decimals);             // reserve ADO supply for private sale activity already conducted (will be locked for privateBuyLockPeriod)
  uint256 public constant oppSupply    =  160000000 * (uint256(10) ** decimals);             // reserve ADO supply for immediate adosia operations (incentives/bounties)
  uint256 public vaultSupply  = totalSupply.sub(privateRSVP).sub(publicSupply).sub(oppSupply);   // reserve ADO sent to vault to hold for vesting periods


  // change to "hours" and "minutes" to "weeks" for production
  uint constant public privateBuyLockPeriod = 4 hours;

  uint public conversionRate = 12500;                                                            // token discount sale base rate: 1 ETH : 1250 ADO  => conversionRate
  mapping (address => bool) public earlyLocklist;
  mapping (address => uint256) public purchaseAmount;

  uint256 public publicSoldPresale = 0;   // total ether raised during public presale (in wei)
  uint256 public publicSoldStage1  = 0;   // total ether raised during public discount sale stage 1 (in wei)
  uint256 public publicSoldStage2  = 0;   // total ether raised during public discount sale stage 2 (in wei)
  uint256 public publicSoldStage3  = 0;   // total ether raised during public discount sale stage 3 (in wei)
  uint256 public publicSoldStage4  = 0;   // total ether raised during public discount sale stage 4 (in wei)


  /****************************************************************************************************************************/
  /***************************************************** ADOSIA SETTINGS ******************************************************/
  /****************************************************************************************************************************/
  // UNCOMMENT FOR PRODUCTION - BEGIN
  /*

  uint256 public scale            = 1 days;
  uint256 public durationSeconds  = 8 * 7 * 24 * 3600;  // total campaign duration of 8 weeks

  // ether cap on funds raised during each stage
  uint256 public publicCapPresale = 40000 ether;       // total cap on public funds raised during public super discount presale (in wei)
  uint256 public publicCapStage1  = 40000 ether;       // total cap on public funds raised during public discount sale stage 1 (in wei)
  uint256 public publicCapStage2  = 30000 ether;       // total cap on public funds raised during public discount sale stage 2 (in wei)
  uint256 public publicCapStage3  = 50000 ether;       // total cap on public funds raised during public discount sale stage 3 (in wei)
  uint256 public publicCapStage4  = 50000 ether;       // total cap on public funds raised during public discount sale stage 4 (in wei)
  */
  // UNCOMMENT FOR PRODUCTION - END
  /****************************************************************************************************************************/
  /****************************************************************************************************************************/
  // COMMENT OUT FOR PRODUCTION - BEGIN

  uint256 public scale            = 1 minutes;      // compresses timing for public discount sale test
  uint256 public durationSeconds  = 3360;           // total campaign duration of 56 minutes (3360 = 56 minutes;  201600 = 56 hours)

  // ether cap on funds raised during each stage
  uint256 public publicCapPresale = 25 ether;       // total cap on public funds raised during public super discount presale (in wei)
  uint256 public publicCapStage1  = 25 ether;       // total cap on public funds raised during public discount sale stage 1 (in wei)
  uint256 public publicCapStage2  = 25 ether;       // total cap on public funds raised during public discount sale stage 2 (in wei)
  uint256 public publicCapStage3  = 25 ether;       // total cap on public funds raised during public discount sale stage 3 (in wei)
  uint256 public publicCapStage4  = 25 ether;       // total cap on public funds raised during public discount sale stage 4 (in wei)
  // COMMENT OUT FOR PRODUCTION - END
  /****************************************************************************************************************************/
  /****************************************************************************************************************************/

  uint256 public startTimestamp;                       // timestamp after which public discount sale will start
  address public poolWallet;                           // address which will receive raised funds and owns the public supply of tokens
  address public vaultWallet;                          // address which will receive funds to be locked and released monthly over a 2 year period
  address public oppWallet;                            // address which will receive tokens available for immediate distribution and bounties
  address public prvWallet;                            // address to send 437.5M tokens for private sale funding

  function ADOToken(address _poolWallet, address _vaultWallet, address _oppWallet, address _prvWallet, uint256 _startTimestamp) public {
      poolWallet = _poolWallet;       /* ADO pool wallet address */
      vaultWallet = _vaultWallet;     /* ADO vault wallet address */
      oppWallet   = _oppWallet;       /* ADO operational bank wallet address */
      prvWallet   = _prvWallet;       // transfering

      if (_startTimestamp > 0)
        startTimestamp = _startTimestamp;

      else
        startTimestamp = now + 5 seconds;

        // send majority of tokens to Adosia public sale wallet
      balances[poolWallet] = publicSupply;
      Transfer(0x0, poolWallet, publicSupply);

      // send 18% of tokens to Adosia vault wallet to hold for vesting
      balances[vaultWallet] = vaultSupply;
      Transfer(0x0, vaultWallet, vaultSupply);

      // send 2% of tokens to Adosia operations wallet for securing
      balances[oppWallet] = oppSupply;
      Transfer(0x0, oppWallet, oppSupply);

      // send remaining reserved tokens to Adosia wallet for private sale distribution
      balances[prvWallet] = privateRSVP;
      Transfer(0x0, prvWallet, privateRSVP);
  }


  // default function executed on payment receipt
  function () external payable {
    buyADO(msg.sender);
  }


  function buyADO(address buyer) public isDiscountOpen whenNotPaused payable {

      if (now <= (startTimestamp + durationSeconds)) {
          // require msg.sender pintended purchase summed with past purchased will equal less than 20 ether (only during discount sale)
          require(purchaseAmount[msg.sender].add(msg.value) <= 20 ether);
      }

      uint mult = 100;

      // +400% bonus token during 1st week of discount sale (public presale)
      if (now <= startTimestamp + scale.mul(7)) {
         publicSoldPresale = publicSoldPresale.add(msg.value);
         mult = 500;
      }

      // +125% bonus token during 2nd week of discount sale (public sale stage 1)
      else if (now > (startTimestamp + scale.mul(7)) && now <= (startTimestamp + scale.mul(14)) ) {
         publicSoldStage1 = publicSoldStage1.add(msg.value);
         mult = 225;
      }

      // +100% bonus token during 3rd week of discount sale (public sale stage 2)
      else if (now > (startTimestamp + scale.mul(14)) && now <= (startTimestamp + scale.mul(21)) ) {
         publicSoldStage2 = publicSoldStage2.add(msg.value);
         mult = 200;
      }

      // +50% bonus token during 4th week of discount sale (public sale stage 3)
      else if (now > (startTimestamp + scale.mul(21)) && now <= (startTimestamp + scale.mul(28)) ) {
         publicSoldStage3 = publicSoldStage3.add(msg.value);
         mult = 150;
      }

      else if (now > (startTimestamp + scale.mul(28)) && now <= (startTimestamp + durationSeconds) ) {
        // 0% bonus token during ongoing sale
        publicSoldStage4 = publicSoldStage4.add(msg.value);
      }


      // calculate how many tokens are being purchased
      uint256 myTokens = calculateTokensBought(msg.value, mult);

      // require the number of tokens stored in adosia token public wallet be greater than the tokens being purchased
      require(balances[poolWallet] >= myTokens);

      balances[poolWallet] = balances[poolWallet].sub(myTokens);
      balances[buyer] = balances[buyer].add(myTokens);

      // immediately transfer ether receieved back home
      poolWallet.transfer(msg.value);

      // now transfer out ADO tokens purchased
      Transfer(poolWallet, buyer, myTokens);
      purchaseAmount[msg.sender] = purchaseAmount[msg.sender].add(msg.value);
  }


  function calculateTokensBought(uint256 weiAmount, uint mult) public constant returns(uint256) {
      // token discount sale base rate: 1 ETH : 12500 ADO  => conversionRate
      uint256 myTokens = weiAmount.mul(conversionRate);
      return myTokens.mul(mult).div(100);
  }


  function transfer(address _to, uint _value) public isDiscountFinished(_to) isLockTimeEnded(msg.sender) returns (bool) {
      require(_to != 0x0);
      return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public isDiscountFinished(_to) isLockTimeEnded(_from) returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }


  function updateADOTokenPrice(uint _rate) external onlyOwner returns (bool) {
      // this function allows adosia to update the price for which we sell ADO directly to users down the road
      // discount period must have ended and privateBuyLockPerioud must have passed before adosia can update direct-sale token price to sell to users
      require (now > (startTimestamp + durationSeconds + privateBuyLockPeriod) );
      conversionRate = _rate;
      return true;
  }


  function editWhitelist(address _address, bool isLocked) external onlyOwner returns (bool) {
      earlyLocklist[_address] = isLocked;
      return true;
  }


  modifier isDiscountOpen() {
      require(now >= startTimestamp);

      // evaluate if discount sale is still occurring before utilizing extensive require
      if (now <= (startTimestamp + durationSeconds)) {
        // make sure cap for each ADO discount sale stage is not yet met
        require(
          (now <= (startTimestamp + scale.mul(7)) && publicCapPresale >= publicSoldPresale.add(msg.value))                                                // public presale       (1 week duration)
          || (now > (startTimestamp + scale.mul(7)) && now <= (startTimestamp + scale.mul(14)) && publicCapStage1 >= publicSoldStage1.add(msg.value))     // stage 1 public sale  (1 week duration)
          || (now > (startTimestamp + scale.mul(14)) && now <= (startTimestamp + scale.mul(21)) && publicCapStage2 >= publicSoldStage2.add(msg.value))    // stage 2 public sale  (1 week duration)
          || (now > (startTimestamp + scale.mul(21)) && now <= (startTimestamp + scale.mul(28)) && publicCapStage3 >= publicSoldStage3.add(msg.value))    // stage 3 public sale  (1 week duration)
          || (now > (startTimestamp + scale.mul(28)) && now <= (startTimestamp + durationSeconds) && publicCapStage4 >= publicSoldStage4.add(msg.value))  // stage 4 public sale  (4 weeks duration)
        );
      }
      _;
  }


  modifier isDiscountFinished(address sendto) {

      // allow ability to send funds from opps wallet and and private wallet
      if (msg.sender != oppWallet && msg.sender != prvWallet && msg.sender != poolWallet) {
        require(now >= (startTimestamp + durationSeconds));
      }
      else if (now <= (startTimestamp + durationSeconds)) {
        // msg.sender is adosia address - so
        // automatically lock any tokens sent out from private or operations wallets prior to the token hold period ending
        earlyLocklist[sendto] = true;
      }
      _;
  }


  modifier isLockTimeEnded(address from) {

    if (earlyLocklist[from]) {
          require(now > startTimestamp + durationSeconds + privateBuyLockPeriod);
    }
    _;
  }


}
