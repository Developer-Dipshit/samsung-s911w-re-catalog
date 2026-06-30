#!/bin/sh
# Framework staging control — refresh, verify, extract, clean
# Requires rish (uid 2000). Run from Termux or PRoot.
set -eu

RISH="${RISH:-/data/data/com.termux/files/usr/bin/rish}"
STAGING="${STAGING:-/data/local/tmp/framework_staging}"
OUT="${OUT:-/data/data/com.termux/files/home/storage/downloads/framework-re}"

rish_cmd() { "$RISH" -c "$*"; }

usage() {
  echo "Usage: $0 {status|verify|refresh|extract-policies|clean|pull-jars}"
  exit 1
}

cmd_status() {
  echo "=== FRAMEWORK STAGING STATUS ==="
  rish_cmd "test -d $STAGING && du -sh $STAGING && find $STAGING -type f | wc -l || echo MISSING"
  rish_cmd "stat $STAGING 2>/dev/null | grep -E 'Uid|Access|Modify'"
  echo ""
  echo "Companion tools:"
  rish_cmd "ls -la /data/local/tmp/am.jar /data/local/tmp/main.jar 2>/dev/null || true"
}

cmd_verify() {
  echo "=== INTEGRITY CHECK (staging vs stock) ==="
  for j in knoxsdk services framework; do
    rish_cmd "md5sum /system/framework/${j}.jar $STAGING/system/framework/${j}.jar 2>/dev/null" || \
      echo "MISSING: $j"
  done
}

cmd_refresh() {
  echo "=== REFRESH STAGING FROM STOCK ==="
  rish_cmd "
    rm -rf $STAGING
    mkdir -p $STAGING/system/framework $STAGING/system/bin $STAGING/vendor/etc $STAGING/apex
    cp -a /system/framework $STAGING/system/
    cp -a /system/bin $STAGING/system/
    cp -a /vendor/etc $STAGING/vendor/ 2>/dev/null || true
    chmod -R 700 $STAGING
    chown -R shell:shell $STAGING
    echo DONE: \$(du -sh $STAGING)
  "
}

cmd_extract_policies() {
  echo "=== KNOX POLICY SURFACE ==="
  rish_cmd "
    unzip -p $STAGING/system/framework/knoxsdk.jar classes.dex 2>/dev/null | strings | \
      grep -oE 'Lcom/samsung/android/knox/[a-zA-Z0-9_/$.]+Policy[^;]*;' | \
      sed 's/^L//;s/;\$//;s/\\\$/./g' | sort -u
  "
}

cmd_clean() {
  echo "=== REMOVE STAGING ==="
  rish_cmd "rm -rf $STAGING && echo removed $STAGING"
}

cmd_pull_jars() {
  mkdir -p "$OUT" 2>/dev/null || true
  echo "=== PULL KEY JARS TO $OUT ==="
  for j in knoxsdk services framework knox_mtd ztsdk esecomm samsungkeystoreutils; do
    rish_cmd "cp $STAGING/system/framework/${j}.jar $OUT/ 2>/dev/null && echo pulled ${j}.jar" || true
  done
}

case "${1:-}" in
  status) cmd_status ;;
  verify) cmd_verify ;;
  refresh) cmd_refresh ;;
  extract-policies) cmd_extract_policies ;;
  clean) cmd_clean ;;
  pull-jars) cmd_pull_jars ;;
  *) usage ;;
esac