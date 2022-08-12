package kong.card.service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import javax.enterprise.context.ApplicationScoped;

import kong.card.model.Balance;
import kong.card.model.Card;
import kong.card.model.Charge;
import kong.card.model.DisputeStatus;
import kong.card.model.Payment;

@ApplicationScoped
public class Database {

    private Card card;
    private Balance balance;
    private List<Charge> charges;
    private List<Payment> payments;

    public Database() {

        card = new Card();
        card.setId("1");
        card.setAccountType("Credit");
        card.setCardNumber("123456");

        balance = new Balance();
        balance.setId("1");
        balance.setCardId(card.getCardNumber());
        balance.setMaxCredit(new BigDecimal(1000));
        balance.setAvailableCredit(new BigDecimal(1000));

        Charge charge1 = new Charge();
        charge1.setId("1");
        charge1.setBalanceId("1");
        charge1.setAmount(new BigDecimal(100));
        charge1.setDescription("Antlers Camping Equipment");
        charge1.setDispute(false);
        this.addCharge(charge1); 

        Charge charge2 = new Charge();
        charge2.setId("2");
        charge2.setBalanceId("1");
        charge2.setAmount(new BigDecimal(500));
        charge2.setDescription("EV Loan Payment");
        charge2.setDispute(false);
        this.addCharge(charge2); 

        payments = new ArrayList<>();
    }

    public Card getCardInfo() {
        return card;
    }

    public Balance getBalance() {
        return balance;
    }

    public Balance addCharge(Charge charge) {
        if (charges == null){
            charges = new ArrayList<>(); 
        }
        // update balance
        BigDecimal ac = balance.getAvailableCredit();
        balance.setAvailableCredit(ac.subtract(charge.getAmount()));

        // update list of charges
        charges.add(charge);

        return balance;
    }

    public List<Charge> getCharges() {
        return charges;
    }

    public List<Payment> getPayments() {
        return payments;
    }

    public List<Payment> postPayment(Payment payment) {

        payment.setId(String.valueOf(payments.size()+1));
        payments.add(payment);

        BigDecimal amount = BigDecimal.valueOf(Integer.valueOf(payment.getAmount())); 
        BigDecimal ac = balance.getAvailableCredit().add(amount); 
        
        if(ac.compareTo(balance.getMaxCredit()) == -1){
            balance.setAvailableCredit(ac);
        }else{
            balance.setAvailableCredit(balance.getMaxCredit());;
        }

        return payments;
    }

    public Charge updateDisputeStatus(String chargeId, DisputeStatus disputeStatus) {

        Charge charge = charges.stream()
                .filter(c -> c.getId().equalsIgnoreCase(chargeId))
                .peek(c -> c.setDispute(disputeStatus.getDispute()))
                .findFirst()
                .orElse(null);

        return charge;
    }

}
