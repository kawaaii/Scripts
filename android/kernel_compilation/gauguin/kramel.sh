#!/usr/bin/env bash
# Copyright (c) 2021-2023, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.
# Version: 10.1
# Revision: 29-06-2023
# shellcheck disable=SC2312
# shellcheck disable=SC1091
# shellcheck disable=SC2154

## Global variables
# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"

# User details
USER='hridaya'
HOST='wsl'
TOKEN='ADD YOUR TOKEN HERE'
CHATID='ADD YOUR CHATID HERE'
BOT_MSG_URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot${TOKEN}/sendDocument"
DEVICE='Redmi Note 9 Pro 5G Series'
CODENAME='gauguin'
PROCS="$(nproc --all)"
DFCF="gauguin_defconfig"

# Paths
KERNEL_DIR="${PWD}"
TOOLCHAIN="${HOME}/toolchains"
ZIP_DIR="${HOME}/ak3"

## Go to kernel directory
cd "${KERNEL_DIR}" || exit 1

## Functions
# A function to showcase the help section of the script
help() {
	echo -e "${CYAN}
Usage ./kramel.sh [ARG]

Arguments:
 --thin-lto		enables thin LTO
 --full-lto		enables full LTO
 --non-lto		disables LTO
 --release		sends final zip to release channel/group
 --help			shows this menu
"
}

# Generic function to send a message or file via Telegram's BOT API
tg_post() {
	local TYPE="$1"
	local CONTENT="$2"
	local CAPTION="$3"

	if [[ "$TYPE" == "message" ]]; then
		curl -s -X POST "${BOT_MSG_URL}" \
			-d chat_id="${CHATID}" \
			-d "disable_web_page_preview=true" \
			-d "parse_mode=html" \
			-d text="${CONTENT}"
	elif [[ "$TYPE" == "file" ]]; then
		local MD5CHECK=$(md5sum "${CONTENT}" | cut -d' ' -f1)
		curl --progress-bar -F document=@"${CONTENT}" "${BOT_BUILD_URL}" \
			-F chat_id="${CHATID}" \
			-F "disable_web_page_preview=true" \
			-F "parse_mode=html" \
			-F caption="${CAPTION} <b>MD5 Checksum: </b><code>${MD5CHECK}</code>"
	fi
}

# A function to send message(s) via Telegram's BOT API
tg_post_msg() {
	tg_post "message" "$1"
}

# A function to send file(s) via Telegram's BOT API
tg_post_log() {
	tg_post "file" "$1" "$2"
}

tg_post_build() {
	tg_post "file" "$1" "$2"
}

## Argument list
for args in "${@}"; do
	case "${args}" in
	"--thin-lto")
		LTO_VARIANT='THIN_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_CLANG_THIN'
		;&
	"--full-lto")
		LTO_VARIANT='FULL_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_NONE'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_CLANG_FULL'
		;;
	"--non-lto")
		LTO_VARIANT='NON_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_CLANG_THIN'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_CLANG_FULL'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_NONE'
		;;
	"--release")
		CHATID='ADD YOUR CHATID HERE'
		;;
	"--help")
		help
		exit 0
		;;
	*)
		echo -e "${YELLOW}Invalid argument(s) '${*}'. Run './kramel.sh --help'"
		sleep 1
		exit 1
		;;
	esac
done

## Export environment variables
export KBUILD_BUILD_USER="${USER}"
export KBUILD_BUILD_HOST="${HOST}"
export PATH="${TOOLCHAIN}/clang-neutron/bin:${PATH}"
export ARCH='arm64'
export PYTHON='python3'

## Set compiler to Clang
KBUILD_COMPILER_STRING="$(${TOOLCHAIN}/clang-neutron/bin/clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')"
MAKE+=(
	O=../work
	CC='ccache clang'
	LLVM=1
	LLVM_IAS=1
)

## Start compilation
rm -rf "${KERNEL_DIR}/../work" "${KERNEL_DIR}/../log.txt"
if [[ ! -d "${KERNEL_DIR}/../out" ]]; then
	mkdir "${KERNEL_DIR}/../out"
fi

BUILD_START="$(date +"%s")"
make -j"${PROCS}" "${DFCF}" "${MAKE[@]}"
echo -e "\n${CYAN}	Build started..."
echo -e "${GREEN}"
time make -j"${PROCS}" "${MAKE[@]}" 2>&1 | tee ../log.txt
git restore "${KERNEL_DIR}/arch/arm64/configs/${DFCF}"
echo -e "\n${CYAN}	Build finished. Zipping...\n"
BUILD_END="$(date +"%s")"
DIFF="$((BUILD_END - BUILD_START))"

## Start zipping and posting
if [[ -f "${KERNEL_DIR}/../work/arch/arm64/boot/Image" ]]; then
	tg_post_log "../log.txt" "Compiled kernel successfully!!"
	source "${KERNEL_DIR}/../work/.config"

	KNAME="$(echo "${CONFIG_LOCALVERSION}" | cut -c 2-)"
	KV="$(cat <"${KERNEL_DIR}/../work/include/generated/utsrelease.h" | cut -c 21- | tr -d '"')"
	DATE="$(date +"%Y-%m-%d %H:%M")"
	COMMIT_NAME="$(git show -s --format=%s)"
	COMMIT_HASH="$(git rev-parse --short HEAD)"

	ZIP_NAME="${KNAME}-${CODENAME^^}-$(date +"%H%M")"
	FINAL_ZIP="${ZIP_NAME}-signed.zip"

	cp "${KERNEL_DIR}/../work/arch/arm64/boot/Image" "${ZIP_DIR}"
	cp "${KERNEL_DIR}/../work/arch/arm64/boot/dtbo.img" "${ZIP_DIR}"
	cd "${ZIP_DIR}" || exit 1
	zip -r9 "${ZIP_NAME}.zip" * -x README.md LICENSE FUNDING.yml zipsigner*
	java -jar zipsigner* "${ZIP_NAME}.zip" "${FINAL_ZIP}"
	echo -e "\n${CYAN}	Pushing kernel zip...\n"

	tg_post_build "${FINAL_ZIP}"

	cp "${FINAL_ZIP}" "${KERNEL_DIR}/../out"
	rm -rf *.zip Image dtbo.img
	cd ${KERNEL_DIR}

	# Print the build information
	tg_post_msg "
	=========Custom Kernel=========
	Compiler: <code>${KBUILD_COMPILER_STRING}</code>
	Linux Version: <code>${KV}</code>
	Maintainer: <code>${USER}</code>
	Device: <code>${DEVICE}</code>
	Codename: <code>${CODENAME}</code>
	Zipname: <code>${FINAL_ZIP}</code>
	LTO Variant: <code>${LTO_VARIANT}</code>
	Build Date: <code>${DATE}</code>
	Build Duration: <code>$((DIFF / 60)).$((DIFF % 60)) mins</code>
	Last Commit Name: <code>${COMMIT_NAME}</code>
	Last Commit Hash: <code>${COMMIT_HASH}</code>
	"
else
	tg_post_build "../log.txt" "Build failed!!"
	echo -e "\n${RED}	Kernel image not found"
	exit 1
fi
