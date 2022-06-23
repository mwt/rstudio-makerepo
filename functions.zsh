#===================================================
# Function for timestamps
#===================================================

date_time_echo() {
    local DATE_BRACKET=$(date +"[%D %T]")
    echo "$DATE_BRACKET" "$@"
}


#===================================================
# Function for RPM Repo: called by make_repos()
#===================================================

update_rpm_repo() {
    local RPM_FILE="$1"
    local RPM_REPO_DIR="$2"

    # query rpm version and package name
    local RPM_FULLNAME=$(rpm -qp "${RPM_FILE}")

    # query rpm arch separately
    local RPM_ARCH=$(rpm -qp --qf "%{arch}" "${RPM_FILE}")

    {mkdir -p "${RPM_REPO_DIR}/${RPM_ARCH}/" &&
    cp "${RPM_FILE}" "${RPM_REPO_DIR}/${RPM_ARCH}/${RPM_FULLNAME}.rpm" &&
    date_time_echo "Copied ${RPM_FILE} to ${RPM_REPO_DIR}/${RPM_ARCH}/${RPM_FULLNAME}.rpm"} ||
    {date_time_echo "Failed to copy ${RPM_FILE} to ${RPM_REPO_DIR}/${RPM_ARCH}/${RPM_FULLNAME}.rpm"; exit 1}

    # remove and replace repodata
    createrepo_c  --update "${RPM_REPO_DIR}/${RPM_ARCH}" || exit 1

    rm -f "${RPM_REPO_DIR}/${RPM_ARCH}/repodata/repomd.xml.asc" &&
    gpg --default-key "$3" -absq -o "${RPM_REPO_DIR}/${RPM_ARCH}/repodata/repomd.xml.asc" "${RPM_REPO_DIR}/${RPM_ARCH}/repodata/repomd.xml" || exit 1
}
