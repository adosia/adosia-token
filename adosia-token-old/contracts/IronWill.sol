pragma solidity ^0.4.19;
// author - adosiawolf
// hey Kyle here - comments in grey explain the code functionality
// find me on git or twitter (@adosiawolf) with questions, comments or feedback

/********  IRON WILL  ********/
/*
  The world is a complex and full of intricate relationships, casual interaction and chaos.

  This IRON WILL (IR) smart contract enables:

    - an immutable execution of intent
    - and execution of benefactor estate fund distributions to beneficiaries
    - a benefactor to designate estate allocations for multiple beneficiaries
    - beneficiary funds released upon occurrance (or lack thereof) of specific conditions
    - no human delay or interference in executing contract terms / functionality


  To initiate an Iron Will smart contract and create a new benefactor account:
    - visit https://ironwill.io and review current minimum ETH amount required to start a new IR benefactor contract
    - send that minimum ETH start amount to the IR Contract address pinned at the top of the Iron Will Telegram Channel.
      - if telegram


    ETH to the IRON Will Contract as
    - benefactors and beneficiaries
    - beneficiary funds released upon occurrance (or lack thereof) of specific conditions
    - no human delay or interference in executing contract terms / functionality
*/


import './StandardToken.sol';
import './Pausable.sol';
import './Ownable.sol';

