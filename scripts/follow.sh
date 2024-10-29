export AWS_PROFILE=mmachenry
export AWS_REGION=us-east-1
aws logs tail --follow /aws/lambda/howMuchSnowGetInfo | python log_parse.py
