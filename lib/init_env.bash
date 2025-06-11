#!/bin/bash

# directories 
CWD=$(pwd)                      
BINDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)  

DIR="$BINDIR/bin"  
ETCDIR="$BINDIR/etc"            
LIBDIR="$BINDIR/lib"            
LOGDIR="$BINDIR/logs"           
VARDIR="$BINDIR/var" 
SCRIPTDIR="$BINDIR/scripts"            
TMPDIR="/tmp/$(basename "$0").$$" 

source $LIBDIR/variables.bash
source $LIBDIR/colors.bash
source $LIBDIR/aws_config.bash