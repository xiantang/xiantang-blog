#! /bin/bash
echo "what your name?"
read name
if [ $name ]; then
	echo $name
else 
      	echo "failed"
fi
