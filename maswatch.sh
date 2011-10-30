#!/bin/zsh
#
#	Author:	Timothy J. Luoma
#	Email:		luomat at gmail dot com
#	Date:		2011-10-29
#
#	Purpose:
#
#	URL:

NAME="$0:t"

# @TODO - what happens if user manually pauses download?!

PKG=`find /private/var/folders -ipath '*com.apple.appstore/*/*.pkg' 2>/dev/null -print`

if [ "$PKG" = "" ]
then
     # growlnotify -d "$NAME" --appIcon 'App Store' --message "No downloads are active at this time" "$NAME"
      exit 0
fi

PKG_DIR="$PKG:h"


ICON="$PKG_DIR/flyingIcon"


#
#
#


zmodload zsh/datetime

timestamp () {
      strftime "%l:%M:%S %p" "$EPOCHSECONDS"
}



PKG=`find /private/var/folders -ipath '*com.apple.appstore/*/*.pkg' 2>/dev/null | head -1`


get_app_name ()
{
      # @TODO - not sure how early in the process this is available
      BOM=`pkgutil --bom "$PKG"`

      APPNAME=`lsbom "$BOM" | fgrep '.app' |  sed 's#.app.*#.app#g ; s#./Applications/##g' | sort -u`

      if [ "$APPNAME" = "" ]
      then
            APPNAME="App Store Download"
      fi
}

get_app_name

while [ -e "$PKG" ]
do
      [[ "$APPNAME" = "App Store Download" ]] && get_app_name

      SIZE=`du -sh "$PKG" | awk '{print $1}'`

      printf "$SIZE\n@ `timestamp`" | growlnotify -d "$NAME"  --image "$ICON"  --appIcon 'App Store' --sticky --message - "$APPNAME"

      sleep 15
done


APP="/Applications/$APPNAME"

if [ -d "$APP" ]
then

      growlnotify -d "$NAME" --image "$ICON" --appIcon 'App Store' --sticky --message "opening $APP" "$NAME"
fi

open "$APP"

exit 0
#EOF