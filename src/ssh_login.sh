#!/usr/bin/expect -f  
set user [lindex $argv 0 ]     
set server [lindex $argv 1 ]     
set password [lindex $argv 2 ]
set port [lindex $argv 3 ]
set timeout 10     
spawn ssh $user@$server -p $port
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$password\r" }
}  
interact  
