docker build -t how-much-snow-update .
docker run -e AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key --profile default)" -e AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id --profile default)" -e AWS_DEFAULT_REGION=us-east-1 how-much-snow-update
