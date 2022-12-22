#!/bin/bash

miner_input_details() {
  echo -e "\n \e[93m ===================================== Please input the details for. ======================================  \e[39m"
  if [[ -f ~/cfg/numminers.txt ]]
  then
    MINER=$(cat ~/cfg/numminers.txt)
    echo "MINER: $MINER"
  else
    read -p "Enter the number of Miners to be deployed. If no. of miners is greater than 1, make sure you have miner keys, dkg keys, nodes.yaml, magicblock & initial-states configs: " MINER
  fi
  if [[ -f ~/cfg/url.txt ]]
  then
    DOMAIN=$(cat ~/cfg/url.txt)
    echo "DOMAIN: $DOMAIN"
  else
    read -p "Enter the subdomain or domain for you miners. Ex- test.abcd.com: " DOMAIN
  fi
}

miner_infra_setup() {
  # Creating directory structure for miner deployment
  echo -e "\n \e[93m ===================================== Creating directory structure for miner deployment. ======================================  \e[39m"
  mkdir -p ${HOME}/miner_deploy/docker.local/bin/ ${HOME}/miner_deploy/docker.local/config/redis/ ${HOME}/miner_deploy/docker.local/build.miner/
  echo -e "\e[32mDirectory structure for miner deployment is successfully created."

  pushd ${HOME}/miner_deploy/

  # create 0chain.yaml file
  echo -e "\n \e[93m ===================================== Creating 0chain.yaml config file. ======================================  \e[39m"
  cat <<\EOF >./docker.local/config/0chain.yaml
version: 1.0

logging:
  level: "debug"
  verbose: false
  console: false # printing log to console is only supported in development mode
  goroutines: false
  memlog: false

development:
  smart_contract:
    zrc20: true
  txn_generation:
    wallets: 50
    max_transactions: 0
    max_txn_fee: 10000
    min_txn_fee: 0
    max_txn_value: 10000000000
    min_txn_value: 100
  faucet:
    refill_amount: 1000000000000000
  pprof: true

zerochain:
  id: "0afc093ffb509f059c55478bc1a60351cef7b4e9c008a53a6cc8241ca8617dfe"
  decimals: 10
  genesis_block:
    id: "ed79cae70d439c11258236da1dfa6fc550f7cc569768304623e8fbd7d70efae4"

server_chain:
  id: "0afc093ffb509f059c55478bc1a60351cef7b4e9c008a53a6cc8241ca8617dfe"
  owner: "edb90b850f2e7e7cbd0a1fa370fdcc5cd378ffbec95363a7bc0e5a98b8ba5759"
  decimals: 10
  tokens: 200000000
  genesis_block:
    id: "ed79cae70d439c11258236da1dfa6fc550f7cc569768304623e8fbd7d70efae4"
  block:
    min_block_size: 1
    max_block_size: 10000
    max_block_cost: 10000 #equal to 100ms
    max_byte_size: 1638400
    min_generators: 2
    generators_percent: 0.2
    replicators: 0
    generation:
      timeout: 15
      retry_wait_time: 5 #milliseconds
    proposal:
      max_wait_time: 180ms
      wait_mode: static # static or dynamic
    consensus:
      threshold_by_count: 66 # percentage (registration)
      threshold_by_stake: 0 # percent
    sharding:
      min_active_sharders: 25 # percentage
      min_active_replicators: 25 # percentageRF
    validation:
      batch_size: 1000
    reuse_txns: false
    storage:
      provider: blockstore.FSBlockStore # blockstore.FSBlockStore or blockstore.BlockDBStore

  round_range: 10000000
  dkg: true
  view_change: false
  round_timeouts:
    softto_min: 1500 # in miliseconds
    softto_mult: 1 # multiples of mean network time (mnt)  softto = max{softo_min, softto_mult * mnt}
    round_restart_mult: 10 # number of soft timeouts before round is restarted
    timeout_cap: 1 # 0 indicates no cap
    vrfs_timeout_mismatch_tolerance: 5
  transaction:
    payload:
      max_size: 98304 # bytes
    timeout: 600 # seconds
    min_fee: 0
    exempt:
      - add_miner
      - miner_health_check
      - add_sharder
      - sharder_health_check
      - contributeMpk
      - sharder_keep
      - shareSignsOrShares
      - wait
  client:
    signature_scheme: bls0chain # ed25519 or bls0chain
    discover: true
  messages:
    verification_tickets_to: all_miners # generator or all_miners
  state:
    enabled: true
    prune_below_count: 100 # rounds
    sync:
      timeout: 10 # seconds
  block_rewards: true  
  stuck:
    check_interval: 10 # seconds
    time_threshold: 60 #seconds
  smart_contract:
    setting_update_period: 200 #rounds
    timeout: 8000ms
    storage: true
    faucet: true
    interest: true
    miner: true
    multisig: true
    vesting: true
    zcn: true
  health_check:
    show_counters: true
    deep_scan:
      enabled: false
      settle_secs: 30s
      window: 0 #Full scan till round 0
      repeat_interval_mins: 3m #minutes
      report_status_mins: 1m #minutes
      batch_size: 50
    proximity_scan:
      enabled: true
      settle_secs: 30s
      window: 100000 #number of blocks, Do not make 0 with minio ON, Should be less than minio old block round range
      repeat_interval_mins: 1m #minutes
      report_status_mins: 1m #minutes
      batch_size: 50
  lfb_ticket:
    rebroadcast_timeout: "15s" #
    ahead: 5 # should be >= 5
    fb_fetching_lifetime: "10s" #
  async_blocks_fetching:
    max_simultaneous_from_miners: 100
    max_simultaneous_from_sharders: 30
  dbs:
    events:
      enabled: true
      name: events_db
      user: zchain_user
      password: zchian
      host: postgres #localhost
      port: 5432
      max_idle_conns: 100
      max_open_conns: 200
      conn_max_lifetime: 20s
    settings:
      # event database settings blockchain
      debug: false
      aggregate_period: 10
      page_limit: 50

network:
  magic_block_file: config/b0magicBlock.json
  initial_states: config/initial-states.yaml
  genesis_dkg: 0
  dns_url: "" # http://198.18.0.98:9091
  relay_time: 200 # milliseconds
  max_concurrent_requests: 40
  timeout:
    small_message: 1000 # milliseconds
    large_message: 3000 # milliseconds
  large_message_th_size: 5120 # anything greater than this size in bytes
  user_handlers:
    rate_limit: 100000000 # 100 per second
  n2n_handlers:
    rate_limit: 10000000000 # 10000 per second

# delegate wallet is wallet that used to configure node in Miner SC; if its
# empty, then node ID used
delegate_wallet: ""
# % of fees and rewards for generator
service_charge: 0.10 # [0; 1) of all fees
# max number of delegate pools allowed by a node in miner SC
number_of_delegates: 10 # max number of delegate pools
# min stake pool amount allowed by node; should not conflict with
# SC min_stake
min_stake: 0.0 # tokens
# max stake pool amount allowed by node; should not conflict with
# SC max_stake
max_stake: 100.0 # tokens
# latitude is miner/sharder latitude geolocation
latitude: 28.644800
# longitude is miner/sharder longitude geolocation
longitude: 77.216721

minio:
  enabled: false # Enable or disable minio backup, Do not enable with deep scan ON
  worker_frequency: 1800 # In Seconds, The frequency at which the worker should look for files, Ex: 3600 means it will run every 3600 seconds
  num_workers: 5 # Number of workers to run in parallel, Just to make execution faster we can have mutiple workers running simultaneously
  use_ssl: false # Use SSL for connection or not
  old_block_round_range: 250000 # How old the block should be to be considered for moving to cloud, Should be greater than proximity scan window
  delete_local_copy: true # Delete local copy of block once it's moved to cloud

cassandra:
  connection:
    delay: 10 # in seconds
    retries: 10
#   host: cassandra
#   port: 9042

# integration tests related configurations
integration_tests:
  # address of the server
  address: host.docker.internal:15210
  # lock_interval used by nodes to request server to connect to blockchain
  # after start
  lock_interval: 1s

EOF

  echo -e "\e[32m0chain.yaml config file is successfully created."

  # create sc.yaml file
  echo -e "\n \e[93m ===================================== Creating sc.yaml config file. ======================================  \e[39m"
  cat <<\EOF >./docker.local/config/sc.yaml
smart_contracts:
  faucetsc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    pour_limit: 1
    pour_amount: 1
    max_pour_amount: 100000
    periodic_limit: 10000000
    global_limit: 10000000
    individual_reset: 3h # in hours
    global_reset: 48h # in hours
    cost:
      update-settings: 100
      pour: 100
      refill: 100
  interestpoolsc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    min_lock: 10
    interest_rate: 0.0
    apr: 0.1
    min_lock_period: 1m
    max_lock_period: 8760h
    max_mint: 1500000.0
    cost:
      lock: 100
      unlock: 100
      updateVariables: 100

  minersc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    # miners
    max_n: 7 # 100
    min_n: 3 # 3
    # sharders
    max_s: 3 # 30
    min_s: 1 # 1
    # max delegates allowed by SC
    max_delegates: 200 #
    # DKG
    t_percent: .66 # of active
    k_percent: .75 # of registered
    x_percent: 0.70 # percentage of prev mb miners required to be part of next mb
    # etc
    min_stake: 0.0 # min stake can be set by a node (boundary for all nodes)
    max_stake: 100.0 # max stake can be set by a node (boundary for all nodes)
    start_rounds: 50
    contribute_rounds: 50
    share_rounds: 50
    publish_rounds: 50
    wait_rounds: 50
    # stake interests, will be declined every epoch
    interest_rate: 0.0 # [0; 1)
    # reward rate for generators, will be declined every epoch
    reward_rate: 1.0 # [0; 1)
    # share ratio is miner/block sharders rewards ratio, for example 0.1
    # gives 10% for miner and rest for block sharders
    share_ratio: 0.8 # [0; 1)
    # reward for a block
    block_reward: 0.21 # tokens
    # max service charge can be set by a generator
    max_charge: 0.5 # %
    # epoch is number of rounds before rewards and interest are decreased
    epoch: 15000000 # rounds
    # decline rewards every new epoch by this value (the block_reward)
    reward_decline_rate: 0.1 # [0; 1), 0.1 = 10%
    # decline interests every new epoch by this value (the interest_rate)
    interest_decline_rate: 0.1 # [0; 1), 0.1 = 10%
    # no mints after miner SC total mints reaches this boundary
    max_mint: 1500000.0 # tokens
    # if view change is false then reward round frequency is used to send rewards and interests
    reward_round_frequency: 250
    # miner delegates to get paid each round when paying fees and rewards
    num_miner_delegates_rewarded: 10
    # sharders rewarded each round
    num_sharders_rewarded: 5
    # sharder delegates to get paid each round when paying fees and rewards
    num_sharder_delegates_rewarded: 1
    cooldown_period: 100
    cost:
      add_miner: 100
      add_sharder: 100
      delete_miner: 100
      delete_sharder: 100
      miner_health_check: 100
      sharder_health_check: 100
      contributeMpk: 100
      shareSignsOrShares: 100
      wait: 100
      update_globals: 100
      update_settings: 100
      update_miner_settings: 100
      update_sharder_settings: 100
      payFees: 0
      feesPaid: 100
      mintedTokens: 100
      addToDelegatePool: 100
      deleteFromDelegatePool: 100
      sharder_keep: 100
      collect_reward: 100
  storagesc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    # the time_unit is a duration used as divider for a write price; a write
    # price measured in tok / GB / time_unit, where the time_unit is this
    # configuration; for example 1h, 24h (a day), 720h (a month -- 30 days);
    time_unit: "720h"
    min_stake: 0.01 # min stake can be set by a node (boundary for all nodes)
    max_stake: 100.0 # max stake can be set by a node (boundary for all nodes)
    # max_mint
    max_mint: 1500000.0 # tokens, max amount of tokens can be minted by SC
    # min possible allocations size in bytes allowed by the SC
    min_alloc_size: 1024
    # min possible allocation duration allowed by the SC
    min_alloc_duration: "5m"
    # max challenge completion time of a blobber allowed by the SC
    max_challenge_completion_time: "10m"
    # min blobber's offer duration allowed by the SC
    min_offer_duration: "10h"
    # min blobber capacity allowed by the SC
    min_blobber_capacity: 1024
    # fraction of the allocation cost that is locked in the cancellation charge
    cancellation_charge: 0.2
    # users' read pool related configurations
    readpool:
      min_lock: 0.1 # tokens
    # users' write pool related configurations
    writepool:
      min_lock: 0.1 # tokens
    # stake pool configurations
    stakepool:
      # minimal lock for a delegate pool
      min_lock: 0.1 # tokens
      # interest_rate is tokens earned by a blobber for its stake
      interest_rate: 0.0
      # interest_interval is interval to pay interests for a stake
      interest_interval: 1m
      # min_lock_period is min lock period. Default lock period is 3 years worth of blocks.
      min_lock_period: 36m
    # following settings are for free storage rewards
    #
    # largest value you can have for the total allowed free storage
    # that a single user can assign
    max_total_free_allocation: 100000000000000000
    # maximum setting for the largest number of tokens permitted in
    # a free storage allocation
    max_individual_free_allocation: 1000000
    # allocation settings for free storage
    # these values are applied to all free allocations
    free_allocation_settings:
      data_shards: 2
      duration: 300h
      parity_shards: 2
      read_pool_fraction: 0.2
      mint_amount: 0.5
      read_price_range:
        max: 1
        min: 0
      size: 100000000
      write_price_range:
        max: 1
        min: 0
    validator_reward: 0.025
    # blobber_slash represents blobber's stake penalty when a challenge not
    # passed
    blobber_slash: 0.10
    # max prices for blobbers (tokens per GB)
    max_read_price: 100.0
    max_write_price: 100.0
    # min_write_price: 0.1
    max_blobbers_per_allocation: 40
    # allocation cancellation
    #
    # failed_challenges_to_cancel is number of failed challenges of an
    # allocation to be able to cancel an allocation
    failed_challenges_to_cancel: 20
    # failed_challenges_to_revoke_min_lock is number of failed challenges
    # of a blobber to revoke its min_lock demand back to user; only part
    # not paid yet can go back
    failed_challenges_to_revoke_min_lock: 10
    #
    # challenges
    #
    # enable challenges
    challenge_enabled: true
    # number of challenges for MB per minute
    challenge_rate_per_mb_min: 1
    # max number of challenges can be generated at once
    max_challenges_per_generation: 100
    # number of validators per challenge
    validators_per_challenge: 2
    # max delegates per stake pool allowed by SC
    max_delegates: 200
    # max_charge allowed for blobbers; the charge is part of blobber rewards
    # goes to blobber's delegate wallets, other part goes to related stake
    # holders
    max_charge: 0.50
    # reward paid out every block
    block_reward:
      block_reward: 1
      block_reward_change_period: 10000
      block_reward_change_ratio: 0.1
      qualifying_stake: 1
      sharder_ratio: 10
      miner_ratio: 40
      blobber_ratio: 50
      trigger_period: 30
      blobber_capacity_ratio: 10
      blobber_usage_ratio: 40
      gamma:
        alpha: 0.2
        a: 10
        b: 9
      zeta:
        i: 1
        k: 0.9
        mu: 0.2
    expose_mpt: true
    cost:
      update_settings: 200
      read_redeem: 700
      commit_connection: 100
      new_allocation_request: 1000
      update_allocation_request: 1400
      finalize_allocation: 1400
      cancel_allocation: 1400
      add_free_storage_assigner: 100
      free_allocation_request: 200
      free_update_allocation: 1600
      add_curator: 100
      remove_curator: 100
      blobber_health_check: 100
      update_blobber_settings: 400
      update_validator_settings: 200
      pay_blobber_block_rewards: 100
      curator_transfer_allocation: 500
      challenge_request: 100
      challenge_response: 900
      add_validator: 500
      add_blobber: 500
      new_read_pool: 100
      read_pool_lock: 200
      read_pool_unlock: 100
      write_pool_lock: 400
      write_pool_unlock: 200
      stake_pool_lock: 1600
      stake_pool_unlock: 400
      stake_pool_pay_interests: 100
      commit_settings_changes: 0
      generate_challenge: 0
      blobber_block_rewards: 0
      collect_reward: 800
  vestingsc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    min_lock: 0.01
    min_duration: "2m"
    max_duration: "2h"
    max_destinations: 3
    max_description_length: 20
    cost:
      trigger: 100
      unlock: 100
      add: 100
      stop: 100
      delete: 100
      vestingsc-update-settings: 100
  zcnsc:
    owner_id: 1746b06bb09f55ee01b33b5e2e055d6cc7a900cb57c0a3a5eaabb8a0e7745802
    min_mint: 1
    min_burn: 1
    min_stake: 0
    min_lock: 0
    min_authorizers: 1
    percent_authorizers: 0.7
    max_delegates: 10
    max_fee: 100
    burn_address: "0000000000000000000000000000000000000000000000000000000000000000"
    cost:
      mint: 100
      burn: 100
      add-authorizer: 100
      delete-authorizer: 100

EOF

  echo -e "\e[32msc.yaml config file is successfully created."

  # create state.redis.conf file
  echo -e "\n \e[93m ===================================== Creating state.redis.conf config file. ======================================  \e[39m"
  cat <<\EOF >./docker.local/config/redis/state.redis.conf
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename state.dump.rdb
dir /0chain/data/redis/state
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
slave-lazy-flush no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble no
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

  echo -e "\e[32mstate.redis.conf config file is successfully created."

  # create transactions.redis.conf file
  echo -e "\n \e[93m ===================================== Creating transactions.redis.conf config file. ======================================  \e[39m"
  cat <<\EOF >./docker.local/config/redis/transactions.redis.conf
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
always-show-logo yes
save ""
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename transactions.dump.rdb
dir /0chain/data/redis/transactions
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
slave-lazy-flush no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble no
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes

EOF

  echo -e "\e[32mtransactions.redis.conf config file is successfully created."

  # create docker-compose file for miner
  echo -e "\n \e[93m ===================================== Creating docker-compose file for miner. ======================================  \e[39m"
  cat <<\EOF >./docker.local/build.miner/p0docker-compose.yaml
version: '3'
services:
  redis:
    image: "redis:alpine"
    volumes:
      - ../config:/0chain/config
      - /mnt/ssd/miner${MINER}/data:/0chain/data
    networks:
      default:
    sysctls:
      net.core.somaxconn: '511'
    command: redis-server /0chain/config/redis/state.redis.conf
    restart: "always"

  redis_txns:
    image: "redis:alpine"
    volumes:
      - ../config:/0chain/config
      - /mnt/ssd/miner${MINER}/data:/0chain/data
    networks:
      default:
    sysctls:
      net.core.somaxconn: '511'
    command: redis-server /0chain/config/redis/transactions.redis.conf
    restart: "always"

  miner:
    image: 0chaindev/miner:staging-02e43b7b
    environment:
      - DOCKER=true
      - REDIS_HOST=redis
      - REDIS_TXNS=redis_txns
    depends_on:
     - redis
     - redis_txns
    links:
      - redis:redis
      - redis_txns:redis_txns
    volumes:
      - ../config:/0chain/config
      - /mnt/ssd/miner${MINER}/data:/0chain/data
      - /mnt/ssd/miner${MINER}/log:/0chain/log
    ports:
      - "707${MINER}:707${MINER}"
    networks:
      default:
      testnet0:
        ipv4_address: 198.18.0.7${MINER}
    command: ./bin/miner  --deployment_mode 0 --keys_file config/b0mnode${MINER}_keys.txt --dkg_file config/b0mnode${MINER}_dkg.json
    restart: "always"

networks:
  default:
    driver: bridge
  testnet0:
    external: true

volumes:
  data:
  config:

EOF

  echo -e "\e[32mdocker-compose file is successfully created."

  # create start script for miner
  echo -e "\n \e[93m ===================================== Creating start script file for miner. ======================================  \e[39m"
  cat <<\EOF >./docker.local/bin/start.p0miner.sh
#!/bin/sh
set -e
PWD=$(pwd)
MINER_DIR=$(basename "$PWD")
MINER_ID=$(echo "$MINER_DIR" | sed -e 's/.*\(.\)$/\1/')
echo Starting miner"$MINER_ID" in daemon mode ...
MINER=$MINER_ID docker-compose -p miner"$MINER_ID" -f ../build.miner/p0docker-compose.yaml up -d

EOF

  sudo chmod +x ./docker.local/bin/start.p0miner.sh
  echo -e "\e[32mStart script file is successfully created."

  # create init setup script for miner
  echo -e "\n \e[93m ===================================== Creating init setup script file for miner. ======================================  \e[39m"
  cat <<\EOF >./docker.local/bin/init.setup.sh
#!/bin/sh

for i in $(seq 1 8)
do
  mkdir -p docker.local/miner"$i"
  sudo mkdir -p /mnt/ssd/miner"$i"/data/redis/state
  sudo mkdir -p /mnt/ssd/miner"$i"/data/redis/transactions
  sudo mkdir -p /mnt/ssd/miner"$i"/data/rocksdb
  sudo mkdir -p /mnt/ssd/miner"$i"/log
done

EOF

  sudo chmod +x ./docker.local/bin/init.setup.sh
  echo -e "\e[32minit setup script file is successfully created."

  # create setup network for miner
  echo -e "\n \e[93m ===================================== Creating network setup script file for miner. ======================================  \e[39m"
  cat <<\EOF >./docker.local/bin/setup.network.sh
#!/bin/sh
docker network create --driver=bridge --subnet=198.18.0.0/15 --gateway=198.18.0.255 testnet0

EOF

  sudo chmod +x ./docker.local/bin/setup.network.sh
  echo -e "\e[32mnetwork setup file is successfully created."

  # create init Sync clock script for miner
  echo -e "\n \e[93m ===================================== Creating sync clock script file for miner. ======================================  \e[39m"
  cat <<\EOF >./docker.local/bin/sync_clock.sh
#!/bin/sh
docker run --rm --privileged alpine hwclock -s

EOF

  sudo chmod +x ./docker.local/bin/sync_clock.sh
  echo -e "\e[32msync clock script file is successfully created. \n"

popd
}

