$collectionPath = "D:\Jala\Jala University\DevOps\P1"
docker run -v ${collectionPath}:/etc/newman -t postman/newman:latest run "DevOps.postman_collection.json" --reporters="cli"