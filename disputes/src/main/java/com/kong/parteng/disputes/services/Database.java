package com.kong.parteng.disputes.services;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.context.annotation.ApplicationScope;

import com.kong.parteng.disputes.model.CreateDispute;
import com.kong.parteng.disputes.model.Dispute;
import com.kong.parteng.disputes.model.DisputeStatus;

@ApplicationScope
@Component
public class Database {

    List<Dispute> disputes;

    public Database() {

        disputes = new ArrayList<>();
        CreateDispute cd = new CreateDispute();
        cd.setCardId("1234");
        cd.setChargeId("45678");
        cd.setReason("Duplicate Charge");

        createDispute(cd);

    }

    public List<Dispute> getDisputes() {
        return disputes;
    }

    public Dispute createDispute(CreateDispute cd) {

        Dispute dispute = new Dispute();
        dispute.setCardId(cd.getCardId());
        dispute.setChargeId(cd.getChargeId());
        dispute.setReason(cd.getReason());
        dispute.setStatus("in progress");

        disputes.add(dispute);
        int s = disputes.size() - 1;
        dispute.setId(String.valueOf(s));

        return dispute;
    }

}
