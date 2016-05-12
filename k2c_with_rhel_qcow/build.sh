docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 
