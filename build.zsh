#!/bin/zsh
#===================================================
# This script generates the repositories
#===================================================

# To use with another project, change this string and reprepro/conf/distributions
DL_LINK_ARRAY=("https://rstudio.org/download/latest/stable/desktop/jammy/rstudio-latest-amd64.deb" "https://rstudio.org/download/latest/stable/desktop/redhat64/rstudio-latest-x86_64.rpm")

# Space delimited (string) list of URLs for which to ignore GPG
UNSIGNED="https://rstudio.org/download/latest/stable/desktop/redhat64/rstudio-latest-x86_64.rpm"

# Get folder that this script is in
SCRIPT_DIR=${0:a:h}

# Use packaged binaries if possible
PATH="$SCRIPT_DIR/usr/bin:$PATH"

# Folder where we store downloads json and version file
STAGING_DIR="${SCRIPT_DIR}/staging"

# Get function for creating deb/rpm repos
. "${SCRIPT_DIR}/functions.zsh"


#===================================================
# START Update
#===================================================

# Use the reprepro keyname with rpm
KEYNAME=$(sed -n 's/SignWith: \(.\+\)/\1/p' "${SCRIPT_DIR}/reprepro/conf/distributions")

# Loop over download links, download files, and make repos (using functions in functions.zsh)
for DL_LINK in ${DL_LINK_ARRAY}; {
    cd "${STAGING_DIR}"

    DL_FILE="${DL_LINK##*/}"

    # create timestamp to see if file changes (if file does not exist, set timestamp to epoch)
    touch -r ${DL_FILE} ${DL_FILE}.timestamp || touch --date '1970-01-01 00:00' ${DL_FILE}.timestamp

    wget -Nnv "${DL_LINK}" -o "${DL_FILE}.log" || {date_time_echo "download failed"; exit 1}

    # if the timestamp is newer, then proceed
    if [[ ${DL_FILE} -nt ${DL_FILE}.timestamp ]] {
        gpg --verify ${DL_FILE}
        if [[ $? -eq 0 || "$UNSIGNED " =~ "$DL_LINK " ]] {
            if [[ ${DL_FILE} == *.deb ]] {
                {reprepro --confdir "${SCRIPT_DIR}/reprepro/conf" includedeb any "${DL_FILE}" >> "${DL_FILE}.log" && 
                date_time_echo "Added ${DL_FILE} to APT repo."} ||
                {date_time_echo "Failed to add ${DL_FILE} to APT repo."; rm "${STAGING_DIR}/${DL_FILE}"; exit 1}
            } elif [[ ${DL_FILE} == *.rpm ]] {
                {update_rpm_repo "${DL_FILE}" "${SCRIPT_DIR}/dist/rpm" "${KEYNAME}" >> "${DL_FILE}.log" &&
                date_time_echo "Added ${DL_FILE} to YUM repo."} ||
                {date_time_echo "Failed to add ${DL_FILE} to YUM repo."; rm "${STAGING_DIR}/${DL_FILE}"; exit 1} 
            }
        } else {
            date_time_echo "GPG verification failed for ${DL_FILE}. Excluding from repo!"
            rm "${STAGING_DIR}/${DL_FILE}"
        }
    } else {
        date_time_echo "No new version of ${DL_FILE}."
    }
}


#===================================================
# POST Update
#===================================================

# delete timestamp files
rm ${STAGING_DIR}/*.timestamp
date_time_echo "Done!\n"
