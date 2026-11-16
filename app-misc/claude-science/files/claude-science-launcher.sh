#!/bin/sh
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# Application-menu launcher for Claude Science: opens a new browser tab on the
# running daemon, or starts the daemon in the background (which opens the UI in
# the browser) when none is running. Self-updates stay off because Portage
# manages the installed binary.

claude-science open && exit 0
exec claude-science serve --detached --no-auto-update
