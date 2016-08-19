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
set timeout 10
set user {<<USER>>}
set server {<<SERVER>>}
set password {<<PASSWORD>>}
set port {<<PORT>>}
set ssh_cmd {zssh -o ServerAliveInterval=60}
set ssh_opt {$user@$server -p $port}

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
