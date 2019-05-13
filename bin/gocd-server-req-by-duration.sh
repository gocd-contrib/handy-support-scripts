#!/bin/bash

set -e

function die {
  echo $@ >&2
  exit 1
}

function usage {
  cat <<USAGE
Usage: $(basename "$0") [ OPTIONS ] infile outfile

Extracts web requests and sorts them slowest to fastest.

Options:

  --help          Show this message
  --csv           Output to CSV format for manipulation in a spreadsheet
                    or similar; appends a ".csv" file extension to <outfile>
                    if it does not have one
  --thresh=N      Only consider requests that took longer than N ms
USAGE
}

function sortReq {
  local fmt="log";
  local thresh="0";

  for arg in $@; do
    case "$arg" in
      --help)
        usage
        exit 0
        ;;
      --csv)
        fmt="csv"
        shift
        ;;
      --thresh=*)
        thresh=${1#"--thresh="}
        if [[ ! "$thresh" =~ ^[0-9]+$ ]]; then
          die "--thresh=N must be a positive integer. Try --help."
        fi
        shift
        ;;
      --thresh)
        shift
        thresh=$1
        if [[ ! "$thresh" =~ ^[0-9]+\$ ]]; then
          die "--thresh=N must be a positive integer. Try --help."
        fi
        shift
        ;;
      --*)
        die "Unknown option $1. Try --help."
        ;;
    esac
  done

  if [ $# -lt 2 ]; then
    usage
  fi

  local infile=$1
  local outfile=$2

  if [ "csv" = "$fmt" ]; then
    if [[ ! "$outfile" == *.csv ]]; then
      outfile="$outfile.csv"
    fi
    echo '"Duration","Timestamp","Status","Method","URL"' > "$outfile" && grep -F "RequestLog:" "$infile" | awk "$(awkmacro $fmt $thresh)" | sort -nr -k 2 -t '"' >> "$outfile"
  else
    grep -F "RequestLog:" "$infile" | awk "$(awkmacro $fmt $thresh)" | sort -nr -k 1 > "$outfile"
  fi
}

function awkmacro {
  local mode=$1
  local thresh=$2

  local preamble="gsub(/\"/,\"\",\$12)"

  if [ "csv" = "$mode" ]; then
    echo -n "\$NF > $thresh {$preamble;print \"\\\"\"\$NF\"\\\",\" \"\\\"\"\$1\"T\"\$2\"\\\",\" \"\\\"\"\$15\"\\\",\" \"\\\"\"\$12\"\\\",\" \"\\\"\"\$13\"\\\"\"}"
  else
    echo -n "\$NF > $thresh {$preamble;print \$NF,\$1\"T\"\$2,\$15,\$12,\$13}"
  fi
}

sortReq $@
