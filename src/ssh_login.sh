#!/usr/bin/expect -f  
set user [lindex $argv 0 ]
set server [lindex $argv 1 ]
set password [lindex $argv 2 ]
set port [lindex $argv 3 ]
set timeout 10
#puts $user
#puts $server
#puts $password
#puts $port
if { ![string compare $port "" ] == 0 } { spawn ssh $user@$server -p $port } else { spawn ssh $user@$server };

if { ![string compare $password ""] == 0 } {
    #puts "PASSWORD GIVEN!"
    expect {
        "*yes/no" { send "yes\r"; exp_continue}
        "*password:" { send "$password\r" }
        exp_continue
    }
} else {
    expect {
        "*yes/no" { send "yes\r"; exp_continue }
        exp_continue
    }
}

#puts "interacting"
interact
