package kong.card.model;

import java.math.BigDecimal;

public class Charge {

    private String id;
    private String balanceId;
    private BigDecimal amount;
    private String description;

    private Boolean dispute; 

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

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Boolean getDispute() {
        return dispute;
    }

    public void setDispute(Boolean dispute) {
        this.dispute = dispute;
    }

}
