
# "What does it do and why?"

When I download (large) apps from the Mac App Store, I never know when they are finished downloading. I *could* keep an eye on the progress indicator in the Mac App Store app (inconvenient), or I could use Launchpad (gross).

Instead I decided to roll my own solution, which looks for .pkg files in the `com.apple.appstore` folder inside the `/private/var/folders` folder. If one is found, then it will be monitored every 15 seconds for changes.

The current size will be reported via [Growl](http://itunes.apple.com/us/app/growl/id467939042?mt=12) using [growlnotify](http://growl.info/downloads).

When the download completes, the app will be opened, and the Growl notification window will be dismissed.

# "What cool features does it have?"

The script tries to use the app icon for the growlnotify, so if you are downloading [iPhoto](http://itunes.apple.com/us/app/iphoto/id408981381?mt=12) then growlnotify will show iPhoto's icon in the notification window.

It will also try to extract the name of the app and include that in the growlnotify message as well.

It will open the app automatically when it finishes downloading. I only download apps if I want to use them, so this seemed like an obvious feature to me.

# Bugs, Limitations, Provisos, Disclaimers, etc #

If you start downloading one large file from the Mac App Store, and then pause it, and then start another one, this script may get confused.

This script must either be launched every X seconds using `launchd`, or manually. If you choose launchd you will need to do something like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.tjluoma.maswatch</string>
		<key>ProgramArguments</key>
		<array>
			<string>/usr/local/bin/maswatch.sh</string>
		</array>
		<key>StartInterval</key>
		<integer>60</integer>
	</dict>
	</plist>

(of course that assumes that you have saved `maswatch.sh` to `/usr/local/bin/maswatch.sh`)
		
and then add it to ~/Library/LaunchAgents/ with a name such as `com.tjluoma.maswatch.plist`

# Historical Trivia #

This is my first Github project. I am still figuring out how git works, so if something seems wrong/weird/etc it's probably because I'm mostly learning as I go.

# Did you know? #

This is unrelated to my script, but something I found out in testing: if you start a large download via the Mac App Store and then quit "App Store.app" the download continues. This can either be considered a bug or a feature, but it's an important note especially if you are on a metered Internet connection.

# Thanks to Rich Siegel

I [asked on Twitter](http://twitter.com/TJLuoma/status/129250886001233920) where to find Mac App Store downloads "in progress", and [Rich answered](http://twitter.com/siegel/status/129253398976536580), which is what inspired me to write this script.

In a nice little bit of symmetry, the script was written in [BBEdit](http://www.barebones.com/).

