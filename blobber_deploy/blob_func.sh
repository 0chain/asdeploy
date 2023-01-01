#checking if you have already added the to DNS & is it resolving or not.
check_dns() {
  echo -e "\n\e[37mChecking if you have already added the ip to DNS & is it resolving or not. \e[73m"
  URL=$(cat ~/cfg/url.txt)
  ipaddr=$(curl api.ipify.org)
  myip=$(dig +short $URL)
  if [[ "$myip" != "$ipaddr" ]]; then
    echo -e "\e[31m  $URL IP resolution mismatch $myip vs $ipaddr. \e[13m \n"
    exit 1
  else
    echo -e "\e[32m  SUCCESS $URL resolves to $myip.  \e[23m \n"
  fi
}

#please pass the argument to check_and_install_tools to check & install package or tool.
install_tools_utilities() {
  REQUIRED_PKG=$1
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
  echo -e "\e[37mChecking for $REQUIRED_PKG if it is already installed. \e[73m"
  if [ "" = "$PKG_OK" ]; then
    echo -e "\e[31m  No $REQUIRED_PKG is found on the server. \e[13m\e[32m$REQUIRED_PKG installed. \e[23m \n"
    sudo apt update &> /dev/null
    sudo apt --yes install $REQUIRED_PKG &> /dev/null
  else
    echo -e "\e[32m  $REQUIRED_PKG is already installed on the server/machine.  \e[23m \n"
  fi
}

#checking if $REQUIRED_PKG is running or not.
status_tools_utilities() {
  REQUIRED_PKG=$1
  if (systemctl is-active --quiet $REQUIRED_PKG) ; then
    echo -e "\e[32m  $REQUIRED_PKG is running fine. \e[23m \n"
  else
    echo -e "\e[31m  $REQUIRED_PKG is failing to run. Please check and resolve it first. You can connect with team for support too. \e[13m \n"
    exit 1
  fi
}

spinner() {
  SECONDS=0
  while [[ SECONDS -lt 100 ]]; do
    for ((i = 0; i < ${#chars}; i++)); do
      sleep 0.5
      echo -e -en "${chars:$i:1}" "\r"
    done
  done
}

append_logs() {
  local text=$1
  script_index=${script_index:-0}
  if [[ -z "$2" || "$2" != "skip_count" ]]; then
    echo "$script_index.$step_count) $text " $(date +"%Y-%m-%d %H:%M:%S") >>$log_path
    ((step_count++))
  else
    echo "$text " $(date +"%Y-%m-%d %H:%M:%S") >>$log_path
  fi
}

progress_bar_fn() {
  local DURATION=$1
  local INT=0.25 # refresh interval

  local TIME=0
  local CURLEN=0
  local SECS=0
  local FRACTION=0

  local FB=2588 # full block

  trap "echo -e $(tput cnorm); trap - SIGINT; return" SIGINT

  echo -ne "$(tput civis)\r$(tput el)│" # clean line

  local START=$(date +%s%N)

  while [[ $SECS -lt $DURATION ]]; do
    local COLS=$(tput cols)

    # main bar
    local L=$(bc -l <<<"( ( $COLS - 5 ) * $TIME  ) / ($DURATION-$INT)" | awk '{ printf "%f", $0 }')
    local N=$(bc -l <<<$L | awk '{ printf "%d", $0 }')

    [ $FRACTION -ne 0 ] && echo -ne "$(tput cub 1)" # erase partial block

    if [ $N -gt $CURLEN ]; then
      for i in $(seq 1 $((N - CURLEN))); do
        echo -ne \\u$FB
      done
      CURLEN=$N
    fi

    # partial block adjustment
    FRACTION=$(bc -l <<<"( $L - $N ) * 8" | awk '{ printf "%.0f", $0 }')

    if [ $FRACTION -ne 0 ]; then
      local PB=$(printf %x $((0x258F - FRACTION + 1)))
      echo -ne \\u$PB
    fi

    # percentage progress
    local PROGRESS=$(bc -l <<<"( 100 * $TIME ) / ($DURATION-$INT)" | awk '{ printf "%.0f", $0 }')
    echo -ne "$(tput sc)"                  # save pos
    echo -ne "\r$(tput cuf $((COLS - 6)))" # move cur
    echo -ne "│ $PROGRESS%"
    echo -ne "$(tput rc)" # restore pos

    TIME=$(bc -l <<<"$TIME + $INT" | awk '{ printf "%f", $0 }')
    SECS=$(bc -l <<<$TIME | awk '{ printf "%d", $0 }')

    # take into account loop execution time
    local END=$(date +%s%N)
    local DELTA=$(bc -l <<<"$INT - ( $END - $START )/1000000000" |
      awk '{ if ( $0 > 0 ) printf "%f", $0; else print "0" }')
    sleep $DELTA
    START=$(date +%s%N)
  done

  echo $(tput cnorm)
  trap - SIGINT
}

progress_bar() {
  if [[ $development == true ]]; then # If development mode is enabled then progress bar will be shown
    progress_bar_fn $1
  else
    sleep $1
  fi
}