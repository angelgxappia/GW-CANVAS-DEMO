#!/bin/bash

username=$1

if [[ $username == "" ]]; then
    echo "Usage: bash sf-package-installer.sh <salesforce_username>"
    exit 1
fi

# id of the package to install is stored in the file called PackageId
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_id=$(head -n 1 $script_path/PackageId)

echoerr() {
    echo -e "[\e[91mERROR\e[0m] $@" 1>&2
}

echosucc() {
    echo -e "[\e[92mSUCCESS\e[0m] $@" >&1
}

# checking if run by bash
current_shell=$(echo $(ps -o args= -p "$$") | awk '{print $1;}')
if [[ $current_shell != "bash" ]]; then
    echoerr "You are using wrong shell. Bash is required."
    exit 1
fi

# checking if jq is installed
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed. Aborting."; exit 1; }

get_json_property() {
    echo $(echo $2 | jq -r ".$1")
}

check_installation_status() {
    local loc_report_result=$(sfdx force:package:install:report -i $1 -u $2 --json 2>&1)
    local loc_report_status=$(get_json_property status "$loc_report_result")
    
    if [[ $loc_report_status -eq 1 ]]; then
        echo "$loc_report_result" >&1
        exit 0
    fi

    local loc_report_res_status=$(get_json_property result.Status "$loc_report_result")

    if [[ $loc_report_res_status == "IN_PROGRESS" ]]; then
        sleep 10
        echo "$(check_installation_status $1 $2)" >&1
        exit 0
    else
        echo "$loc_report_result" >&1
        exit 0
    fi
}

# uninstall - not available for 1st generation packages

# install
install_result=$(sfdx force:package:install -p=$package_id -u=$username --json 2>&1)
set -e

# check install request result: 1 - failed / 0 - started
install_status=$(get_json_property status "$install_result")

if [[ $install_status -eq 1 ]]; then
    # failed? => fail the script including proper message

    install_fail_msg=$(get_json_property message "$install_result")
    echoerr Install request failed with following message: \"$install_fail_msg\"
    exit 1
elif [[ $install_status -eq 0 ]]; then
    # started? => periodically check the status of the installation until it is done

    report_id=$(get_json_property result.Id "$install_result")
    report_result=$(check_installation_status $report_id $username)
    report_status=$(get_json_property status "$report_result")

    if [[ $report_status -eq 1 ]]; then
        report_fail_msg=$(get_json_property message "$report_result")
        echoerr Install request processing failed due to following error\(s\): \"$report_fail_msg\"
        exit 1
    fi
    
    report_res_status=$(get_json_property result.Status "$report_result")

    if [[ $report_res_status == "SUCCESS" ]]; then
        echosucc Install request processing \(for package $package_id\) has finished successfuly.
        exit 0
    else
        report_errors=$(get_json_property result.Errors "$report_result")
        echoerr Install request processing failed due to following error\(s\): \"$report_errors\"
        exit 1
    fi
else
    echoerr Install request failed with unknown status. The result of the install request: \"$install_result\"
    exit 1
fi
