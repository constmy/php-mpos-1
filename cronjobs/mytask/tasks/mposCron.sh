#!/bin/bash

RunArg='mposcron#now#2m'

function mposcron()
{
  /var/www/php-mpos/cronjobs/run-crons.sh -v -f;
  return 0;
}

