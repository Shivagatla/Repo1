public class EMSContactReviewCaseCreation {
    
    @InvocableMethod(label='Creates a New Customer Registration review Case' description='Creates a Case for review of New Customer Registration')
    public static void createCase(List<Contact> aList){
        for(Contact a: aList){
            createCase(a.Id);
        }    
    }    
    
    @future  public static void createCase(Id contactIdIn){
        List<User> usersL = [SELECT Id, FirstName, LastName,ContactId, Registration_Info__c, Name,corporate__c,purina__c,lol__c,seed__c,FGI__c FROM User WHERE  ContactId = :contactIdIn LIMIT 1];
        integer count = 0;
        Group reviewQueueQ;
        String reviewQueue = 'Default';
        
        User userC =null;
        String additionalComments ='';
        if(usersL == null || usersL.size() ==0){
            System.debug(LoggingLevel.ERROR, 'No user was associated with this contact:'+Contact.Id);
            additionalComments = ' No Salesforce User was found for this contact.  This needs to be remedied as well.\n';
            
        }
        else{
            userC = usersL[0];
            
            additionalComments = userC.Registration_Info__C+'\n';
            if (userC.corporate__c == true){
                reviewQueue='corp_registrations';count++;
            }
            
            if (userC.purina__c == true) {
                reviewQueue = 'Feed'; count++;
            }
            if (userC.seed__c == true) {
                reviewQueue = 'Winfield'; count++;
            }
            
            if (userC.lol__c == true) {
                reviewQueue = 'LoL_Maiden'; count++;
            }
            if (userC.FGI__c == true) {
                reviewQueue = 'FGI_Admin'; count++;
            }
        }
        if (count >1){
            reviewQueue='Default';
            additionalComments = additionalComments+ '\n*More than one business unit was selected.';
            System.debug('More than one business unit was found.');
        }
        if (count == 0){
            System.debug('no business unit was found');
            additionalComments = additionalComments+ '\n*No business unit was found.';
            reviewQueue='Default';
        }
        
        try {
            System.debug('Looking for queue: ' + reviewQueue);
            reviewQueueQ = 
                [select Id, Name 
                 from Group 
                 where Type = 'Queue' 
                 and DeveloperName=:reviewQueue
                 limit 1];
        } catch (Exception ex) {
            System.debug('***Could not find a queue "' + reviewQueue + '" of reviewers for new customer registrations');
        }
        Case c = new Case(
            
            Priority = 'Medium',
            Status = 'New',
            Subject = 'New Customer Registration: ' + 
            (userC!=null?userC.Name:'Unknown User') + ' (Queue: ' + reviewQueueQ.Name + ')',
            Description = 'New customer ' + (userC!=null?userC.Name:'Unknown User') + 
            ' has registered. Please review this request and close the case to activate the customer.\n'+additionalComments,
            Type='Review',
            ContactId = contactIdIn
        );
        // Try to insert our Case
        try {
            c.Related_External_User__c = UserC.Id;
            c.RecordTypeId = [select Id from RecordType where DeveloperName = 'RegistrationReview' and SobjectType = 'Case' LIMIT 1].Id;
            c.ownerId = reviewQueueQ.Id;
            insert c;
        } catch (DMLException ex) {
            // Handle the error
            System.debug(LoggingLevel.ERROR,'Unable to get record type.');
        }
        
        /*  c.ownerId = reviewQueueQ.Id;
Database.DmlOptions options = new Database.DmlOptions();
options.emailHeader.triggerUserEmail = true;
Database.update(c, options); */
    }
}