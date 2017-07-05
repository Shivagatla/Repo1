public without sharing class EMSCreateCase {
  
   


    public static void createCase(Id contactIdIn, String subject, String rType, String description, String queueName,String relatedRequest){
        List<User> usersL = [SELECT Id, FirstName, LastName,ContactId, Registration_Info__c, Name,corporate__c,purina__c,lol__c,seed__c FROM User WHERE  ContactId = :contactIdIn LIMIT 1];
        integer count = 0;
         Group reviewQueueQ;
         String reviewQueue = 'CustomerService';
       
         User userC =null;
          String additionalComments ='';
       if(usersL == null || usersL.size() ==0){
        System.debug(LoggingLevel.ERROR, 'No user was associated with this contact:'+Contact.Id);
        additionalComments = ' No Salesforce User was found for this contact.  This needs to be remedied as well.\n';

       }
      else{
        userC = usersL[0];

        reviewQueue = queueName;
         

      }
     additionalComments += description;

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
                Subject = subject+ ': ' + 
                    (userC!=null?userC.Name:'Unknown User') + ' (Queue: ' + reviewQueueQ.Name + ')',
                Description = additionalComments,
                Type='Review',
                ContactId = contactIdIn
            );
            // Try to insert our Case
            try {
                c.Related_External_User__c = UserC.Id;
                c.RelatedRequest__c = relatedRequest;
                c.RecordTypeId = [select Id from RecordType where DeveloperName =  :rType and SobjectType = 'Case' LIMIT 1].Id;
              c.ownerId = reviewQueueQ.Id;
              insert c;
            } catch (DMLException ex) {
                // Handle the error
                System.debug(LoggingLevel.ERROR,'Unable to get record type.');
            }


        }
     }