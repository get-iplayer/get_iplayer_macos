#!/bin/bash
trap 'exec bash -l' SIGINT SIGTERM
/usr/local/bin/get_iplayer.cgi
