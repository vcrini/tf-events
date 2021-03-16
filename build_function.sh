#!/usr/bin/env bash
FUNCTION=function.zip
rm $FUNCTION
cd deploy_function/package/
zip -r9 ../../$FUNCTION .
cd ..
zip -g ../$FUNCTION lambda_function.py
