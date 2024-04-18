#!/bin/bash

#Directory dove risiedono i backup
BASEDIR="/data/"

#Mi sposto all'interno della directory dei backup
pushd ${BASEDIR} &>/dev/null

#Prende l'elenco di tutti gli IDRS
for IDRS in $(ls -d */)
do
    #Mi sposto dentro alla directory del cliente
    pushd ${IDRS} &>/dev/null

    #Prende l'elenco delle tecnologie backuppate
    for MODEL in $(ls -d */)
    do
        #Entra dentro a ogni directory
        pushd ${MODEL} &>/dev/null

        #Verifica il modello e associa la regex corretta per il nome dei file
        case ${MODEL} in
            "checkpoint/")

                #Lista tutti i file, con sed vado a cercare il nome del backup togliendo il residuo. Con sort -u tolgo le righe duplicate
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

        #Per sf-storage e clearpass non serve nessuna regex
        if [ ${MODEL} == "sf-storage/" ] || [ ${MODEL} == "clearpass/" ]
        then

            #Lista le directory univoche per ogni sf-storage
            for BK in $(ls -d */)
            do

                #Per sf-storage entra in ogni sotto directory univoca aggiungendo backup, per gli altri entra nella sotto directory univoca
                
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
                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -type f -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
                fi

                #Ritorno alla directory sf-storage
                popd &>/dev/null
            done

        #Per ise non serve nessuna regex
        elif [ ${MODEL} == "ise/" ]
        then
            RETENTION="+30"
            ALL_BACKUP=$(find . -type f | wc -l)
            OLD_BACKUP=$(find . -type f -mtime ${RETENTION} | wc -l)
            #Se dovesse essere presente solo 1 file non elimina nulla
            #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
            if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
            then

                #Elimina tutti i file più vecchi di 30 giorni
                find . -type f -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
            fi

        #Se l'elenco dei backup fosse vuoto non faccio nulla
        elif [ -n ${BK_NAMES} ]
        then

            #Per ogni firewall elimino i file
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
                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ ${ALL_BACKUP} -gt 1 ] && [ $((${ALL_BACKUP} - ${OLD_BACKUP})) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -type f -name "*${BK}*" -mtime ${RETENTION} -exec rm -f {} \; &>/dev/null
                fi
            done
        fi

        #Ritorno alla directory del cliente per cambiare tecnologia
        popd &>/dev/null

        #Elimino la variabile ad ogni ciclo
        unset BK_NAMES
    done

    #Torno nella directory dei backup per cambiare cliente
    popd &>/dev/null
done

popd &>/dev/null

exit 0
