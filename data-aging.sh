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
            "checkpoint")

                #Lista tutti i file, con sed favo a cercare il nome del firewall togliendo il residuo. Con sort -u tolgo le righe duplicate
                FW_NAMES=( $(ls | sed -E 's/^backup_-(.*)_.*_.*_.*_.*_.*_.*\.tgz/\1/g' | sort -u) )
                ;;
            "fauth")
                FW_NAMES=( $(ls | sed -E 's/(^.*)_.*_.*-.*\.conf/\1/g' | sort -u) )
                ;;
            "ise")
                FW_NAMES=( $(ls | sed -E 's/Backup_(.*)-.*-.*\.tar\.gpg/\1/g' | sort -u) )
                ;;
        esac

        #Per sf-storage non serve nessuna regex
        if [ ${MODEL} == "sf-storage/" ]
        then

            #Lista le directory univoce per ogni sf-storage
            for FW in $(ls -d */)
            do

                #Entra nella sotto directory backup di ogni sf-storage
                pushd "${FW}/backups" &>/dev/null

                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ $(find . | wc -l) -gt 1 ] && [ $(($(find . | wc -l) - $(find . -mtime +30 | wc -l))) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -mtime +30 -exec rm -f {} \; &>/dev/null
                fi

                #Ritorno alla directory sf-storage
                popd &>/dev/null
            done

        #Se l'elenco dei firewall fosse vuoto non faccio nulla
        elif [ -n ${FW_NAMES} ]
        then

            #Per ogni firewall elimino i file
            for FW in ${FW_NAMES[@]}
            do

                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ $(find . -name "*${FW}*" | wc -l) -gt 1 ] && [ $(($(find . -name "*${FW}*" | wc -l) - $(find . -name "*${FW}*" -mtime +30 | wc -l))) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -name "*${FW}*" -mtime +30 -exec rm -f {} \; &>/dev/null
                fi
            done
        fi

        #Ritorno alla directory del cliente per cambiare tecnologia
        popd &>/dev/null

        #Elimino la variabile ad ogni ciclo
        unset FW_NAMES
    done

    #Torno nella directory dei backup per cambiare cliente
    popd &>/dev/null
done

popd &>/dev/null

exit 0