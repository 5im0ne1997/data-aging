#!/bin/bash

#Directory backup
BASEDIR="/data/"

#move to backup directory
pushd ${BASEDIR} &>/dev/null

#Get customer ID
for IDRS in $(ls -d */)
do
    #Move to customer ID
    pushd ${IDRS} &>/dev/null

    #Get list of backupped tecnology
    for MODEL in $(ls -d */)
    do
        #Move to any folder
        pushd ${MODEL} &>/dev/null

        #Check the template and associate the correct regex for the filename
        case ${MODEL} in
            "checkpoint/")

                #List all files, with sed I search for the name of the backup by removing the duplicate. With sort -u I remove duplicate rows
                BK_NAMES=( $(ls | sed -E 's/(^.*)_.*_.*_.*_.*_.*_.*\.tgz/\1/g' | sort -u) )
                ;;
            "fauth/")
                BK_NAMES=( $(ls | sed -E 's/(^.*)_.*_.*-.*\.conf/\1/g' | sort -u) )
                ;;
            "cp_small/")
                BK_NAMES=( $(ls | sed -E 's/(^.*)_.*_.*_.*_.*_.*\.zip/\1/g' | sort -u) )
                ;;
            "libraesva/")
                BK_NAMES=( $(ls | sed -E 's/(^.*)-.*-.*\.gpg/\1/g' | sort -u) )
                ;;
            "netapp/")
                BK_NAMES=( $(ls | sed -E 's/(^.*)\..*-.*_.*\.7z/\1/g' | sort -u) )
                ;;
        esac

        #No regex is needed for sf-storage and clearpass
        if [ ${MODEL} == "sf-storage/" ] || [ ${MODEL} == "clearpass/" ]
        then

            #List the unique directories for each sf-storage 
            for BK in $(ls -d */)
            do

                #For sf-storage it enters each unique sub-directory by adding backups, for others it enters the unique sub-directory
                
                case ${MODEL} in
                    "sf-storage/")
                        pushd "${BK}/backups" &>/dev/null
                        ;;
                    *)
                        pushd "${BK}" &>/dev/null
                        ;;
                esac
                RETENTION="+30"
                ALL_BACKUP=$(find . -type f | wc -l)
                OLD_BACKUP=$(find . -type f -mtime ${RETENTION} | wc -l)
                #If only 1 file is present, do not delete anything
                #If the total number of files minus the number of files older than 30 days is zero, it does not delete anything
                if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
                then

                    #Deletes all files older than 30 days
                    find . -type f -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
                fi

                #Return to the sf-storage directory
                popd &>/dev/null
            done

        #No regex is needed for ise
        elif [ ${MODEL} == "ise/" ]
        then
            RETENTION="+30"
            ALL_BACKUP=$(find . -type f | wc -l)
            OLD_BACKUP=$(find . -type f -mtime ${RETENTION} | wc -l)
            #If only 1 file is present, do not delete anything
            #If the total number of files minus the number of files older than 30 days is zero, it does not delete anything
            if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
            then

                #Deletes all files older than 30 days
                find . -type f -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
            fi

        #If the backup list were empty, I would do nothing
        elif [ -n ${BK_NAMES} ]
        then

            #For each firewall I delete files
            for BK in ${BK_NAMES[@]}
            do
                if [ ${MODEL} == "netapp/" ]
                then
                    case $(echo ${BK} | sed -E 's/.*\.(.*)/\1/g') in
                        "8hour")
                            RETENTION="+1"
                            ;;
                        "daily")
                            RETENTION="+7"
                            ;;
                        "weekly")
                            RETENTION="+30"
                            ;;
                        *)
                            RETENTION="+30"
                            ;;
                else
                    RETENTION="+30"
                fi
                ALL_BACKUP=$(find . -type f -name "*${BK}*" | wc -l)
                OLD_BACKUP=$(find . -type f -name "*${BK}*" -mtime ${RETENTION} | wc -l)
                #If only 1 file is present, do not delete anything
                #If the total number of files minus the number of files older than 30 days is zero, it does not delete anything
                if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
                then

                    #Deletes all files older than 30 days
                    find . -type f -name "*${BK}*" -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
                fi
            done
        fi

        #Return to customer directory to change technology
        popd &>/dev/null

        #I delete the variable at each cycle
        unset BK_NAMES
    done

    #Returning to the backup directory to change clients
    popd &>/dev/null
done

popd &>/dev/null

exit 0
