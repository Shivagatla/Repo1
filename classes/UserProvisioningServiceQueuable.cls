public with sharing class UserProvisioningServiceQueuable implements Queueable,Database.AllowsCallouts{
    
    
    private String action='';
    private User targetUser;
    private String value;
    
    
    
    public UserProvisioningServiceQueuable(String action, User targetUserIn, String value) {
        this.action = action;
        targetUser = targetUserIn;
        this.value =value;
        
    }
    
    public UserProvisioningServiceQueuable(String action, Id targetUserIn,String value) {
        
        targetUser =  [SELECT id,External_Fed_Id__c, email, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                       street, city, country, postalcode, username,state, localesidkey, mobilephone, extension, fax, contact.email,Ag2Ag_Id__C,jobclassification__c,IsActive,IsPortalEnabled,
                       Contact.Account.Name,Contact.Account.BillingState,Contact.Account.AIMS_Number__c
                       FROM User
                       WHERE id = :targetUserIn];
        this.action=action;
        this.value=value;
        
    }   
    
    
    public void execute(QueueableContext context){
        UserProvisioningService ups = new UserProvisioningService();
        if (action == EMSConstants.CHANGEPASSWORD_ACT){
            ups.changePassword(targetUser,value);
        }
        if (action== EMSConstants.UPDATECONTACT_ACT){
            Contact c = [select Id,Ag2Ag_Id__C,firstname,lastname,email,phone from Contact where Id=:targetUser.contact.Id LIMIT 1];
            ups.changeContact(targetUser.Ag2Ag_id__c,c); 
        }
        if (action == EMSConstants.CREATUSER_ACT){
            String ag2agID = ups.createUser(value, targetUser.firstName, targetUser.lastName, targetUser.email, targetUser.phone, targetUser.Contact.Account.Name, 'Winfield', targetUser.jobClassification__c,targetUser.Contact.Account.AIMS_Number__c,targetuser.Contact.Account.BillingState);
            targetUser.Ag2Ag_ID__C = ag2agID;
            update targetUser;          
        }
        if (action == EMSConstants.DISABLEUSER_ACT){
            ups.disableUser(targetUser);
        }
    }
}