miner_pre_deploy_setup() {
  pushd ${HOME}/miner_deploy/
  echo -e "\n \e[93m ===================================== Executing init setup script for miner. ======================================  \e[39m"
  sed -i "s/8/$MINER/g" "./docker.local/bin/init.setup.sh"
  ./docker.local/bin/init.setup.sh
  echo -e "\e[32mSuccessfully Executed. \e[23m"
  echo -e "\n \e[93m ===================================== Executing network setup script for miner. ======================================  \e[39m"
  ./docker.local/bin/setup.network.sh
  echo -e "\e[32mSuccessfully Executed. \e[23m"
  echo -e "\n \e[93m ===================================== Executing sync clock script for miner. ======================================  \e[39m"
  ./docker.local/bin/sync_clock.sh
  echo -e "\e[32mSuccessfully Executed. \e[23m"
  popd
}


miner_keys_configs() {
  echo -e "\n \e[93m ============================================== Kindly copy following key's and config files as follows ===============================================  \e[39m"
  echo -e "\e[93m Make sure all the file name should be same as below  \e[39m"
  pushd ${HOME}/miner_deploy/
  for k in $(seq 1 $MINER)
    do
      echo -e "\n b0mnode${k}_keys.txt miner key to $PWD/docker.local/config/ "
      echo -e "\n b0mnode${k}_dkg.json DKG key to $PWD/docker.local/config/ "
    done
  echo -e "\n b0magicBlock.json configs to $PWD/docker.local/config/ "
  echo -e "\n nodes.yaml config to $PWD/docker.local/config/ "
  echo -e "\n initial-states.yaml config to $PWD/docker.local/config/ "
  popd
  echo -e "\n \e[93m ===================================== Press make sure if you have entered the above keys & configs. ======================================  \e[39m"
  #if [[ "$AUTOIMPORT" == "y" ]]
  #then
    #cp keygen/config/* sharder_deploy/docker.local/config/
    cp ~/keygen/config/* ~/miner_deploy/docker.local/config/
    echo "AUTOIMPORTED!"
    ls ~/miner_deploy/docker.local/config/*
  #fi
  read -p "Press enter after you have sucessfully placed the files to the specifed directory: "
}

miner_deploy() {
  echo -e "\n \e[93m ============================================== Putting up all the miners ===============================================  \e[39m"
  for j in $(seq 1 $MINER)
    do
      pushd ${HOME}/miner_deploy/
        cd docker.local/miner"$j"/
        echo -e "Starting miner $j."
        ../bin/start.p0miner.sh
      popd
    done
}

nginx_setup() {
  echo -e "\n \e[93m ============================================== Installing nginx on the server ===============================================  \e[39m"
  sudo apt update
  sudo apt install nginx -y
  echo -e "\n \e[93m ============================================== Adding proxy pass to nginx config ===============================================  \e[39m"
  pushd ${HOME}/miner_deploy/
  cat <<\EOF >./docker.local/bin/default
server {
   server_name subdomain;
   add_header 'Access-Control-Expose-Headers' '*';
   location / {
       # First attempt to serve request as file, then
       # as directory, then fall back to displaying a 404.
       try_files $uri $uri/ =404;
   }
EOF
  for l in $(seq 1 $MINER)
    do
    echo "
    location /miner0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:707${l}/;
    }" >> ./docker.local/bin/default
    done
  echo "}" >> ./docker.local/bin/default
  sed -i "s/subdomain/$DOMAIN/g" "./docker.local/bin/default"
  cat ./docker.local/bin/default > /etc/nginx/sites-available/default
  popd
  sudo apt-get install certbot -y
  apt-get install python3-certbot-nginx -y
}

miner_infra_setup
miner_input_details
#nginx_setup
miner_pre_deploy_setup
miner_keys_configs
miner_deploy

#echo -e "\n\n \e[93m Create a record in your dns to map server ip with domain. \e[39m"
#echo -e "\n \e[93m Run the following command: \n  sudo certbot --nginx -d $DOMAIN \e[39m"
