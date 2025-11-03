#!/bin/bash
#curlftpfs ftp://10.73.19.117 ~/my_win -o debug,ftpfs_debug=3,no_verify_peer,no_verify_hostname,disable_eprt,custom_list="LIST",user=data:k4m1z4m4,gid=1000,uid=1000
curlftpfs ftp://10.73.19.117 ~/my_win -o ftpfs_debug=3,no_verify_peer,no_verify_hostname,disable_eprt,custom_list="LIST",user=data:k4m1z4m4,gid=1000,uid=1000,umask=113
