#!/bin/bash
for i in $(find . -type f -name ".*" -maxdepth 1); do
  ln -s $(cd $(dirname $i) && pwd)/$i ~/$i
done

