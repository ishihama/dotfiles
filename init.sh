#!/bin/bash
for i in $(find . -name ".*" -not -name ".git" -not -name "." -maxdepth 1); do
  ln -s $(cd $(dirname $i) && pwd)/$i ~/$i
done