contract IronWill is StandardToken, Ownable, Pausable {

  using SafeMath for uint256;

  string public constant name = "Iron Will";
  string public constant symbol = "IRON";
  uint8 public constant decimals = 18;
  uint256 public totalSupply             =   1000000 * (uint256(10) ** decimals);  // total IRON supply = 50M
  uint256 public constant publicSupply   =   38000000 * (uint256(10) ** decimals);  // reserve 38M IRON supply to send to customers
  uint256 public constant privateSupply  =   12000000 * (uint256(10) ** decimals);  // reserve 12M IRON supply to send to home


  uint256 public ironStartCost          = 500 finney;                         // 0.5 ETH / min amount in wei that must be sent to contract in order to start/create a new iron will
  uint256 public minADOForRebate        = 3125 * (uint256(10) ** decimals);   // min amount of ADO needed to initate rebate on initial fees associated with initial ironwill account creation

  uint256 public rebateETHForADO        = 250 finney;                         // 0.25 ETH / amount in wei to send as rebate in response to ADO being sent to contract from an existing account holder address that has not previously recieved a rebate
  uint256 public newAccountRewardIRON   = 1 * (uint256(10) ** decimals);    // reward 1 IRON for each new accont until no IRON is available to reward or feature is disabled

  uint public initialBeneficiaries      = 2;                                  // two (2) beneficiaries per account allowed to start

  bool public imposeNewBeneficiaryCost           = true;      // reserve ability to disable imposing costs for adding extra beneficiaries
  bool public startDiscountAcceptADO             = true;      // reserve ability to disable accepting ADO for discount on new iron will contracts
  bool public newBeneficiaryAcceptADO            = true;      // reserve ability to disable accepting ADO for discounts

  // master toggle for abiliut to distrinute an IRON token for each contract interaction
  bool public rewardBenefactorOnNewBenefactorAccount    = false;    // reserve ability to toggle IR's ability to reward one IRON token for each new account contract intiated
  bool public rewardBenefactorOnBenefactorContribute    = false;    // reserve ability to toggle IR's ability to reward one IRON to benefactor when benfactor makes an additional contribution to existing account
  bool public rewardBeneficiaryOnBeneficiaryWithdrawl   = false;    // reserve ability to toggle IR's ability to reward one IRON to beneficiary when beneficiary successfully withdrawls / claims their respective contract allocation
  bool public enableBenefactorAccountPortFee            = true;    // reserve ability to toggle disabling charing benecator a fee for poritng account


  uint256 public newBeneficiaryCostETH    = 250 finney;                         // 0.25 ETH cost for each additinal beneficiary
  uint256 public newBeneficiaryCostADO    = 250 * (uint256(10) ** decimals);   // optional use x2500 ADO as alternative payment for extra beneficiary upgrade
  uint256 public newBeneficiaryCostIRON   =   2 * (uint256(10) ** decimals);   // optional use x2 IRON as alternative payment  for extra beneficiary upgrade

  uint public withdrawlFeeRateNormal      = 1;           // 1% fee contract charges upon distributing beneficiary payout (will divide by 100 later)
  uint public withdrawlFeeRateSpecial     = 6;           // 0.6% special discount fee contract charges upon distributing beneficiary payout (will divide 6 by 1000 later to get 0.6%)
  uint public cancelPortFeeRate           = 2;           // 2% fee contract charges upon canceling contract (98% remaining balance or beneficiary balance returned to benefactor, 2% to IRON/ADOSIA address)

  // amount of time after creation of a new IR contract a benefactor will be alloted to receive a discount rebate refund in ETH
  // benefactor must send ADO (amount specificed on ironwill.io) using the same ETH address used to start the IR contract

  uint256 startRebateExpireTime           = 10 days;
  uint256 startRebateValue;


  //mapping (address => address) public accountOwner;         // address of account owner
  mapping (address => uint)    public accountType;            // integer determining user account type (0 for benefactor, 1 for beneficiary, 2 for both?)
  mapping (address => bool)    public startRebateIssued;      // boolean flag to determine if rebate (associated with initial setup) has been issued (ADO sent to account from admin account address)
  mapping (address => uint256) public startRebateExpire;      // rebate expired
  mapping (address => bool)    public discountWithdrawl;      // boolean flag to determine if the special discount will be applied upon account withdrawl by beneficiary
  mapping (address => uint256) public estateBalance;          // total amount of estate
  mapping (address => uint256) public balanceADO;             // ADO balance
  mapping (address => uint256) public balanceIRON;            // IRON balance
  mapping (address => int)     public beneficiaryCount;       // number of beneficiaries (6 max per account)
  mapping (address => bool)    public enableAccountPortFee;   // ability to enable / disable fee associated with canceling individual account (used to allow special cased of porting or terminiated contract withouth disabled the feature for all IR contracts)

  // support up to 6 beneficiaries
  mapping (address => address) public beneficiaryAddress01;      // address of beneficiary 1        (primary beneficiary for unallocated funds)
  mapping (address => uint8)   public beneficiaryPercent01;      // beneficiary 01 percent
  mapping (address => address) public beneficiaryAddress02;      // address of beneficiary 2
  mapping (address => uint8)   public beneficiaryPercent02;      // beneficiary 02 percent
  mapping (address => address) public beneficiaryAddress03;      // address of beneficiary 3
  mapping (address => uint8)   public beneficiaryPercent03;      // beneficiary 03 percent
  mapping (address => address) public beneficiaryAddress04;      // address of beneficiary 4
  mapping (address => uint8)   public beneficiaryPercent04;      // beneficiary 04 percent
  mapping (address => address) public beneficiaryAddress05;      // address of beneficiary 5
  mapping (address => uint8)   public beneficiaryPercent05;      // beneficiary 05 percent
  mapping (address => address) public beneficiaryAddress06;      // address of beneficiary 6
  mapping (address => uint8)   public beneficiaryPercent06;      // beneficiary 06 percent


  address public ethWallet;     // address which will receive raised funds and owns the public supply of tokens
  address public ironWallet;    // address which will receive funds to be locked and released monthly over a 2 year period
  address public wolfWallet;    // address which will receive tokens available for immediate distribution and bounties


  function IronWill(address _ethWallet, address _ironWallet, address _wolfWallet) public {

      ethWallet  = _ethWallet;      /* Adosia home wallet where revenue is sent accepted */
      ironWallet = _ironWallet;     /* iron will main vault wallet address where rebates are reserved stored */
      wolfWallet = _wolfWallet;     /* private wallet address */

      withdrawlFeeRateNormal    = withdrawlFeeRateNormal.div(100);      // initial value set above
      withdrawlFeeRateSpecial   = withdrawlFeeRateSpecial.div(1000);    // initial value set above
      cancelPortFeeRate         = cancelPortFeeRate.div(100);           // initial value set above

      startRebateValue = ironStartCost.div(5);                          // divide by 5 to enable a 20% discount

      // send public supply tokens to iron wallet for distribution
      balances[ironWallet] = publicSupply;
      Transfer(0x0, ironWallet, publicSupply);

      // send private supply tokens to private wallet for distribution
      balances[wolfWallet] = privateSupply;
      Transfer(0x0, wolfWallet, privateSupply);
  }


  // default function executed on receipt of ether
  function () external payable { startIRON(msg.sender); }


  function startIRON(address buyer) public whenNotPaused payable {

    // money being sent to account

    if (accountType[buyer] > 0) {

        // an iron will account exists for the sending address, so we should interact with the request and allow adding money

        // add msg.value to IRON account ETH balance
        balances[ironWallet] = balances[ironWallet].sub(newAccountRewardIRON);
    }



    else {

      // brand new iron will contract, so we need to require the payment value be greater than the start fee
      require(msg.value >= ironStartCost);

      // if we get here then the payment has been accepted
      ethWallet.transfer(msg.value.sub(startRebateValue));  // immediately transfer half of contract start cost (in ether) back home - this is free and clear adosia revenue
      ironWallet.transfer(startRebateValue);                // immediately transfer all remaining ether to iron wallet for safekeeping (includes half of setup fee for potential rebate)
      estateBalance[buyer] = msg.value.sub(ironStartCost); // set estate balance the difference of msg.value and contract start cost

      accountType[buyer] = 1;
      startRebateIssued[buyer] = false;
      discountWithdrawl[buyer] = false;

      // zero the balances for account
      balanceADO[buyer] = 0;
      balanceIRON[buyer] = 0;

      // initialize beneficiaries to buyer address as default
      beneficiaryAddress01[buyer] = buyer;    // address of beneficiary 1        (primary beneficiary for unallocated funds)
      beneficiaryPercent01[buyer] = 100;      // beneficiary 01 percent
      beneficiaryAddress02[buyer] = buyer;    // address of beneficiary 2
      beneficiaryPercent02[buyer] = 0;        // beneficiary 02 percent
      beneficiaryAddress03[buyer] = buyer;    // address of beneficiary 3
      beneficiaryPercent03[buyer] = 0;        // beneficiary 03 percent
      beneficiaryAddress04[buyer] = buyer;    // address of beneficiary 4
      beneficiaryPercent04[buyer] = 0;        // beneficiary 04 percent
      beneficiaryAddress05[buyer] = buyer;    // address of beneficiary 5
      beneficiaryPercent05[buyer] = 0;        // beneficiary 05 percent
      beneficiaryAddress06[buyer] = buyer;    // address of beneficiary 6
      beneficiaryPercent06[buyer] = 0;        // beneficiary 06 percent


      // send IRON reward for newly created benefactor account (require promotion to be actve and IRON to be available)
      require(balances[ironWallet] >= newAccountRewardIRON && rewardBenefactorOnNewBenefactorAccount);    // require the number of tokens stored in adosia token public wallet be greater than the tokens being purchased
      balances[ironWallet] = balances[ironWallet].sub(newAccountRewardIRON);              // adjust balances
      balances[buyer] = balances[buyer].add(newAccountRewardIRON);
      Transfer(ironWallet, buyer, newAccountRewardIRON);                                  // now transfer out IRON token bonus rebate

      // account setup is complete - now new user shoud be able to interact with account

    }

  }


  function transfer(address _to, uint _value) public returns (bool) {
      require(_to != 0x0);
      return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }


  function updateIronStartCost(uint256 _newCost) external onlyOwner returns (bool) {
      ironStartCost = _newCost.div(100).mul(1 ether);
      return true;
  }


  function updateADOForRebate(uint256 _amountADO) external onlyOwner returns (bool) {
      minADOForRebate = _amountADO * (uint256(10) ** decimals);
      return true;
  }


  function updateRebateETHForADO(uint256 _ethRebate) external onlyOwner returns (bool) {
      rebateETHForADO = _ethRebate.div(100).mul(1 ether);
      return true;
  }


  function updateNewAccountRewardIRON(uint256 _rewardIRON) external onlyOwner returns (bool) {
      newAccountRewardIRON = _rewardIRON * (uint256(10) ** decimals);
      return true;
  }


  function updateInitialBeneficiaries(uint _count) external onlyOwner returns (bool) {
      initialBeneficiaries = _count;
      return true;
  }



  function updateEnableNewAccountIronReward(bool _enable) external onlyOwner returns (bool) {
      rewardBenefactorOnNewBenefactorAccount = _enable;
      return true;
  }

  function updateEnableBenefactorRewardOnBenefactorContribute(bool _enable) external onlyOwner returns (bool) {
      rewardBenefactorOnBenefactorContribute = _enable;
      return true;
  }


  function updateEnableBeneficiaryRewardOnBeneficiaryWithdrawl(bool _enable) external onlyOwner returns (bool) {
      rewardBeneficiaryOnBeneficiaryWithdrawl = _enable;
      return true;
  }

  function updateEnableBenefactorAccountPortFee(bool _enable) external onlyOwner returns (bool) {
      enableBenefactorAccountPortFee = _enable;
      return true;
  }

  function updateEnableImposeNewBeneficiaryCost(bool _enable) external onlyOwner returns (bool) {
      imposeNewBeneficiaryCost = _enable;
      return true;
  }


  function updateEnableStartDiscountAcceptADO(bool _enable) external onlyOwner returns (bool) {
      startDiscountAcceptADO = _enable;
      return true;
  }


  function updateEnableNewBeneficiaryAcceptADO(bool _enable) external onlyOwner returns (bool) {
      newBeneficiaryAcceptADO = _enable;
      return true;
  }


  function updateNewBeneficiaryCostETH(uint256 _costETH) external onlyOwner returns (bool) {
      newBeneficiaryCostETH = _costETH.div(100).mul(1 ether);
      return true;
  }


  function updateNewBeneficiaryCostADO(uint256 _costADO) external onlyOwner returns (bool) {
      newBeneficiaryCostADO = _costADO * (uint256(10) ** decimals);
      return true;
  }


  function updateNewBeneficiaryCostIRON(uint256 _costIRON) external onlyOwner returns (bool) {
      newBeneficiaryCostIRON = _costIRON * (uint256(10) ** decimals);
      return true;
  }


  function updateWithdrawlFeeRateNormal(uint _rate) external onlyOwner returns (bool) {
      initialBeneficiaries = _rate;
      return true;
  }


  function updateWithdrawlFeeRateSpecial(uint _rate) external onlyOwner returns (bool) {
      withdrawlFeeRateSpecial = _rate;
      return true;
  }


  function updateCancelPortFeeRate(uint _rate) external onlyOwner returns (bool) {
      cancelPortFeeRate = _rate;
      return true;
  }


  function updateRebateExpireTime(uint256 _time) external onlyOwner returns (bool) {
      startRebateExpireTime = _time.mul(1 days);
      return true;
  }

}
