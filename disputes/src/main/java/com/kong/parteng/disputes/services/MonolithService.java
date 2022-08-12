package com.kong.parteng.disputes.services;

import org.apache.http.client.HttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.function.ServerRequest.Headers;

import com.kong.parteng.disputes.model.CreateDispute;
import com.kong.parteng.disputes.model.Dispute;
import com.kong.parteng.disputes.model.DisputeStatus;

@Component
public class MonolithService {

    @Value("${monolithRootUri}")
    private String rootUri;

    private final RestTemplate restTemplate;

    public MonolithService(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder.build();
        HttpClient httpClient = HttpClientBuilder.create().build();
        HttpComponentsClientHttpRequestFactory requestFactory = new HttpComponentsClientHttpRequestFactory(httpClient);
        restTemplate.setRequestFactory(requestFactory);
    }

    public String disputesStatusCall(DisputeStatus status, CreateDispute dispute) {
        HttpEntity<DisputeStatus> request = new HttpEntity<>(status);
        String response = this.restTemplate.patchForObject(
                "http://10.251.1.186:8080/monolith/resources/card/charge/{id}", request, String.class,
                dispute.getChargeId());

        return response;
    }

}
