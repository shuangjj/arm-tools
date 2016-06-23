#!/bin/bash

registry=$1
user=$2
shift
shift
repos=$@
for x in $repos
do
    docker push  $x
done
