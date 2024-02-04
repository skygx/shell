#!/bin/bash
 
name="John"
age=25
city="New York"
 
data='{"name": "'"$name"'", 
       "age": '"$age"', 
	   "city": "'"$city"'"
	   }'
echo $data 

JSON="{\"ticket\": \"${TICKET}\", \"result\": 2001, \"data\": \"${VERSION}\"}"
echo $JSON