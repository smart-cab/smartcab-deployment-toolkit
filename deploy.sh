#!/usr/bin/env bash

setup_machines=( workstation hub )

settings_file=$1
secrets_file=./settings/secrets.sh

if [ -z $settings_file ]; then
    echo -e "${RED}Settings file were not provided as the first script argument${NOCOLOR}"
    exit 1
elif [ ! -f $settings_file ]; then
    echo -e "${RED}File $settings_file were not found${NOCOLOR}"
    exit 1
fi
source $settings_file
source $secrets_file

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

GREEN='\033[1;32m'
RED='\033[1;31m'
NOCOLOR='\033[0m'

if ! command_exists sshpass; then
    echo -e "${RED}sshpass utility is not installed${NOCOLOR}"
    exit 1
fi

for machine in "${setup_machines[@]}"
do
    host=${settings[${machine}_host]}
    port=${settings[${machine}_ssh_port]}
    user=${settings[${machine}_ssh_user]}
    password=${settings[${machine}_ssh_password]}
    setup_file=${machine}_setup.sh
    deploy_dir=${settings[${machine}_deploy_dir]}
    deploy_tools_dir=${settings[${machine}_deploy_dir]}/.deploy_tools

    echo -e "\n${GREEN}Running $machine (${user}@${host}) setup${NOCOLOR}"

    export password
    sshpass -epassword ssh -p $port ${user}@${host} "echo $password | sudo -S rm -rf ${deploy_dir} && mkdir -p ${deploy_tools_dir}"
    sshpass -epassword scp -P $port -r $setup_file settings ${user}@${host}:${deploy_tools_dir}/
    sshpass -epassword ssh -p $port ${user}@${host} "bash -s <<EOF
cd ${deploy_tools_dir}
./${setup_file} ${settings_file}
echo $password | sudo -S rm -rf ${deploy_tools_dir}
EOF"
    unset password
done

echo -e "${GREEN}Done!${NOCOLOR}"
