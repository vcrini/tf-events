#!/usr/bin/env bash
FUNCTION=function.zip
FUNCTION2=error_parser.zip
cd deploy_function/package/
zip -r9 ../../$FUNCTION .
cd ..
zip -g ../$FUNCTION lambda_function.py
cd ..
cd error_parser_function/
zip -g ../$FUNCTION2 lambda_function.py
