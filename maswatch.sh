#!/bin/zsh -f
#
#	Author:		TJ Luoma
#	Email:		luomat at gmail dot com
#	Date:		2011-10-26
#
#	Purpose: 	Show size of current download from Mac App Store. Useful for keeping an eye on larger downloads such as OS X releases.
#
#	URL:

#  find /var/folders/ -ipath '*com.apple.appstore*' -ls 2>/dev/null

# @TODO - check for when downloads are paused

NAME="$0:t"

die ()
{
	echo "$NAME: $@"
	exit 1
}


live ()
{
	echo "$NAME: $@"
	exit 0
}

timestamp () {
	strftime "%l:%M:%S %p" "$EPOCHSECONDS"
}

	# We're looking for a file named 'manifest.plist' anywhere under /var/folders/
PLIST=`find /var/folders -ipath '*com.apple.appstore*' -name manifest.plist  2>/dev/null`

	# if we don't find any, we haven't started any Mac App Store downloads recently
[[ -e "$PLIST" ]] || live "No manifest.plist found in /var/folders at `timestamp`"

	# If we get here, we have found a manifest.plist
	# so we need to convert it to XML so we can parse it
plutil -convert xml1 "$PLIST"

	# this saves the contents of PLIST to $ACTIVE_DOWNLOAD WITH some exceptions :
	# All tabs and newlines are deleted.
	# after that, we look for '</dict><dict>' which indicates more than one download in the manifest.plist
	# (usually one is active and the others are paused, but it could be that all of them are paused)
	# If we find '</dict><dict>' we separate them into separate lines
	# and then we look for any which are "Paused = False" (or "Not Paused", i.e. Active)


ACTIVE_DOWNLOAD=`egrep -v '<?xml |<!DOCTYPE|<plist version="1.0">' "$PLIST" | tr -d '\t|\n' | sed 's#</dict><dict>#</dict>\
<dict>#g' |\
fgrep '<key>paused</key><false/>'`



	# if the ACTIVE_DOWNLOAD is empty, it means that the PLIST exists but either all downloads have finished or all downloads
	# are paused.
[[ "$ACTIVE_DOWNLOAD" = "" ]] && live "No active downloads at `timestamp`"


	# IF we get here, we have an active download

	# We look for the filename, which is usually something like "mzm.qrnlnuht.pkg"
PKG_FILE_NAME=`echo $ACTIVE_DOWNLOAD 		| sed 's#.*<key>name</key><string>##g ; s#<.*##g' `

	# We look for the size of the download, in bytes
TOTAL_DOWNLOAD_SIZE=`echo $ACTIVE_DOWNLOAD 	| sed 's#.*<key>size</key><integer>##g ; s#<.*##g'`

	# We look for the "real name" of the download
DOWNLOAD_REAL_NAME=`echo $ACTIVE_DOWNLOAD 	| sed 's#.*<key>title</key><string>##g ; s#<.*##g' `

	# Get the icon for the download
APP_ICON_PATH=`echo $ACTIVE_DOWNLOAD 		| sed 's#.*<key>artwork-url</key><string>##g; s#flyingIcon</string>.*#flyingIcon#g'`

		# If we don't find the app icon, use a generic image for the Mac App Store
	[[ "$APP_ICON_PATH" = "" ]] && APP_ICON_PATH="/Applications/App Store.app/Contents/Resources/Images/appstore.png"

	# PKG_FILE_NAME gave us the filename, but not the full path. We want the full path
PKG_FILE_PATH=`find /var/folders -ipath '*com.apple.appstore*' -name "$PKG_FILE_NAME"  2>/dev/null`

	# How often do we want the script to loop?
SLEEP_TIME=15

	# init variables
OLD_SIZE=0
DIFF=''

################################################################################################################

################################################################################################################
#
#
# for file sizes
zmodload zsh/stat
# for using time without invoking `date`
zmodload zsh/datetime

# simple function to convert bytes to something more readable
bytes2readable () {

	METRIC=('KB' 'MB' 'GB' 'TB' 'XB' 'PB')

	MAGNITUDE=0

	PRECISION="scale=1"

	UNITS=`echo $@ | tr -d ','`

	while [ ${UNITS/.*} -ge 1000 ]
	do
		UNITS=`echo "$PRECISION; $UNITS/1000" | bc`
		((MAGNITUDE++))
	done

	echo "$UNITS ${METRIC[$MAGNITUDE]}"
}


