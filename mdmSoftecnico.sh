#!/bin/bash

# Global constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Check if running in Recovery Mode
checkRecoveryMode() {
  if [ -e "/System/Library/CoreServices/Finder.app" ]; then
    echo -e "${RED}This script should only be run in Recovery Mode.${NC}"
    exit 1
  else
    echo -e "${GREEN}Running in Recovery Mode. Proceeding...${NC}"
  fi
}

# Check for root permissions
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root.${NC}"
  exit 1
fi

# Check if the script is running in Recovery Mode
checkRecoveryMode

# Function to check for MDM enrollment
checkMDMEnrollment() {
  echo -e "${BLUE}Checking MDM enrollment status...${NC}"
  if profiles status -type enrollment >/dev/null 2>&1; then
    echo -e "${GREEN}Device is enrolled in MDM.${NC}"
    echo -e "${BLUE}Fetching enrollment details...${NC}"
    sudo profiles show -type enrollment
  else
    echo -e "${GREEN}Device is not enrolled in MDM.${NC}"
  fi
}

# Function to remove MDM enrollment
removeMDM() {
  echo -e "${BLUE}Removing MDM profiles and blocking MDM hosts...${NC}"
  
  # Mount System Volume
  systemVolumePath=$(defineVolumePath "$DEFAULT_SYSTEM_VOLUME" "System")
  mountVolume "$systemVolumePath"

  # Mount Data Volume
  dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
  mountVolume "$dataVolumePath"

  # Block MDM hosts
  echo -e "${BLUE}Blocking MDM hosts...${NC}"
  hostsPath="$systemVolumePath/etc/hosts"
  blockedDomains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")
  for domain in "${blockedDomains[@]}"; do
    echo "0.0.0.0 $domain" >>"$hostsPath"
  done
  echo -e "${GREEN}MDM hosts blocked successfully.${NC}\n"

  # Remove config profiles
  echo -e "${BLUE}Removing config profiles...${NC}"
  configProfilesSettingsPath="$systemVolumePath/var/db/ConfigurationProfiles/Settings"
  rm -rf "$configProfilesSettingsPath/.cloudConfigHasActivationRecord"
  rm -rf "$configProfilesSettingsPath/.cloudConfigRecordFound"
  touch "$configProfilesSettingsPath/.cloudConfigProfileInstalled"
  touch "$configProfilesSettingsPath/.cloudConfigRecordNotFound"
  echo -e "${GREEN}Config profiles removed successfully.${NC}\n"
}

# Function to create a new local user
createLocalUser() {
  echo -e "${BLUE}Creating a new local user...${NC}"
  
  # Mount Data Volume
  dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
  mountVolume "$dataVolumePath"

  # Check if user already exists
  dscl_path="$dataVolumePath/private/var/db/dslocal/nodes/Default"
  localUserDirPath="/Local/Default/Users"
  defaultUID="501"
  
  if ! dscl -f "$dscl_path" localhost -list "$localUserDirPath" UniqueID | grep -q "\<$defaultUID\>"; then
    read -rp "Full Name (default: Apple): " fullName
    fullName="${fullName:-Apple}"

    read -rp "Username (default: Apple): " username
    username="${username:-Apple}"

    read -rsp "Password (default: 1234): " userPassword
    userPassword="${userPassword:-1234}"
    echo ""

    # Create the user
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UserShell "/bin/zsh"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" RealName "$fullName"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UniqueID "$defaultUID"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" PrimaryGroupID "20"
    mkdir "$dataVolumePath/Users/$username"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" NFSHomeDirectory "/Users/$username"
    dscl -f "$dscl_path" localhost -passwd "$localUserDirPath/$username" "$userPassword"
    dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"

    echo -e "${GREEN}User created successfully.${NC}\n"
  else
    echo -e "${BLUE}User already exists.${NC}\n"
  fi
}

# Function to mount volumes
mountVolume() {
  local volumePath=$1
  if [ ! -d "$volumePath" ]; then
    diskutil mount "$volumePath" || {
      echo -e "${RED}Failed to mount volume at $volumePath.${NC}"
      exit 1
    }
  fi
}

# Function to define volume path
defineVolumePath() {
  local defaultVolume=$1
  local volumeType=$2
  if diskutil info "$defaultVolume" >/dev/null 2>&1; then
    echo "/Volumes/$defaultVolume"
  else
    echo "/Volumes/$(diskutil ap list | grep -A 5 "($volumeType)" | grep 'Name:' | awk -F'Name: ' '{print $2}' | xargs)"
  fi
}

# Main menu
PS3='Please select an option: '
options=("1. Check MDM Profile" "2. Remove MDM" "3. Create Local User" "4. Exit")

while true; do
  echo -e "\n${CYAN}--------------------------------------"
  echo -e "        MDM Bypass Tool"
  echo -e "--------------------------------------${NC}"
  select opt in "${options[@]}"; do
    case $opt in
      "1. Check MDM Profile")
        checkMDMEnrollment
        break
        ;;
      "2. Remove MDM")
        removeMDM
        break
        ;;
      "3. Create Local User")
        createLocalUser
        break
        ;;
      "4. Exit")
        echo -e "${BLUE}Exiting...${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        ;;
    esac
  done
  echo -e "\n${YELLOW}Credits: eudy97 | MDM-bypass${NC}\n"
done
