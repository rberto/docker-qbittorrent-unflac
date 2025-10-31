#!/bin/bash
#
#
# A shell script designed to be executed by qBittorrent's "Run external program on torrent completion"
#  Determines if the completed torrent is a directory, if so iterate through all directories in the torrent directory
#  looking for single flac/ape/m4a/wv/wav files.  If there's a single file, check for a matching name .cue file.
#  If there is, extract the single file album using https://github.com/ftrvxmtrx/split2flac
#
# An example how to fill in qBittorrent's "Run external program on torrent completion" to execute this script
# /bin/bash -c "chmod +x /path/to/split_album.sh; /path/to/split_album.sh '%R'
#
# Supported parameters (case sensitive):
# - %N: Torrent name
# - %L: Category
# - %G: Tags (separated by comma)
# - %F: Content path (same as root path for multifile torrent)
# - %R: Root path (first torrent subdirectory path)
# - %D: Save path
# - %C: Number of files
# - %Z: Torrent size (bytes)
# - %T: Current tracker
# - %I: Info hash
#

shopt -s nullglob

startdir="$1"
logfile="/test.log"
if [ -z "$startdir" ]; then 
    echo "ERROR: Expected <startdir> as the 1st argument but none given, <startdir> should be the Torrent rootfolder (\"%R\") from qBittorrent"
    exit 1
fi


echo `date` "Download complete: $startdir" >> $logfile

if [ -d "$startdir" ]; then
    while IFS= read -r -d '' dir; do
        cd "${dir}"
        echo `date` "    ...checking $dir" >> $logfile
        flacfiles=`find "$dir" -type f -regextype posix-extended -regex '.*.(flac|ape|m4a|wv|wav)' -printf x | wc -c`
        if [ $flacfiles -eq "1" ]; then
            flacname=`find "${dir}" -type f -regextype posix-extended -regex '.*.(flac|ape|m4a|wv|wav)'`
            flacclean=${flacname%.*}
            if [ -f "$flacclean.cue" ] || [ -f "$flacname.cue" ]; then
                echo `date` "    ...extracting $flacname" >> $logfile
								/usr/local/bin/unflac -n "songs/{{- printf .Input.TrackNumberFmt .Track.Number}} - {{.Track.Title | Elem}}" 
                
            fi
        else
            echo `date` "    ...nothing to do" >> $logfile
        fi
    done < <(find "$startdir" -type d -print0)
else
    echo `date` "    ...not a directory, nothing to do" >> $logfile
fi
echo `date` "    Done!" >> $logfile
