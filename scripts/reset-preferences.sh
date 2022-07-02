#!/bin/sh

# Reset window size.
defaults delete com.palantir.gpg-tap-notifier

# Any values configured in the GUI can be reset by deleting the App Group preferences.
rm -rf ~/Library/Group\ Containers/PXSBYN8444.com.palantir.gpg-tap-notifier/Library/Preferences
