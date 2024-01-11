#!/bin/bash
for i in `seq 31 50`
do
cp /kvm/win7_templete.qcow2 /kvm/win7_10.$i.qcow2
echo "$i copy"
done