package kong.card.model;

public class Payment {

    private String id;
    private String balanceId;
    private String cardId;
    private String amount;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getBalanceId() {
        return balanceId;
    }

    public void setBalanceId(String balanceId) {
        this.balanceId = balanceId;
    }

    public String getCardId() {
        return cardId;
    }

    public void setCardId(String cardId) {
        this.cardId = cardId;
    }

    public String getAmount() {
        return amount;
    }

    public void setAmount(String amount) {
        this.amount = amount;
    }

}
