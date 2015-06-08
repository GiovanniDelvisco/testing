#!/bin/bash
# this file can be found here /opt/dba-scripts/lib
# This library creates functions for retrieving information about or from Tungsten.
#


# FUNCTION : This is the new fucntion to check if TUNGSTEN is installed. 

function get_tungsten_information() {

local host=$(hostname)
local user_name=$(tungsten)
local uid=`id -u`
local success=$(10004)

# check for tungsten ID
  if [[ $uid -ne $success ]]; then
  printf "$user_name user : No such a user"
  exit 1;
  else printf "$user_name user exists "
  
#  check if tungsten directory exists 
  if [[ -d "/opt/continuent" ]]; then
    printf "Directoy:/opt/continuent/ exists"
    elif [[ ! -d "/opt/continuent" ]]; then 
  printf " Directory: /opt/continuent was not found"
  exit 1;

## check if rpm are installed 
if [[ $(rpm -qa | grep -c tungsten) -gt 0 ]]; then 
  printf "$user_name rpm installed on : $host"
else
  printf " $user_name rpm not installed on: $host"
  exit 1;
fi 
fi
fi

}

# FUNCTION: get_tungsten_members() - Simple function for retrieving the Tungsten Cluster Members.
#
# The result of this function is then returned to an array $tu_cluster_members

# Hack because Bash 3.2 does not support global array definitions in functions.
declare -a tu_cluster_members

function get_tungsten_members () {
    local cluster
    local cctrl_bin="/opt/continuent/tungsten/tungsten-manager/bin/cctrl"
    local return_val
    declare -a members

    for cluster in $(echo ls | $cctrl_bin -multi | sed -n '/DATA SERVICES/,/^$/{/DATA SERVICES\|^$\|^\+---.*/!p}')
    do
        members+=( $(echo -e "cd ${cluster}\nmembers" | $cctrl_bin -multi | grep ${cluster}/ |cut -f2 -d/|cut -f1 -d.) )
    done
    tu_cluster_members+=(${members[@]})
}

# FUNCTION: get_tungsten_connector_port() - Simple function for requesting the Tungsten Connector port in use.
#
# The result of this function is then returned to stdout

function get_tungsten_connector_port () {
    local portcfg
    local portns
    local conncnf_dir=/opt/continuent/tungsten/tungsten-connector/conf/connector.properties
    
    portcfg=$(grep -P "^server.port[^.].*\d+$" $conncnf_dir |grep -Po "\d+"| head -n 1)
    portns=$(netstat -ln | grep -P ":${portcfg} .*LISTEN" | awk '{print $4}' | cut -d':' -f2- | grep -Po "\d+")

    if [[ $portcfg -eq $portns ]]; then
        printf $portcfg
    else
        printf "unknown"
    fi
}


# FUNCTION: get_tungsten_role() - Simple function for requesting the replication role.
#
# The result of this function is then returned to stdout

function get_tungsten_role() {
  local host=$(hostname)
  local role="unknown"
  local exit_code
  local cctrl_bin="/opt/continuent/tungsten/tungsten-manager/bin/cctrl"
  local trepctl_bin="/opt/continuent/tungsten/tungsten-replicator/bin/trepctl"
  
  set -o pipefail
  if [[ -d "/opt/continuent" ]]; then
    # Method 1
    role=$($trepctl_bin status|grep '^role'|awk ' {print $3}')
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
      # Method 2
      role=$(echo ls | $cctrl_bin | grep -iP ^\\\|${host} | awk -F'(' '{print $2}' | cut -d':' -f1)
      exit_code=$?
      if [[ $exit_code -eq 1 ]]; then
        role="unknown"
      fi
    fi
 fi
  set +o pipefail
  printf $role
}

