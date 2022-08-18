# Docker

```console
docker build --build-arg JAR_FILE=target/*.jar -t parteng/disputes .

docker run -p 8081:8080 parteng/disputes
```

## APIs

GET all disputes: `http://localhost:8080/disputes`

**POST Dispute**
**JSON**

```console
{
    "cardId" : "123456", 
    "chargeId" : "abcde",
    "reason" : "duplicate transaction"
}
```

**API CAll**

```console
curl -X POST localhost:8081/disputes \
  -H  "Content-Type: application/json" \
  -d '{"cardId" : "123456","chargeId" : "abcde","reason" : "duplicate transaction"}'
```

Healthcheck: `http://localhost:8081/actuator/health`

Swagger: `http://localhost:8081/v3/api-docs/`
Swagger UI: `http://localhost:8081/swagger-ui/index.html`