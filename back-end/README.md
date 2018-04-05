how-much-snow/back-end
===

This is the back-end for how-much-snow. It contains code for an AWS Lambda
function that acts as the implementation for the REST API to get weather 
predictions as well as a cron job script to pull prediction data from NOAA,
parse it, and put it into the database.

Installation
---

    virtualenv env
    env/bin/activate
    pip install sqlalchemy psycopg2
    deactivate
    zip deploy.zip lambda_function.py config.py
    cd env/lib/python2.7/site-packages/
    zip -ur ../../../../deploy.zip *
    # Copy the zip file up to the lambda function in AWS console
