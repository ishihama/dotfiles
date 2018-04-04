#!/bin/bash
for i in $(find . ".*" -maxdepth 1); do
  ln -s $(cd $(dirname $i) && pwd)/$i ~/$i
done

