package kong.card.service;

import java.util.List;

import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.PATCH;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;


import kong.card.model.Balance;
import kong.card.model.Card;
import kong.card.model.Charge;
import kong.card.model.DisputeStatus;
import kong.card.model.Payment;

@Path("card")
public class CardResource {

    @Inject
    Database db; 

    @GET
    @Path("{id}")
    @Consumes("application/json")
    @Produces("application/json")
    public Card getCardInfo() {
        return db.getCardInfo(); 
    }

    @GET
    @Path("/balance/{id}")
    @Consumes("application/json")
    @Produces("application/json")
    public Balance getBalance(){
        return db.getBalance(); 
    }

    @GET
    @Path("/balance/{id}/charges")
    @Consumes("application/json")
    @Produces("application/json")
    public List<Charge> getCharges(){
        return db.getCharges(); 
    }

    @PATCH
    @Path("/charge/{chargeId}")
    @Consumes("application/json")
    @Produces("application/json")
    public Response disputeChargeStatus(DisputeStatus disputeStatus, @PathParam("chargeId") String chargeId){
        Charge charge = db.updateDisputeStatus(chargeId, disputeStatus); 

        if (charge == null){
            return Response.status(Response.Status.BAD_REQUEST).entity("failure to update charge dispute status").build(); 
        }
        return Response.status(Response.Status.ACCEPTED).entity("dispute status updated").build(); 
    }

    @POST 
    @Path("/payment")
    @Consumes("application/json")
    @Produces("application/json")
    public Response postPayment(Payment payment){
        List<Payment> paymentResponse = db.postPayment(payment); 
        if (paymentResponse == null) {
            return Response.status(Response.Status.BAD_REQUEST).entity("failure to accept payment").build(); 
        }

        return Response.status(Response.Status.ACCEPTED).entity("payment accepted").build(); 
    }

    @GET
    @Path("/payment")
    @Consumes("application/json")
    @Produces("application/json")
    public List<Payment> getPayments(){
        return db.getPayments(); 
    }

    //these 2 apis will be broken out into the microservice
    @GET 
    @Path("/dispute")
    @Consumes("application/json")
    @Produces("application/json")
    public String getDisputes(){
        return "Please Dial in to see disputes on file";
    }

    @POST
    @Path("/dispute")
    @Consumes("application/json")
    @Produces("application/json")
    public String createDispute() {
        return "Please Call in to talk to an Associate";
    }

}
