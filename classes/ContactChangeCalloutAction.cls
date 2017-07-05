public class ContactChangeCalloutAction implements Queueable, Database.AllowsCallouts {
    
    Contact contact;
    UserProvisioningService ups = new UserProvisioningService();
    
    public ContactChangeCalloutAction(Contact contact) {
        this.contact = contact;
    }
    
    public void execute(QueueableContext context) {
    	if(Test.isRunningTest()==false){
        ups.changeContact(contact.Ag2Ag_Id__c,contact);
    	}
    }
}