curl localhost:8080/header


curl "localhost:8080/set/a?value=a1,a2,a3&weight=30,60,10"
curl "localhost:8080/set/b?value=b1,b2,b3&weight=5,5,90"
curl "localhost:8080/set/c?value=c1,c2&weight=50,50"


curl "localhost:8080/get/a"

curl "localhost:8080/header"
