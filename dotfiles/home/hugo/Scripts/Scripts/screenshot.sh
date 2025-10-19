#!/bin/sh
#
# GUI Screenshot Tool for Wayland Using Zenity, Grim and Slurp
# Last Modification: Thu Nov 14 18:05:37 PM WET 2024
#

TMP_DIR=/tmp
DEFAULT_FILENAME=screenshot.png

CHOICE=$(zenity --width=450 --height=400 --title "Screenshot" \
--text "Take a screenshot of" \
--list --radiolist \
--column "Pick" \
--column "Choice" \
True "whole screen" \
False "a part of the screen" \
False "a part of the screen and put the output into the clipboard");

# echo $CHOICE

case $CHOICE in
    "whole screen")
        grim "$TMP_DIR/$DEFAULT_FILENAME";;
    "a part of the screen")
        slurp | grim -g - "$TMP_DIR/$DEFAULT_FILENAME";;
    "a part of the screen and put the output into the clipboard")
        slurp | grim -g - - | wl-copy;
        exit;;
    "")
        exit;;
esac

FILE=$(zenity --file-selection --title="Select a File" --filename=$DEFAULT_FILENAME --save 2> /dev/null)

# echo $FILE

case $? in
    0)
        mv "$TMP_DIR/$DEFAULT_FILENAME" $FILE;;
    1)
        rm "$TMP_DIR/$DEFAULT_FILENAME";;
    -1)
        echo "An unexpected error has occurred.";;
esac

exit
