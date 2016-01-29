#!/bin/bash

# Бұл скриптаның көмегімен СОНО программасына арналған формаларды
# өз компьютеріңізге жүктеп ала аласыз. 
#
# TODO
#   1. әзірге скриптаны орындаған кезде формаларды бері қарай 
#      жүктейтін қылып жасаймыз
#
#   2. кейін аптасына бір рет автоматты түрде қадағалап отыратын
#      қылып жасау керек

source `dirname $0`/config.cfg
FILES="/tmp/flist.txt"

for FORM in $FORMS
do
  ftp -n -v $HOST 1>/dev/null <<EOT
  user $USER $PASSWORD
  passive
  cd /SONO/install/forms/$FORM
  nlist . $FILES
  bye
EOT

  echo $FORM >> list$$.txt
  for list in `cat $FILES`
  do
    if [[ $list -ge $last ]]
    then
          ftp -n $HOST <<EOT
            user $USER $PASSWORD
            passive
            binary
            cd /SONO/install/forms/$FORM/$list
            mget *
            cr
            bye
EOT
    fi
  done
done

mkdir update 2>/dev/null
mv form* update/

rm list$$.txt
