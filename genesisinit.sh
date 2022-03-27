
KEY="adaovalidatorkey"
CHAINID="genesis_29-2"
MONIKER="adaovalidator"
KEYRING="os"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
TRACE="--trace"
#TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

#global change of open files limits
echo "* - nofile 500000" >> /etc/security/limits.conf
echo "root - nofile 500000" >> /etc/security/limits.conf
echo "fs.file-max = 500000" >> /etc/sysctl.conf 
ulimit -n 500000
# remove existing daemon
rm -rf ~/.genesisd*

make install

genesisd config keyring-backend $KEYRING
genesisd config chain-id $CHAINID

# if $KEY exists it should be deleted
genesisd keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
genesisd init $MONIKER --chain-id $CHAINID 

# Change consensus_params
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["consensus_params"]["block"]["max_bytes"]="1048576"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

cat $HOME/.genesisd/config/genesis.json | jq '.app_state["consensus_params"]["evidence"]["max_age_num_blocks"]="403200"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["consensus_params"]["evidence"]["max_age_duration"]="2419200000000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["consensus_params"]["evidence"]["max_bytes"]="150000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json



# Change parameter token denominations to aphoton
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="aphoton"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="aphoton"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aphoton"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="aphoton"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

cat $HOME/.genesisd/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["amount"]="50000000000000000000000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

# initial mint inflation rate set to 15%, minimal to 5%.
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["mint"]["minter"]["inflation"]="0.150000000000000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["mint"]["params"]["inflation_rate_change"]="0.150000000000000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["mint"]["params"]["inflation_min"]="0.050000000000000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

# block time (~5-7s)
cat $HOME/.genesisd/config/genesis.json | jq '.consensus_params["block"]["time_iota_ms"]="1000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

# Set gas limit in genesisl1 = 100K
cat $HOME/.genesisd/config/genesis.json | jq '.consensus_params["block"]["max_gas"]="100000000"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

# Set unbound time to 3 days
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["staking"]["params"]["unbonding_time"]="259200s"' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json

# 100 validators 
cat $HOME/.genesisd/config/genesis.json | jq '.app_state["staking"]["params"]["max_validators"]=300' > $HOME/.genesisd/config/tmp_genesis.json && mv $HOME/.genesisd/config/tmp_genesis.json $HOME/.genesisd/config/genesis.json


# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.genesisd/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.genesisd/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.genesisd/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.genesisd/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.genesisd/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.genesisd/config/config.toml
  fi
fi

# Allocate genesis accounts (cosmos formatted addresses)
genesisd add-genesis-account $KEY 21000000000000000000000000aphoton --keyring-backend $KEYRING

# Sign genesis transaction with Genesis L1 DAO validator A: adaovalidator
genesisd gentx $KEY 300000000000000000000000aphoton --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
genesisd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
genesisd validate-genesis

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
genesisd start --pruning=nothing $TRACE --log_level $LOGLEVEL --minimum-gas-prices=1000000000aphoton