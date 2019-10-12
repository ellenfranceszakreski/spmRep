#!/bin/sh
# source load_modules.sh
# load all required modules
# Note: when accessing the CIC remotely, make sure you ssh again: ssh -Y zakell@cicws01

echo "loading required modules"
module load matlab/R2012a SPM12/r6685 qbatch # scripts are compatible with this version of MATLAB and this version of SPM
module list

# done
