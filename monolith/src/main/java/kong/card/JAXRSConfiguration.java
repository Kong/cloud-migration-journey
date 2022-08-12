package kong.card;

import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

import io.swagger.v3.jaxrs2.integration.resources.AcceptHeaderOpenApiResource;
import io.swagger.v3.jaxrs2.integration.resources.OpenApiResource;
import kong.card.service.CardResource;

@ApplicationPath("resources")
public class JAXRSConfiguration extends Application {
    @Override
    public Set<Class<?>> getClasses() {

        return Stream.of(CardResource.class,OpenApiResource.class, AcceptHeaderOpenApiResource.class).collect(Collectors.toSet());

    }
}
