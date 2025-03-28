#!/bin/bash

eval touch {1..99999}.txt
for i in {1..10}
do
  eval touch {${i}00000..${i}99999}.txt

done
