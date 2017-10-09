#!/usr/bin/env bash

set -ex

/usr/bin/supervisord --nodaemon -c /etc/supervisor/conf.d/supervisord.conf