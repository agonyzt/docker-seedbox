#!/bin/bash

function filebotize {
	filebot -script 'fn:amc' "$1" --output "$2/" --action move -non-strict --conflict auto --def 'skipExtract=y' 'subtitles=en' 'artwork=n' 'seriesFormat=TV Shows/{n.ascii()}/Season {s}/{n.ascii()} - {s00e00} - {t.ascii()}' 'movieFormat=Movies/{n.ascii()} ({y})/{n.ascii()}' --def excludeList=.processed.amc
}

function transcode {
	ffprobe "$1" 2>&1 | grep Stream | grep Video | grep h264 && VIDEO_CODEC="copy" || VIDEO_CODEC="h264"
	ffprobe "$1" 2>&1 | grep Stream | grep Audio | egrep "(ac3|aac)" && AUDIO_CODEC="copy" || AUDIO_CODEC="aac"
	ffmpeg -i "$1" -y -vcodec $VIDEO_CODEC -acodec $AUDIO_CODEC -strict -2 "$2"
}

function process {
	TRANSCODED_FILE="/tmp/$(basename "$1").mp4"
	transcode "$1" "$TRANSCODED_FILE"
	filebotize "$TRANSCODED_FILE" /library
	echo "$1" >> /library/.processed
}

if [[ $# -eq 1 ]]; then
	find "$1" -type f -print | while read line; do grep -F "$line" /library/.processed > /dev/null || echo "$line"; done | while read line; do file -b -i "$line" | grep video > /dev/null && process "$line"; done
fi
