docker build -t how-much-snow-update .
eval $(aws ecr get-login --no-include-email --region us-east-1)
docker tag how-much-snow-update:latest 221691463461.dkr.ecr.us-east-1.amazonaws.com/how-much-snow-update:latest
docker push 221691463461.dkr.ecr.us-east-1.amazonaws.com/how-much-snow-update:latest
