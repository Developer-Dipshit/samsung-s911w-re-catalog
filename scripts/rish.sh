#!/bin/sh
# RISH wrapper for dom0/proot — requires Shizuku server running
export RISH_APPLICATION_ID="${RISH_APPLICATION_ID:-com.termux}"
exec /data/data/com.termux/files/usr/bin/rish "$@"