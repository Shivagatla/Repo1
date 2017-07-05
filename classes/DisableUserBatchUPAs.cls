public class DisableUserBatchUPAs implements Database.Batchable<UserProvAccount>{
    
    private List<UserProvAccount> listOfUserProvAccs = new List<UserProvAccount>();
    
    public DisableUserBatchUPAs(List<UserProvAccount> listOfUserProvAccs) {
        this.listOfUserProvAccs = listOfUserProvAccs;
    }
    
    public Iterable<UserProvAccount> start(Database.BatchableContext BC) {
        return listOfUserProvAccs;
    }
    
    public void execute(Database.BatchableContext BC, List<UserProvAccount> scope) {
        Database.update(scope, false);
    }
    
    public void finish(Database.BatchableContext BC) {}
}