#
################################################################################################################

	# The byte-size of the download is given in the PLIST, so we convert that with our function
TOTAL_READABLE=`bytes2readable $TOTAL_DOWNLOAD_SIZE`

################################################################################################################
#
#	the PKG_FILE_PATH file will be removed from /var/folders once the download is completed. That's how we know
#	the download is done.
#

echo "$NAME: PKG_FILE_PATH is: $PKG_FILE_PATH"

while [ -e "$PKG_FILE_PATH" ]
do

	CURRENT_SIZE_RAW=`stat -L +size "$PKG_FILE_PATH" `

	PERCENT_DONE=$(echo "scale=2;$CURRENT_SIZE_RAW/$TOTAL_DOWNLOAD_SIZE" | bc | tr -d '.' | sed 's#$# %#g')

	if (( $+commands[gdu] ))
	then
			# GNU du gives more accurate sizes than the standard 'du' due (I think to the 1000 vs 1024 issue)
			# so we use that if it's installed
		CURRENT_SIZE=$(gdu --si "$PKG_FILE_PATH" | awk '{print $1}')

	else

		CURRENT_SIZE=$(du -sh "$PKG_FILE_PATH" | awk '{print $1}')

	fi



	if [[ "$OLD_SIZE" != "0" ]]
	then
			DIFF=`expr $CURRENT_SIZE_RAW - $OLD_SIZE`

			DIFF_READABLE=`bytes2readable "$DIFF"`

			DIFF=`echo "\n[$DIFF_READABLE since last check]"`
	fi

	growlnotify -d "$NAME" \
				--sticky \
				--image "$APP_ICON_PATH" \
				--message "$CURRENT_SIZE ($PERCENT_DONE) of $TOTAL_READABLE $DIFF
				as of `timestamp`.
				Sleeping ${SLEEP_TIME}" "$DOWNLOAD_REAL_NAME"

	sleep $SLEEP_TIME

	OLD_SIZE="$CURRENT_SIZE_RAW"
done


growlnotify -d "$NAME" \
			--sticky \
			--image "$APP_ICON_PATH" \
			--message "Finished downloading ($CURRENT_SIZE of $TOTAL_READABLE)" "$DOWNLOAD_REAL_NAME"


#
################################################################################################################

exit 0
#EOF

# <dict><key>artwork-url</key><string>/var/folders/d_/6wf7f1891zv5rdkyd29t0s9c0000gn/C/com.apple.appstore/498672703/flyingIcon</string><key>assets</key><array><dict><key>name</key><string>mzm.uumkpgza.pkg</string><key>size</key><integer>2062666</integer><key>typeStr</key><string>app</string><key>url</key><string>http://a1852.phobos.apple.com/us/r1000/097/Purple/7e/01/ea/mzm.uumkpgza.pkg</string></dict></array><key>bundle-id</key><string>com.droplr.droplr-mac</string><key>failed</key><false/><key>in-server-queue</key><false/><key>item-id</key><integer>498672703</integer><key>kind</key><string>software</string><key>paused</key><false/><key>show-in-dock</key><true/><key>subtitle</key><string>Droplr, LLC</string><key>title</key><string>Droplr</string></dict></array></dict></plist>

# <dict><key>representations</key><array><dict><key>artwork-url</key><string>/var/folders/d_/6wf7f1891zv5rdkyd29t0s9c0000gn/C/com.apple.appstore/495026057/flyingIcon</string><key>assets</key><array><dict><key>name</key><string>mzm.qrnlnuht.pkg</string><key>size</key><integer>3703180282</integer><key>typeStr</key><string>app</string><key>url</key><string>http://a189.phobos.apple.com/us/r1000/089/Purple/00/33/f1/mzm.qrnlnuht.pkg</string></dict></array><key>bundle-id</key><string>com.apple.InstallAssistant.OSX8DP1</string><key>failed</key><false/><key>in-server-queue</key><false/><key>item-id</key><integer>495026057</integer><key>kind</key><string>software</string><key>paused</key><false/><key>show-in-dock</key><true/><key>subtitle</key><string>Apple</string><key>title</key><string>OS X Mountain Lion Developer Preview</string></dict>


