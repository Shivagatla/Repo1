public class ScrambleContactEmailBatch implements Database.Batchable<Contact> {
    
    private List<Contact> listOfUserProvAccs = new List<Contact>();
    
    public ScrambleContactEmailBatch(List<Contact> listOfUserProvAccs) {
        this.listOfUserProvAccs = listOfUserProvAccs;
    }
    
    public Iterable<Contact> start(Database.BatchableContext BC) {
        return listOfUserProvAccs;
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        Database.update(scope, false);
    }
    
    public void finish(Database.BatchableContext BC) {}
}