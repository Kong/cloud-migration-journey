# Build
mvn clean package && docker build -t com.kong.parteng/monolith .

# RUN

docker rm -f monolith || true && docker run -d -p 8080:8080 -p 4848:4848 --name monolith com.kong.parteng/monolith 

docker rm -f monolith || true && docker run -d -p 8080:8080 -p 9990:9990 --name monolith com.kong.parteng/monolith 

# Sample API Calls 
http://localhost:8080/monolith/resources/card/1

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

Post Payment : 
curl  http://localhost:8080/monolith/resources/card/payment \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"balanceId": "1","cardId" : "123456","amount" : "100"}'
# System Test

Switch to the "-st" module and perform:

mvn compile failsafe:integration-test

http://54.219.113.36:8080/monolith/resources/card/balance/1
http://54.219.113.36:8080/monolith/resources/card/charge/1

http://54.219.113.36:8080/monolith/resources/card/dispute


http://54.67.0.169:8080/disputes