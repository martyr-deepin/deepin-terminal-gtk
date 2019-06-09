#! /usr/bin/expect -f

# Copyright (C) 2011 ~ 2016 Deepin, Inc.
#               2011 ~ 2016 Wang Yong
#
# Author:     Wang Yong <wangyong@deepin.com>
# Maintainer: Wang Yong <wangyong@deepin.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

## All possible interactive messages:
# Are you sure you want to continue connecting (yes/no)?
# password:
# Enter passphrase for key

## Main
# Delete self for secret, will not affect the following code
file delete $argv0

# Setup variables
# Set timeout -1 to avoid remote server dis-connect.
set timeout -1
set user {<<USER>>}
set server {<<SERVER>>}
set password "<<PASSWORD>>"
set private_key {<<PRIVATE_KEY>>}
set port {<<PORT>>}
set authentication {<<AUTHENTICATION>>}
set ssh_cmd {zssh -X -o ServerAliveInterval=60}
set ssh_opt {$user@$server -p $port -o PubkeyAuthentication=$authentication}
set remote_command {<<REMOTE_COMMAND>>}

# This code is use for synchronous pty's size to avoid terminal not update if login in remote server.
trap {
    stty rows [stty rows] columns [stty columns] < $spawn_out(slave,name)
} WINCH

# Spawn and expect
eval spawn $ssh_cmd $ssh_opt $private_key -t $remote_command exec \\\$SHELL -l
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

