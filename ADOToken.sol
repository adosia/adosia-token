pragma solidity ^0.4.19;
// author - adosiawolf - comments in grey explain the code functionality
// this smart contract demonstrates a rudamentary implementation of what Adosia refers to as "incentive tokenization"
// it's a utility

import './StandardToken.sol';
import './Pausable.sol';
import './Ownable.sol';

contract ADOToken is StandardToken, Ownable, Pausable {
  using SafeMath for uint256;

  string  public constant name        = "Adosia";
  string  public constant symbol      = "ADO";
  uint8   public constant decimals    = 18;
  uint256 public constant totalSupply = 8000000000 * (uint256(10) ** decimals);             // total ADO supply
  uint256 public constant IoTSupply   = 4100000000 * (uint256(10) ** decimals);             // ADO supply allocated to be made available for public utility usage / Adosia IoT platform access and operation
  uint256 public constant prvSupply1  = 2900000000 * (uint256(10) ** decimals);             // ADO private supply - primary wallet
  uint256 public constant prvSupply2  =  900000000 * (uint256(10) ** decimals);             // ADO private supply - secondary wallet
  uint256 public oppSupply = totalSupply.sub(IoTSupply).sub(prvSupply1).sub(prvSupply2);    // ADO operational wallet

  address public fundWallet;                                                                // wallet address which will receive any cryptocurrency funds from tokens sold to whitelisted Adosia IoT customers
  address public IoTWallet;                                                                 // Adosia address owning the public supply of tokens
  address public oppWallet;                                                                 // Adosia operational wallet
  address public prvWallet1;                                                                // private wallet - primary addresss
  address public prvWallet2;                                                                // private wallet - secondary address

  // wicked IoT
  struct DynamicProfiles {
    bytes32   profileKey;
    uint8     profileStartHour;
    uint8     profileStartMinute;
    uint8     profileEndHour;
    uint8     profileEndMinute;
  }

  struct LicensePackage {
    bool    profileLicenseEnable;               // disable to retire package
    bool    profileResaleLicenseEnable;
    uint8   profileResaleCommissionPercent;
    unit256 profileResaleMinLicenseCost;
    unit256 profileDeviceLicenseQuantity;
    unit256 profileDeviceLicenseCost;
  }

  struct DeviceProfile {
    bytes32 profileKey;
    address profileCreatorOwnerAddress;
    address profileCurrentOwnerAddress;
    uint256 userCount;
    uint256 deviceCount;
    string profileJSON;
    bytes32[] licensePackageKeys;
  }

  struct Device {
    bool    binaryLock;
    bytes32 binaryHash;
    bytes32 licenseKey;
    address deviceOwnerAddress;
    DynamicProfiles[] dynamicProfiles;
  }

  struct UserLiceses {

    // license purchase details, how many devices assigned, etc


  }

  struct User {
    bytes32 userKey;
    Device[] userDevices;
    UserLiceses[] userLicenses;
  }

  mapping (bytes32 => DeviceProfile)      private profiles;
  mapping (bytes32 => AvailableLicenses)  public availableLicenses;
  mapping (bytes32 => UserLicenses)       private userLicenses;
  mapping (bytes32 => Device)             private devices;

  mapping (address => User)               public users;
  mapping (address => uint256)            public enterpriseWhiteList;       // whitelist for enterprise / direct customers to enable direct token purchases



  // paramerters for IoT device profile marketplace

  uint public maxTokensAllowed  = 50000;         // max tokens non-whitelisted customers can store within Adosia account
  uint public conversionRate    = 20000;         // token sale base rate: 1 ETH : 1250 ADO  => conversionRate
  bool cryptoSaleEnable         = true;          // flag to enable sales via cryptocurrencies
  bool secureIoTFlag = true;                     // flag to enable securing IoT device profiles via this contract - will possibly disable once individual IoT devices move to tokenized representations
  uint mult = 100;                               // token bonus % multiplier


  function ADOToken(address _vaultWallet, address _IoTWallet, address _oppWallet, address _prvWallet1, address _prvWallet2) public {
      vaultWallet = _vaultWallet;    /* Adosia primary wallet for storing ADA currency */
      IoTWallet   = _IoTWallet;     /* Adosia public wallet address for storing ADO */
      oppWallet   = _oppWallet;     /* Adosia operational wallet address for storing ADO */
      prvWallet1  = _prvWallet1;    /* Adosia private wallet address for storing ADO */
      prvWallet2  = _prvWallet2;    /* Adosia private wallet address for storing ADO */


      // send majority of tokens to Adosia public sale wallet
      balances[IoTWallet] = IoTSupply;
      Transfer(0x0, IoTWallet, IoTSupply);

      // send 18% of tokens to Adosia vault wallet to hold for vesting
      balances[prvWallet1] = prvSupply1;
      Transfer(0x0, prvWallet1, prvSupply1);

      balances[prvWallet2] = prvSupply2;
      Transfer(0x0, prvWallet2, prvSupply2);

      // distribute remaining tokens to Adosia operational wallet
      balances[oppWallet] = oppSupply;
      Transfer(0x0, oppWallet, oppSupply);
  }


  // default function executed on payment receipt
  function () external payable {
      buyADO(msg.sender);
  }


  function buyADO(address buyer) public whenNotPaused enableCryptoSale(cryptoSaleEnable) payable {

      //require account to be actively enabled for cryptocurrencies?

      uint256 myTokens = msg.value.mul(conversionRate).mul(mult).div(100);
      require(preventExceedingTokenLimit(buyer, myTokens));

      vaultWallet.transfer(msg.value);                          // immediately transfer ether (ADA in production) receieved back home
      balances[IoTWallet] = balances[IoTWallet].sub(myTokens);  // subtract amount of purchased tokens from IoTWallet token balance
      balances[buyer]     = balances[buyer].add(myTokens);      // add amount of purchased tokens to buyer walleet token balance
      Transfer(IoTWallet, buyer, myTokens);                     // log transfer event to transfer ADO tokens purchased out of IoTWallet and into buyerWallet
  }

  function adminBuyADOApp(address buyer, uint256 tokenPurchaseCount) external onlyOwner preventExceedingTokenLimit(buyer, tokenPurchaseCount) {
      balances[IoTWallet] = balances[IoTWallet].sub(tokenPurchaseCount);  // update IoTWallet balance to reflect decremented tokens to be transferred to buyer wallet
      balances[buyer] = balances[buyer].add(tokenPurchaseCount);          // update buyer wallet balance with newly purchased tokens
      Transfer(IoTWallet, buyer, tokenPurchaseCount);                     // log transfer event
  }


  function transfer(address _to, uint _value) public returns (bool) {
      require(_to != 0x0);
      return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }



  function saveIoTDeviceProfile(string _profile_json, string _profile_key) {

      require(profileInit[_profile_key] == false || profileCreatorOwnerAddress[_profile_key] == msg.sender);
      profileInit[_profile_key]  = true;

      profileJSON[_profile_key]  = _profile_json;
      profileCreatorOwnerAddress[_profile_key] = msg.sender;

      profileCurrentOwnerAddress[_profile_key] = msg.sender;

      profilePerDeviceSaleEnable[_profile_key] = ;
      profilePerDeviceSaleCost;

      mapping (bytes32 => bool)    public profileMultiDeviceSaleEnable;
      mapping (bytes32 => uint8)   public profileMultiDeviceSaleQuantity;
      mapping (bytes32 => uint256) public profileMultiDeviceSaleCost;

      mapping (bytes32 => bool)    public profileResaleEnable;
      mapping (bytes32 => uint8)   public profileResaleCommissionPercent;

  }

  /* this function allows adosia to update the maximum number of tokens that can be purchased at any given time */
  function updateMaxTokensAllowed(uint _maxTokensAllowed) external onlyOwner returns (bool) {
      maxTokensAllowed = _maxTokensAllowed;
      return true;
  }

  /* this function allows adosia to update the conversion rate pricing (adosia tokens per revenue received) */
  function updateConversionRate(uint _conversionRate) external onlyOwner returns (bool) {
      conversionRate = _conversionRate;
      return true;
  }

  function updateEnterpriseWhitelist(address _address, uint256 _newLimit) external onlyOwner returns (bool) {
      enterpriseWhiteList[_address] = _newLimit;
      return true;
  }

  function returnEnterpriseWhitelist(address _address) external constant returns (uint256) {
      return enterpriseWhiteList[_address];
  }

  function udpateSecureIoTProfileEnable(bool _secureIoTFlag) external onlyOwner returns (bool) {
      secureIoTFlag = _secureIoTFlag;
      return true;
  }

  function updateEnableCryptoSale(bool _cryptoSaleEnable) external onlyOwner returns (bool) {
      cryptoSaleEnable = _cryptoSaleEnable;
      return true;
  }

  function returnIsCryptoSaleOpen() external onlyOwner returns (bool) {
      return cryptoSaleOpenEnable;
  }


  function getTokenLimit(address _address) internal constant returns (uint256) {

    if (enterpriseWhiteList[_address] > 0) {
      return enterpriseWhiteList[_address];
    }
    else {
      return maxTokensAllowed;
    }
  }

  function returnAllowedTokenPurchaseLimit(address _address) external constant returns (uint256) {
    uint256 tokenLimit = getTokenLimit(_address);
    return tokenLimit.sub(balances[_address]);
  }


  /* though we check manually via returnAllowedTokenPurchaseLimit() before allowing purchase, this is an additional safeguard */
  modifier preventExceedingTokenLimit(address _address, uint256 _purchasedTokens) {
    uint256 tokenLimit = getTokenLimit(_address);
    /* make this address is permitted to purcahse the amount of desired tokens */
    /* make sure enough tokens åre stored in IoTWallet before allowing tokens to be purchased */
    require(balances[_address].add(_purchasedTokens) <= tokenLimit && _purchasedTokens <= tokenLimit && balances[IoTWallet] >= _purchasedTokens);
    _;
  }


  modifier enableCryptoSale(bool _isSaleOpen) {
    require(_isSaleOpen);      // make sure cryptoSaleOpenEnable flag is set to true
    _;
  }

}
