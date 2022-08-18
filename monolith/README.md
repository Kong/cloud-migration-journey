# Build

```console
mvn clean package && docker build -t com.kong.parteng/monolith .
```

# RUN

```console
docker rm -f monolith || true && docker run -d -p 8080:8080 -p 4848:4848 --name monolith com.kong.parteng/monolith
```

# Sample API Calls

```console
swagger: http://localhost:8080/monolith/openapi

Get Balance: 
http://localhost:8080/monolith/resources/card/balance/1

Get Charges: 
http://localhost:8080/monolith/resources/card/balance/1/charges

Post DisputeStatus to Charge: 
curl http://localhost:8080/monolith/resources/card/charge/1 \
    -H "Content-Type: application/json" \
    -X PATCH \
    -d '{"dispute" : true}'

Post Payment: 
curl  http://localhost:8080/monolith/resources/card/payment \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"balanceId": "1","cardId" : "123456","amount" : "100"}'
```
