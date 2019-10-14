#!/bin/bash

students=`ls  -td ./solutions/*`

for i in $students;
do
	echo $i
	cp -r templates/* $i/
done
