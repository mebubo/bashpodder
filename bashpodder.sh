#!/bin/bash

PODCAST_DIR=~/media/podcasts
THIS_DIR=$(cd $(dirname $0); pwd)

extract_enclosure_urls () {
    local url=$1
    xsltproc $THIS_DIR/parse_rss_enclosure.xsl $url 2>/dev/null
}

limit () {
    local limit=$1
    case "$limit" in
        all)
            cat
            ;;
        "")
            head -n 2
            ;;
        *)
            head -n $limit
            ;;
    esac
}

extract_filename () {
    local normalized=$(unquote $(basename $1) | tr " " "_")
    echo ${normalized%%\?*}
}

download_files () {
    local title=$1
    mkdir -p $PODCAST_DIR/$title
    while read url; do
        if [ -n "$url" ]; then
            download_file $PODCAST_DIR/$title $url
        fi
    done
}

download_file () {
    local dir=$1 url=$2
    local filename=$(extract_filename $url)
    local path=$dir/"$filename"
    if [ -f "$path" -o -L "$path" ]; then
        echo $path already downloaded
        return
    fi
    echo "downloading $url to $path"
    wget -c -O "$path.partial" $url && mv "$path.partial" "$path"
}

unquote () {
    python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" $1
}

main () {
    while read title url limit; do
        extract_enclosure_urls $url | limit $limit | download_files $title
    done < <(grep -v ^# $THIS_DIR/podcasts.conf | tac)
}

main
