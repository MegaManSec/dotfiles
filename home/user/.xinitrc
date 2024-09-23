#!/bin/sh
rm $HOME/.serverauth.*

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

urxvtd -q -f -o
xrandr --output eDP-1 --mode 2880x1800

xautolock -detectsleep -time 10 -secure -locker "sh -c 'i3lock -f ; sudo acpiconf -s 3'" &

exec i3
