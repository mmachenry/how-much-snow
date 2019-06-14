how-much-snow/back-end
===

This is the back-end for how-much-snow. It contains code for an AWS Lambda
function that acts as the implementation for the REST API to get weather 
predictions as well as a cron job script to pull prediction data from NOAA,
parse it, and put it into the database.

Installation of get_prediction Lambda
---

    virtualenv --python `which python3` venv
    source venv/bin/activate
    pip install sqlalchemy psycopg2-binary simplejson
    deactivate
    zip deploy.zip lambda_function.py config.py
    cd venv/lib/python3.6/site-packages/
    zip -ur ../../../../deploy.zip *
    # Copy the zip file up to the lambda function in AWS console

Installation of trigger_update Lambda
---

    zip deploy.zip trigger_update.py noaa_ftp.py filename_log.py
    # Copy the zip file up to the lambda function in AWS console

Installation of Docker backend
---

    docker build -t how-much-snow-update .
    eval $(aws ecr get-login --no-include-email --region us-east-1)
    docker tag how-much-snow-update:latest 221691463461.dkr.ecr.us-east-1.amazonaws.com/how-much-snow-update:latest
    docker push 221691463461.dkr.ecr.us-east-1.amazonaws.com/how-much-snow-update:latest


