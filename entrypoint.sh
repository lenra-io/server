#!/bin/sh

/app/bin/lenra eval "Lenra.MigrationHelper.migrate"
/app/bin/lenra $@
