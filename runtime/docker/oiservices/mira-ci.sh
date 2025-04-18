#!/bin/bash
#*******************************************************************************
# JMMC project ( http://www.jmmc.fr ) - Copyright (C) CNRS.
#*******************************************************************************

#
# MiRA wrapper for OIMAGING
#


# TRAP: Do not leave children jobs running if the shell has been canceled
cleanup_trap() {
    CHILDREN_PIDS=$(jobs -p)
    if [ -n "$CHILDREN_PIDS" ]
    then
        trap - EXIT
        echo -e "SHELL canceled, stopping $CHILDREN_PIDS"
        # we may try to send only TERM before a pause and a last loop with KILL signal ?
        kill $CHILDREN_PIDS

        echo -e "SHELL canceled, waiting on $CHILDREN_PIDS"
        # wait for all pids
        for pid in $CHILDREN_PIDS; do
            wait $pid
        done

        CHILDREN_PIDS=$(jobs -p)
        if [ -n "$CHILDREN_PIDS" ]
        then
            echo -e "SHELL canceled, killing $CHILDREN_PIDS"
            kill -9 $CHILDREN_PIDS
        fi
  fi
}
trap cleanup_trap EXIT


# HERE BEGINS THE SCRIPT

#make FULLSCRIPTNAME and SCRIPTROOT fully qualified
FULLSCRIPTNAME=$(readlink -f $0)
SCRIPTNAME=$(basename $FULLSCRIPTNAME)
SCRIPTROOT=$(readlink -f $( dirname $FULLSCRIPTNAME)/..)

#source main environment if any
if [ -e "$SCRIPTROOT/bin/env.sh" ]
then
  source $SCRIPTROOT/bin/env.sh
fi

# Print usage and exit program
function printUsage ()
{
  ymira -help
  exit 1
}


# command-line parameters will be given to MiRA
# just check
if [ $# -lt 2 ]
then
    echo "ERROR: Missing arguments: required input and output files"
    printUsage
fi

CLIARGS="$*"
shift $(( $# - 2 ))
INPUT="$(readlink -f $1)"
OUTPUT="$(readlink -f $2)"

FITS_VERIFY=`cat /opt/FITS_VERIFY`
# Check INPUT:
if [ "$FITS_VERIFY" -eq "1" ] ; then
  echo ""
  echo "--- fitsverify $INPUT ---"
  fitsverify -q $INPUT
  if [ $? != 0 ] ; then fitsverify $INPUT; fi
  echo "---"
fi

# Run execution
cd $SCRIPTROOT

echo "MIRA_CI_VERSION: ${MIRA_CI_VERSION}"

# start mira and get intermediate result
echo "cmd: \"ymira -oi-imaging -save_data_model -save_initial $CLIARGS\""
ymira -oi-imaging -save_data_model -save_initial $CLIARGS

# produce compliant oifits for OIMAGING:
if [ -e "${OUTPUT}" ] ; then

    # Check OUTPUT:
    if [ "$FITS_VERIFY" -eq "1" ] ; then
      echo ""
      echo "--- fitsverify $OUTPUT ---"
      fitsverify -q $OUTPUT
      if [ $? != 0 ] ; then fitsverify $OUTPUT; fi
      echo "---"
      echo "--- fitsverify $OUTPUT ---"
      dfits -x 0 $OUTPUT
      echo "---"
    fi

fi
