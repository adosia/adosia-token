module.exports = {

  networks: {

    development: {
      host: 'localhost',
      port: 7545,
      network_id: '*',
      from: '0x627306090abaB3A6e1400e9345bC60c78a8BEf57',
      gasPrice: 25000000000,
      gas:  4600000
    },

    rinkeby: {
      host: 'localhost',
      port: 8545,
      network_id: 4,
      from: '0xA7FeA0a10783F1f0C8f7DA27559075c8FaE2c943',
      gas:  4612388 // gas limit used for deploys
    },

    live: {
      host: 'localhost',
      port: 8545,
      network_id: 1,
      gasPrice: 25000000000,
      gas:  4712388,
      from: '0xd90707E875D62779250c4455A5B8D34F525dC401'
    }



  }

};
