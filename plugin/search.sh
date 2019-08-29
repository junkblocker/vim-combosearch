#!/usr/bin/env bash

# Arguments
SEARCH_QUERY="$(tr -d "\"\`\'^$" <<<$1)"
IGNORE_OPTIONS=$2

# Change to 1 to debug search results. It will append, for example,
# `search_by_path::` onto lines generated by the search_by_path() function.
TAG_BY_SEARCH_TYPE=0

if [ -x "$(command -v fdfind)" ]; then
	fd() {
		fdfind "$@"
	}
fi

_tag_search_type() {
	if [ $TAG_BY_SEARCH_TYPE -ne 0 ]; then
		sed "s/^/$1::/g"
	else
		tee
	fi
}

search_by_path() {
	fd  \
		--full-path \
		--ignore-case \
		--ignore-file=<(printf "$IGNORE_OPTIONS") \
		--type=f \
		"$SEARCH_QUERY"  2> /dev/null | \
	sed "s/$/:0:0/g" | \
	_tag_search_type "search_by_path"
}

search_all_lines_except_matches() {
	if [ "$(fd $SEARCH_QUERY)" ]; then
		rg \
			--color=always \
			--column \
			--hidden \
			--ignore-case \
			--invert-match \
			--line-number \
			--max-columns=500 \
			--no-heading \
			--no-messages \
			--with-filename \
			"$SEARCH_QUERY" $(fd "$SEARCH_QUERY") 2> /dev/null | \
		rg ":.*:.*:.*\w.*$" | \
		_tag_search_type "search_all_lines_except_matches"
	fi
}

search_matches() {
	rg \
		--color=always \
		--column \
		--hidden \
		--ignore-case \
		--ignore-file=<(printf "$IGNORE_OPTIONS") \
		--line-number \
		--max-columns=500 \
		--no-heading \
		--no-messages \
		--with-filename \
		"$SEARCH_QUERY" 2> /dev/null | \
	_tag_search_type "search_matches"
}

# Finally, call the three search methods
search_by_path & search_matches & search_all_lines_except_matches
