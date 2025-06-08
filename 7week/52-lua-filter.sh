###############################################################################
# Test Headerer service
###############################################################################
k ns istioinacion
kaf lua-filter/httpbin.yaml
kaf lua-filter/headerer-service.yaml

# Check my awful headerer service
HOST="headerer"
keti debug -- curl $HOST/header -v
keti debug -- curl "$HOST/set/group?value=gold,silver,bronze&weight=10,25,65"
keti debug -- curl "$HOST/get/group"
keti debug -- curl $HOST/header -v | grep group

kaf lua-filter/lua-filter.yaml
###############################################################################
# Check
###############################################################################
keti debug -- curl http://httpbin.istioinaction:8000/headers | jq '.'
# check weights
for i in {1..100};
do
  keti debug -- curl http://httpbin.istioinaction:8000/headers | yq '.headers.Group'
  sleep 0.3
done | sort | uniq -c


keti debug -- curl "headerer/set/group?value=a,b&weight=10,90"
for i in {1..100};
do
  keti debug -- curl http://httpbin.istioinaction:8000/headers | yq '.headers.Group'
  sleep 0.3
done | sort | uniq -c

# Enter the debug pod for performance test
#keti debug -- zsh
#for i in {1..100};
#do
#  curl http://httpbin.istioinaction:8000/headers -s | jq '.headers.Group'
#done | sort | uniq -c



###############################################################################
# Clear
###############################################################################
kdelf lua-filter/httpbin.yaml
kdelf lua-filter/headerer-service.yaml
kdelf lua-filter/lua-filter.yaml

#kubectl apply -f ch14/httpbin.yaml -n istioinaction
#kubectl apply -f ch14/bucket-tester-service.yaml -n istioinaction
