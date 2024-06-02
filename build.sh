#!/usr/bin/env bash
# shellcheck disable=SC2199
# shellcheck source=/dev/null
#
# Copyright (C) 2020-22 UtsavBalar1231 <utsavbalar1231@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GCC_64_DIR="$HOME/WeebX-Clang-17.0.6"
KBUILD_COMPILER_STRING=$($HOME/WeebX-Clang-17.0.6/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
KBUILD_LINKER_STRING=$($HOME/WeebX-Clang-17.0.6/bin/ld.lld --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' | sed 's/(compatible with [^)]*)//')
export KBUILD_COMPILER_STRING
export KBUILD_LINKER_STRING

DEVICE=$1
TYPE=$2
IS_KSU=""

if [ "${DEVICE}" = "picasso" ]; then
if [ "${TYPE}" = "ksu" ]; then
DEFCONFIG=picasso-ksu_defconfig
IS_KSU="-ksu"
else
DEFCONFIG=picasso_defconfig
fi
fi

#
# Enviromental Variables
#

DATE=$(date '+%Y%m%d-%H%M')

# Set our directory
OUT_DIR=out/

VERSION="Skizo${IS_KSU}-${DEVICE}-${DATE}"

# Export Zip name
export ZIPNAME="${VERSION}.zip"

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
    COUNT="$(grep -c '^processor' /proc/cpuinfo)"
    export KEBABS="$((COUNT + 2))"
fi

echo "Jobs: ${KEBABS}"

ARGS="ARCH=arm64 \
O=${OUT_DIR} \
CC=clang \
LLVM=1 \
LLVM_IAS=1 \
CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-gnu- \
CROSS_COMPILE_COMPAT=$GCC_64_DIR/bin/arm-linux-gnueabi- \
-j${KEBABS}"

dts_source=arch/arm64/boot/dts/vendor/qcom

START=$(date +"%s")

# Set compiler Path
export PATH="$HOME/WeebX-Clang-17.0.6/bin:$PATH"
export LD_LIBRARY_PATH=${HOME}/WeebX-Clang-17.0.6/lib64:$LD_LIBRARY_PATH

echo "------ Starting Compilation ------"

# Make defconfig
make -j${KEBABS} ${ARGS} ${DEFCONFIG}

# Make olddefconfig
cd ${OUT_DIR} || exit
make -j${KEBABS} ${ARGS} CC="ccache clang" HOSTCC="ccache gcc" HOSTCXX="cache g++" olddefconfig
cd ../ || exit

make -j${KEBABS} ${ARGS} CC="ccache clang" HOSTCC="ccache gcc" HOSTCXX="ccache g++" 2>&1 | tee build.log

find ${OUT_DIR}/$dts_source -name '*.dtb' -exec cat {} + >${OUT_DIR}/arch/arm64/boot/dtb

git checkout arch/arm64/boot/dts/vendor &>/dev/null
