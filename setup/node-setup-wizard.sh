#!/bin/bash
cat << "EOF"

  /$$$$$$                                          /$$                 /$$         /$$       
 /$$__  $$                                        |__/                | $$       /$$$$       
| $$  \__/  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$      |_  $$       
| $$ /$$$$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/| $$ /$$_____/      | $$        | $$       
| $$|_  $$| $$$$$$$$| $$  \ $$| $$$$$$$$|  $$$$$$ | $$|  $$$$$$       | $$        | $$       
| $$  \ $$| $$_____/| $$  | $$| $$_____/ \____  $$| $$ \____  $$      | $$        | $$       
|  $$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$ /$$$$$$$/| $$ /$$$$$$$/      | $$$$$$$$ /$$$$$$     
 \______/  \_______/|__/  |__/ \_______/|_______/ |__/|_______/       |________/|______/     
                                                                                             
Welcome to the decentralized blockchain Renaissance, above money & beyond cryptocurrency!
This script installs the genesis_29-2 blockchain full node while running under root user.

GENESIS L1 is a highly experimental decentralized project, provided AS IS, with NO WARRANTY.
GENESIS L1 IS A NON COMMERCIAL OPEN DECENTRALIZED BLOCKCHAIN PROJECT RELATED TO SCIENCE AND ART
  
  Mainnet EVM chain ID: 29
  Chain ID: genesis_29-2
  Blockchain utilitarian coin: L1
  Min. coin unit: el1
  1 L1 = 1 000 000 000 000 000 000 el1 	
  Initial supply: 21 000 000 L1
  genesis_29-2 at the time of upgrade circulation: ~29 000 000 L1
  Mint rate: < 20% annual
  Block target time: ~11s
  Binary name: genesisd
  genesis_29-1 start: Nov 30, 2021
  genesis_29-2 start: Apr 16, 2022
  
EOF

# Fixed/default variables (do not modify)
CHAIN_ID="genesis_29-2"
NODE_DIR=".genesis"
REPO_DIR=$(cd "$(dirname "$0")"/.. && pwd)
SETUP_DIR=$REPO_DIR/setup
BACKUP_DIR=".genesis_backup_$(date +"%Y%m%d%H%M%S")"
MONIKER=""
KEY=""
PRESERVE_DB=false
NO_RESTORE=false
NO_SERVICE=false
NO_START=false

if [ "$#" -lt 1 ]; then
    echo "Usage: sh $0 \e[3m--moniker string\e[0m \e[3m[...options]\e[0m"
    echo ""
    echo "   Options:"
    echo "     \e[3m--key string\e[0m             This creates a new key with the given alias, else no key gets generated."
    echo "     \e[3m--backup-dir string\e[0m      Set a different name for the backup directory. (default is time-based, ex: $BACKUP_DIR)."
    echo "     \e[3m--preserve-db\e[0m            This makes sure the complete /data folder gets backed up via a move-operation (default: false)."
    echo "     \e[3m--no-restore\e[0m             This prevents restoring the old backed up $NODE_DIR folder in the $HOME folder (default: false)."
    echo "     \e[3m--no-service\e[0m             This prevents the genesisd service from being installed (default: false)."
    echo "     \e[3m--no-start\e[0m               This prevents the genesisd service from starting at the end of the script (default: false)."
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as the root user."
    exit 1
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        --moniker)
            shift
            if [ -z "$1" ] || [ "$(echo "$1" | cut -c 1)" = "-" ]; then
                echo "Error: --moniker option requires a non-empty value."
                exit 1
            fi
            MONIKER="$1"
            ;;
        --key)
            shift
            if [ -z "$1" ] || [ "$(echo "$1" | cut -c 1)" = "-" ]; then
                echo "Error: --key option requires a non-empty value."
                exit 1
            fi
            KEY="$1"
            ;;
        --backup-dir)
            shift
            if [ -z "$1" ] || [ "$(echo "$1" | cut -c 1)" = "-" ]; then
                echo "Error: --backup-dir option requires a non-empty value."
                exit 1
            fi
            BACKUP_DIR="$1"
            ;;
        --preserve-db)
            PRESERVE_DB=true
            ;;
        --no-restore)
            NO_RESTORE=true
            ;;
        --no-service)
            NO_SERVICE=true
            ;;
        --no-start)
            NO_START=true
            ;;
        *)
            echo "Error: Unknown option $1"
            exit 1
            ;;
    esac
    shift
done

# Check if required options are provided
if [ -z "$MONIKER" ]; then
    echo "Error: --moniker is required."
    exit 1
fi

echo "Script configurations:"
echo " o Moniker will be set to: $MONIKER."
if [ ! -z "$KEY" ]; then
    echo " o Will create a key with the alias: $KEY."
fi
echo " o Backup directory is set to: $HOME/$BACKUP_DIR."
$PRESERVE_DB && echo " o The complete /data folder will be backed up (\e[3m--preserve-db\e[0m: $PRESERVE_DB)."
$NO_RESTORE && echo " o Will not restore a previously found $NODE_DIR folder (\e[3m--no-restore\e[0m: $NO_RESTORE)."
$NO_SERVICE && echo " o Will skip installing genesisd as a service (\e[3m--no-service\e[0m: $NO_SERVICE)."
if ! $NO_SERVICE && $NO_START; then
    echo " o Will skip starting the genesisd service at the end of the script (\e[3m--no-start\e[0m: $NO_START)."
