#!/bin/bash

# Check variables
# ------------------------------------------------------------------------
if [[ -z "$TORCH_REPO" ]] ; then
    TORCH_REPO="https://github.com/ROCmSoftwarePlatform/pytorch.git"
    export TORCH_REPO
    echo "Setting TORCH_REPO to $TORCH_REPO by default."
fi

if [[ -z "$TORCH_BRANCH" ]] ; then
    echo "WARNING: No branch was supplied with TORCH_BRANCH, main branch will be used."
fi

if [[ -z "$TORCH_HASH" ]] ; then
    echo "WARNING: No torch hash supplied, TOT will be used"
fi

TORCH_BUILD_LOG=build-$TORCH_HASH.log
export TORCH_BUILD_LOG

# Clean environment
# -----------------------------------------------------------------------
pip3 uninstall torch -y -q && rm -rf pytorch
 
# Initialise repo
# -----------------------------------------------------------------------
printf "\nCloning repository...\n"
printf "Repository:  %s\nBranch:  %s\nCommit:  %s\nBuild log:  %s\n" "$TORCH_REPO" "$TORCH_BRANCH" "$TORCH_HASH" "$TORCH_BUILD_LOG"
git clone --recursive $TORCH_REPO -b $TORCH_BRANCH 2>&1 &> $TORCH_BUILD_LOG
cd pytorch
git checkout $TORCH_HASH 2>&1 &> $TORCH_BUILD_LOG
git submodule sync 2>&1 &> $TORCH_BUILD_LOG
git submodule update --init --recursive 2>&1 &> $TORCH_BUILD_LOG

# Build pytorch
# -------------------------------------------------------------------------
MAX_JOBS=`nproc`
printf "\nBulding pytorch...\n"
printf "MAX_JOBS:  %s\nPYTORCH_ROCM_ARCH:  %s\nBuild log:  %s\n\n" "$MAX_JOBS" "$TORCH_BUILD_LOG"
MAX_JOBS=$MAX_JOBS .jenkins/pytorch/build.sh 2>&1 &> $TORCH_BUILD_LOG

# Run a simple torch example
# --------------------------------------------------------------------------
cd ../
program_output=$(python -c 'import torch; torch.cuda.is_available()' 2>&1 >/dev/null | grep -Eo "ImportError")
if [[ -z "$program_output" ]] ; then
    echo "BUILD_SUCCESS"
else
    echo "BUILD_FAILED"
fi
