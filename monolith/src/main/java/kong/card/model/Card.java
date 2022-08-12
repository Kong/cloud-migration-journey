package kong.card.model;


public class Card {

    private String id;
    private String cardNumber;
    private String accountType;

    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }
    public String getCardNumber() {
        return cardNumber;
    }
    public void setCardNumber(String cardNumber) {
        this.cardNumber = cardNumber;
    }
    public String getAccountType() {
        return accountType;
    }
    public void setAccountType(String accountType) {
        this.accountType = accountType;
    }

}
