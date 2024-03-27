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
        esac

        #Per sf-storage e clearpass non serve nessuna regex
        if [ ${MODEL} == "sf-storage/" ] || [ ${MODEL} == "clearpass/" ]
        then

            #Lista le directory univoce per ogni sf-storage
            for BK in $(ls -d */)
            do

                #Entra nella sotto directory backup di ogni sf-storage oppure clearpass
                
                case ${MODEL} in
                    "sf-storage/")
                        pushd "${BK}/backups" &>/dev/null
                        ;;
                    "clearpass/")
                        pushd "${BK}" &>/dev/null
                        ;;
                esac

                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ $(find . -type f | wc -l) -gt 1 ] && [ $(($(find . -type f | wc -l) - $(find . -type f -mtime +30 | wc -l))) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -type f -mtime +30 -exec rm -f {} \; &>/dev/null
                fi

                #Ritorno alla directory sf-storage
                popd &>/dev/null
            done

        #Per ise non serve nessuna regex
        elif [ ${MODEL} == "ise/" ]
        then

            #Se dovesse essere presente solo 1 file non elimina nulla
            #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
            if [ $(find . -type f | wc -l) -gt 1 ] && [ $(($(find . -type f | wc -l) - $(find . -type f -mtime +30 | wc -l))) -gt 0 ]
            then

                #Elimina tutti i file più vecchi di 30 giorni
                find . -type f -mtime +30 -exec rm -f {} \; &>/dev/null
            fi

        #Se l'elenco dei backup fosse vuoto non faccio nulla
        elif [ -n ${BK_NAMES} ]
        then

            #Per ogni firewall elimino i file
            for BK in ${BK_NAMES[@]}
            do

                #Se dovesse essere presente solo 1 file non elimina nulla
                #Se il numero totale di file meno il numero di file più vecchi di 30 giorni è uguale a zero non elimina nulla
                if [ $(find . -type f -name "*${BK}*" | wc -l) -gt 1 ] && [ $(($(find . -type f -name "*${BK}*" | wc -l) - $(find . -type f -name "*${BK}*" -mtime +30 | wc -l))) -gt 0 ]
                then

                    #Elimina tutti i file più vecchi di 30 giorni
                    find . -type f -name "*${BK}*" -mtime +30 -exec rm -f {} \; &>/dev/null
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
