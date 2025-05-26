#!/bin/bash

# directories 
CWD=$(pwd)                      
BINDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)  

ETCDIR="$BINDIR/etc"            
LIBDIR="$BINDIR/lib"            
LOGDIR="$BINDIR/logs"           
VARDIR="$BINDIR/var"            
TMPDIR="/tmp/$(basename "$0").$$" 

source $LIBDIR/variables.bash
source $LIBDIR/colors.bash


