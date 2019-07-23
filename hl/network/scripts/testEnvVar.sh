#!/bin/bash

CURRENT_DIR=$PWD

source ../.env

varName=$1

if [ -z "${!varName}" ]; then
	echo "not set"
else
	echo "${!varName}"
fi 

