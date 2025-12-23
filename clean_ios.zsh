#!/bin/zsh
cd "$(dirname "$0")"
xattr -cr .
flutter clean
rm -rf build
