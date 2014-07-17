#!/bin/bash
#
# requires:
#  bash
#  sed, tac
#

sed 's,-A ,-D ,; s,-N ,-X ,' /dev/stdin | tac