fi

echo ""
echo "Please note the following:"
echo " - If a Cosmovisor process is running, it will be killed."
echo " - If the Genesis Daemon is running, it will be halted."
echo " - Existing app.toml and config.toml files will get overwritten, but backed up safely in the $HOME/$BACKUP_DIR folder."
! $PRESERVE_DB && echo " - Any existing Genesis database (in the /data folder) will get wiped! Use the flag \e[3m--preserve-db\e[0m if this is not desirable."
echo ""

read -p "Do you still wish to continue? (y/N): " ANSWER
ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
  echo "Aborted."
  exit 1
fi

echo "Continuing..."

# Stop processes
systemctl stop genesisd
pkill cosmovisor

sleep 3s

# System update and installation of dependencies
sh $SETUP_DIR/dependencies.sh
snap install ponysay

# Backup of previous configuration if one existed
if [ -e ~/"$NODE_DIR" ]; then
    rsync -qr --verbose --exclude 'data' --exclude 'config/genesis.json' ~/$NODE_DIR/ ~/"$BACKUP_DIR"/
    echo "Backed up previous $NODE_DIR folder."
    
    rm -r ~/"$BACKUP_DIR"/data
    mkdir -p ~/"$BACKUP_DIR"/data
    
    if $PRESERVE_DB; then
        # A move is more feasible, especially with big data.
        if mv ~/$NODE_DIR/data ~/"$BACKUP_DIR"/; then
            echo "Backed up entire /data folder."
        fi
    else
        if cp ~/$NODE_DIR/data/priv_validator_state.json ~/"$BACKUP_DIR"/data/priv_validator_state.json; then
            echo "Backed up previous priv_validator_state.json file."
        fi
    fi
fi

# Deletion of the previous configuration
rm -rf ~/$NODE_DIR

# cd to root of the repository
cd $REPO_DIR

# Building genesisd binaries
ponysay "In 5 seconds the wizard will start to build the binaries for genesisd..."
sleep 5s
make install

# Restore backup if backup exists and --no-restore is false
if ! $NO_RESTORE && [ -e ~/"$BACKUP_DIR" ]; then
    rsync -qr --verbose --exclude 'data' --exclude 'config/genesis.json' ~/"$BACKUP_DIR"/ ~/$NODE_DIR/
    echo "Restored previous $NODE_DIR folder."
fi

# Set chain-id
genesisd config chain-id $CHAIN_ID

# Create key
if [ ! -z "$KEY" ]; then
    genesisd config keyring-backend os
    ponysay "GET READY TO WRITE YOUR SECRET SEED PHRASE FOR YOUR NEW KEY NAMED: $KEY."
    sleep 10s
    genesisd keys add $KEY --keyring-backend os --algo eth_secp256k1

    # Check if the exit status of the previous command is equal to zero (zero means it succeeded, anything else means it failed)
    if [ $? -eq 0 ]; then
      echo "Press Enter to continue..."
      read REPLY
    fi
fi

# Init node
genesisd init $MONIKER --chain-id $CHAIN_ID -o

# State and chain specific configurations (i.e. timeout_commit 10s, min gas price 50gel).
cp $REPO_DIR/configs/default_app.toml ~/$NODE_DIR/config/app.toml
cp $REPO_DIR/configs/default_config.toml ~/$NODE_DIR/config/config.toml
cp $REPO_DIR/states/$CHAIN_ID/genesis.json ~/$NODE_DIR/config/genesis.json
# Set moniker again since the configs got overwritten
sed -i "s/moniker = .*/moniker = \"$MONIKER\"/" ~/$NODE_DIR/config/config.toml

# Reset to imported genesis.json
genesisd tendermint unsafe-reset-all

# Restore priv_validator_state.json or the entire /data folder if backup exists and --no-restore is false.
if ! $NO_RESTORE && [ -e ~/"$BACKUP_DIR" ]; then
    if $PRESERVE_DB; then
        if mv ~/$BACKUP_DIR/data/* ~/"$NODE_DIR"/data/; then
            echo "Restored previous /data folder."

            # the mv removes the priv_validator_state from the backup, so reintroduce it back.
            cp ~/"$NODE_DIR"/data/priv_validator_state.json ~/$BACKUP_DIR/data/priv_validator_state.json;
        fi
    else
        if cp ~/"$BACKUP_DIR"/data/priv_validator_state.json ~/$NODE_DIR/data/priv_validator_state.json; then
            echo "Restored backed up priv_validator_state.json file"
        fi
    fi
fi

# Set genesisd as a systemd service
if ! $NO_SERVICE; then
    # Install service
    sh $SETUP_DIR/install-service.sh
    sleep 3s

    # Start node if user hasn't run this wizard with the no-start flag
    if ! $NO_START; then
cat << "EOF"
     	    \\
             \\_
          .---(')
        o( )_-\_
       Node start                                                                                                                                                                                     
EOF
 
        sleep 5s
        systemctl start genesisd
        ponysay "genesisd node service started, you may try *journalctl -fu genesisd -ocat* or *service genesisd status* command to see it! Welcome to GenesisL1 blockchain!"
    else
        ponysay "genesisd node service installed, use *service genesisd start* to start it! Welcome to GenesisL1 blockchain!"
    fi
else
    ponysay "genesisd node is ready, use *service genesisd start* to start it! Welcome to GenesisL1 blockchain!"
fi