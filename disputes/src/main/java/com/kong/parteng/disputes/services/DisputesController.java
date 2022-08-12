package com.kong.parteng.disputes.services;

import org.apache.catalina.connector.Response;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.kong.parteng.disputes.model.CreateDispute;
import com.kong.parteng.disputes.model.Dispute;
import com.kong.parteng.disputes.model.DisputeStatus;

@RestController
public class DisputesController {

    @Autowired
    MonolithService service; 

    @Autowired
    private Database db;

    @GetMapping("/disputes")
    public ResponseEntity getDisputes() {
        return ResponseEntity.ok(db.getDisputes());
    }

    @PostMapping("/disputes")
    public ResponseEntity createDispute(@RequestBody CreateDispute cd) {
        Dispute dispute = db.createDispute(cd);

        //update charge dispute status
        DisputeStatus status = new DisputeStatus(); 
        status.setDispute(true);

        String disputesStatusCall = service.disputesStatusCall(status, dispute); 
        if (dispute == null){
            ResponseEntity.status(Response.SC_BAD_REQUEST).body("Error creating dispute");
        }

        if ( disputesStatusCall.isEmpty()){
            System.out.println("what is in this?"+ disputesStatusCall);
            ResponseEntity.status(Response.SC_BAD_REQUEST).body("Error updating dispute status on charge");
        }
        
        return ResponseEntity.ok(dispute);
    }

}
