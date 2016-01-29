#!/bin/bash

# Бұл скриптаның көмегімен СОНО программасына арналған формаларды
# өз компьютеріңізге жүктеп ала аласыз. 
#
# TODO
#   + әзірге скриптаны орындаған кезде формаларды бері қарай 
#     жүктейтін қылып жасаймыз
#   + config.cfg файлында көрсетілгенге сәйкес керекті формаларды 
#     жүктеп тұр
#   + сол файлда көрсетілген күннен кейін шыққан формаларды
#     қатесіз тауып тұр
#   + бір рет жұктеп алған файлын қайта жүктемейді
#   + басқа каталогтан жіберсең де керекті файлдарды қатесіз
#     тауып тұр 
#   - обновление тұратын папкалардың қалай реттелу керек екенін
#     білмей отырмын
#   - кейін аптасына бір рет автоматты түрде қадағалап отыратын
#     қылып жасау керек 
#       (мүмкін айына бір рет жасау керек шығар, әлде
#        отчеттың уақыты тақаған кезде жасау керек болар,
#        жоқ обновление шыққан кезде уведомление беретін
#        етіп жасау керек болар? Осы мәселе шешілгенде 
#        папкаларды қалай қалай реттеу керек екені шешіледі)

cd `dirname $0`
# sono.sh скриптісі тұрған катологқа көшеміз

source ./config.cfg

# $FORMS, $USER, $PASSWORD - config.cfg файлынан алынады
# $FORMS-та көрсетілген каталогтардың тізімі ./dirlist 
# файлына жазылады
ftp -n -v $HOST 1>/dev/null <<EOT
  user $USER $PASSWORD
  passive
  cd /SONO/install/forms
  mls $FORMS dirlist
  bye
EOT

# content of file ./dirlist like this
# 
# 100.00/20150119
# 100.00/20150704
# 300.00/20090427
# 300.00/20090515

# awk [-Fc] [-f file] [files]
#   file - файл где записаны программы на языке AWK
#          pattern {action}
#          pattern {action}
#           ...
# 
#   files - обработкаға түсетін файл
#   -Fc  - разделитель полей
# 
# awk [-Fc] [prog] [files]
#   prog - программа, вида: 'pattern ${$action$}$'
#   files - обработкаға түсетін файл
#   -Fc  - разделитель полей

awk -F/ '$2>='$last'{print}' dirlist > uplist

if [[ -f updated ]]
then
  diff -u uplist updated | sed -e '1,3d' -e '/^ /d' | awk -F- '{print $2}' | sed -e '/^$/d' >up$$
else
  cp uplist up$$
fi

upfiles=`cat up$$`
echo $upfiles

#if [[ !$upfiles ]]
for file in $upfiles
do
ftp -n -v ftp.salyk.kz >/dev/null <<EOT
  user $USER $PASSWORD
  pass
  cd SONO/install/forms/$file
  binary
  mget *
  cr
  bye
EOT
done

todaydir=`date +%Y%m`
today=`date +%Y%m%d`

if [[ -s up$$ ]]
then
  if [[ ! -d $todaydir ]]
  then
    mkdir $todaydir
  fi

  mv uplist updated
  
  if [[ ! -d update ]]
  then
    mkdir update
  fi

  #echo `cat up$$` '---'

  cp form* $todaydir/ #&>/dev/null
  mv form* update/ #&>/dev/null

  sed -i /^last/s/[0-9]*$/$today/ config.cfg
else
  rm uplist
fi

rm up$$ dirlist

cd `echo $OLDPWD`
