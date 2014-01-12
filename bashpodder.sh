#!/bin/bash

PODCAST_DIR=~/pod

extract_enclosure_urls () {
    xsltproc parse_rss_enclosure.xsl $1 2>/dev/null | head -n 1
}

extract_filename () {
    unquote $(basename $1) | tr " " "_"
}

download_files () {
    local title=$1
    mkdir -p $PODCAST_DIR/$title
    while read url; do
        download_file $PODCAST_DIR/$title $url
    done
}

download_file () {
    local dir=$1 url=$2
    local filename=$(extract_filename $url)
    local path=$dir/"$filename"
    if [ -f "$path" ]; then
        echo $path already downloaded
        return
    fi
    wget -c -O "$path.partial" $url && mv "$path.partial" "$path"
}

unquote () {
    python -c "import urllib, sys; print urllib.unquote(sys.argv[1])" $1
}

main () {
    while read title url; do
        extract_enclosure_urls $url | download_files $title
    done < <(grep -v ^# podcasts.conf)
}

main
