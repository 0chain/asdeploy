# Guide to deploy blobbers & validators on the server using docker.
## Info.
- This is a working document and is subject to change. For mainnet, an officially Züs hosted procedure will be
used, but process will be similar.<br />

## Steps.
1. Run the following command in your home folder of your Linux server (You should run this command every time you wish to re-run any of the following points since it will refresh the scripts)
   ```bash
   wget -N https://raw.githubusercontent.com/0chain/asdeploy/main/blob_init.sh ; bash blob_init.sh
   ```
   The above will:-
    - Prompt you to enter number of blobbers, url, email. These get saved in ~/cfg folder.
    - Also prompt for a delegating wallet. This is the owner wallet id that will initially stake to your blobber.
    Additional wallets can then also stake to your blobber once operational.
    - Install various dependencies
    - Fetch all required scripts for the rest of this process into the current folder.<br /><br />
2. Run the following script to generate the nginx config (for both blobber and validator)
    ```bash
    bash blob_nginx.sh
    ```
    This creates a blob folder with requisite Operational Wallets/Keys. If you run this script again, the existing blobber folder will be backed up and a new one created.<br /><br />
3. Then you need to generate Operational Keys for your blobber and validator. We only recommend 1 blobber per server in production, but more may be used testnets.
    ```bash
    bash blob_gen.sh
    ```
    This creates a blob folder with requisite Operational Wallets/Keys. If you run this script again, the existing blobber folder will be backed up and a new one created.<br /><br />
4. You will then need to initialize the blobber repo and configure it for your blobber(s):
    ```bash
    bash blob_files.sh
    ```<br /><br />
5. You then need to run the following command:
   ```bash
   bash blob_run.sh
   ```
   This will launch the blobber docker containers for each blobber, then attempt to delegate funds in order to make each blobber operational.<br /><br />
6. You then need to run the following command:
   ```bash
   docker ps -a
   ```
   In a web browser, should be able to check they are running at the following urls:<br />
   - `https://<url>/blobber01/_stats`, 
   - `https://<url>/validator01/`<br /><br />

7. Before your blobber(s) can be used, they need to be staked to by the delegating wallet specified previously. You will be able to do this via the bolt app, but for testnet deployments you can run the following script to delegate a small number of tokens sufficient for testing purposes
   ```bash
   bash blob_del.sh
   ```
