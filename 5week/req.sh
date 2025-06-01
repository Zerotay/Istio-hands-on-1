SIMPLEWEB="webapp.istioinaction.io"
curl -s http://$SIMPLEWEB:30000/api/catalog --resolve "$SIMPLEWEB:30000:127.0.0.1"
while true; do curl -s http://$SIMPLEWEB:30000/api/catalog --resolve "$SIMPLEWEB:30000:127.0.0.1" ; date "+%Y-%m-%d %H:%M:%S" ; sleep 1; echo; done

