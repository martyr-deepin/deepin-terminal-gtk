#! /usr/bin/expect -f

## All possible interactive messages:
# Are you sure you want to continue connecting (yes/no)?
# password:
# Enter passphrase for key

## Main
if {$argc < 2} {
    set scriptname [lindex [split $argv0 "/"] end]
    send_user "Usage: $scriptname <user> <host>\n"
    send_user "Environment variables: EXP_SSH_PASS, EXP_SSH_PORT, EXP_SSH_OPT\n"
    exit 1
}

# Setup variables
set timeout 10
set user [lindex $argv 0]
set host [lindex $argv 1]
set ssh_cmd "ssh"
set ssh_opt "$user@$host"

set password ""
if {[info exists env(EXP_SSH_PASS)]} {
    set password $env(EXP_SSH_PASS)
}

if {[info exists env(EXP_SSH_PORT)]} {
    set ssh_opt "$ssh_opt -p $env(EXP_SSH_PORT)"
}

if {[info exists env(EXP_SSH_OPT)]} {
    set ssh_opt "$ssh_opt $env(EXP_SSH_OPT)"
}

# Spawn and expect
eval spawn $ssh_cmd $ssh_opt
if {[string length $password]} {
    expect {
        timeout {send_user "ssh connection time out, please operate manually\n"}
        -nocase "(yes/no)\\?" {send "yes\r"; exp_continue}
        -nocase -re "password:|enter passphrase for key" {
            send "$password\r"
        }
    }
}

interact
