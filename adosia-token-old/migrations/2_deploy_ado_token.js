const ADOToken = artifacts.require('./ADOToken.sol');
const ADOVault = artifacts.require('./ADOVault.sol');

module.exports = function (deployer, network, accounts) {

    console.log('Adosia deploying ADO...');

    let saleStartTime;
    let poolWallet;
    let oppWallet;
    let vaultWallet;
    let prvWallet;
    let allocated;
    let oppAmount;
    let vaultAmount;
    let prvAmount;

    oppAmount    = 160000000000000000000000000;   // 160M w/ 18 decimals
    vaultAmount = 1440000000000000000000000000;   // 1.4B w/ 18 decimals
    prvAmount   =  437500000000000000000000000;   // 437.5M w/ 18 decimals

    if (network == 'development') {
      saleStartTime = 0;                  // now + 120 seconds
      poolWallet  = '0x627306090abaB3A6e1400e9345bC60c78a8BEf57';
      oppWallet   = '0xf17f52151EbEF6C7334FAD080c5704D77216b732';
      vaultWallet = '0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef';
      prvWallet   = '0x821aEa9a577a9b44299B9c15c88cf3087F3b5544';
      allocated   = [
                      '0x821aEa9a577a9b44299B9c15c88cf3087F3b5544',   // 800,000,000
                      '0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5',   // 360,000,000
                      '0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5',   // 200,000,000
                      '0x6330A553Fc93768F612722BB8c2eC78aC90B3bbc',   // 40,000,000
                      '0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE'    // 40,000,000
                    ];

    } else if (network == 'rinkeby') {
      saleStartTime = 0;                 // now + 120 seconds
      poolWallet  = '0xA7FeA0a10783F1f0C8f7DA27559075c8FaE2c943';
      oppWallet   = '0x69A364B682CD84E54012Bef57091dc079359B97D';
      vaultWallet = '0xb1694955Cf826e5DA469eb9775572f67Bd49E580';
      prvWallet   = '0xFa538EFCe3d1C3f84Edc5C5Cc3E7B88869bc5E2f';
      allocated   = [
                      '0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2',   // 800,000,000
                      '0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5',   // 360,000,000
                      '0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5',   // 200,000,000
                      '0x6330A553Fc93768F612722BB8c2eC78aC90B3bbc',   // 40,000,000
                      '0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE'    // 40,000,000
                    ];
    }/*
     else if (network == "live") {
      saleStartTime = 1523887200;          // April 16, 2018 2:00:00 PM UTC
      poolWallet    = '0xd90707E875D62779250c4455A5B8D34F525dC401';
      oppWallet     = '0xdf95Dda9Cc42fED246a5e91058a29540036c3a5f';
      vaultWallet   = '0xf5eDe4b45cB203750002CB822BE17272A27b700E';
      prvWallet     = '0x74855A08a0fd0A4edC6d3141d6199c74A95D3100';
      allocated   = [
                      '0xD7925cbB926135B2d8F13D5F0D1d21AFbF8B67bB',   // 800,000,000
                      '0xdAC352887B1bA00B1a7Ab72043Ae34c965ed468d',   // 360,000,000
                      '',   // 200,000,000
                      '',   // 40,000,000
                      ''    // 40,000,000
                    ];
    }*/

    deployer.deploy(ADOToken, poolWallet, vaultWallet, oppWallet, prvWallet, saleStartTime)
      .then(function () {
        deployer.deploy(ADOVault, vaultWallet, allocated, saleStartTime);
      });

  };
