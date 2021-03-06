#!/bin/bash

. $(dirname $0)/../include.rc
. $(dirname $0)/../volume.rc

cleanup;

TEST glusterd
TEST pidof glusterd
TEST $CLI volume info;

TEST $CLI volume create $V0 replica 2 stripe 2 $H0:$B0/${V0}{1,2,3,4,5,6,7,8};

function limit_on()
{
        local QUOTA_PATH=$1;
        $CLI volume quota $V0 list | grep "$QUOTA_PATH" | awk '{print $2}'
}

EXPECT "$V0" volinfo_field $V0 'Volume Name';
EXPECT 'Created' volinfo_field $V0 'Status';
EXPECT '8' brick_count $V0

TEST $CLI volume start $V0;
EXPECT 'Started' volinfo_field $V0 'Status';

## ------------------------------
## Verify quota commands
## ------------------------------
TEST $CLI volume quota $V0 enable

TEST $CLI volume quota $V0 limit-usage /test_dir 100MB

TEST $CLI volume quota $V0 limit-usage /test_dir/in_test_dir 150MB

EXPECT "150MB" limit_on "/test_dir/in_test_dir";

TEST $CLI volume quota $V0 remove /test_dir/in_test_dir

EXPECT "100MB" limit_on "/test_dir";

TEST $CLI volume quota $V0 disable
## ------------------------------

TEST $CLI volume stop $V0;
EXPECT 'Stopped' volinfo_field $V0 'Status';

TEST $CLI volume delete $V0;
TEST ! $CLI volume info $V0;

cleanup;
