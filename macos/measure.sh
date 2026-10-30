#!/bin/zsh
# Relaunch the wallpaper and report its total CPU (app + its WebKit helpers) over 30 s.
pkill -x CommonWallpaper; sleep 2
before=$(pgrep -f 'com\.apple\.WebKit\.' | sort)
open ~/Applications/CommonWallpaper.app; sleep 10
after=$(pgrep -f 'com\.apple\.WebKit\.' | sort)
pids=($(pgrep -x CommonWallpaper) $(comm -13 <(echo $before) <(echo $after)))
cpu() { ps -o time= -p ${(j:,:)pids} | awk -F'[:.]' '{s+=$1*60+$2+$3/100} END{print s}' }
a=$(cpu); sleep 30; b=$(cpu)
echo "pids: $pids"
echo "avg CPU over 30s: $(( (b - a) / 30 * 100 ))% of one core"
ps -o pid,rss,comm -p ${(j:,:)pids} | awk 'NR>1{m+=$2} END{print "memory:", int(m/1024), "MB"}'
