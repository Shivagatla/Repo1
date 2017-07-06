trigger EMSCaseClosedTrigger on Case (after update) {

    for (Case so : Trigger.new) {
        //friends remind friends to bulkify
        if (Trigger.oldMap.get( so.Id ).Status != Trigger.newMap.get( so.Id ).Status){
        //if the status has changed...
            if (so.Status.equalsIgnoreCase('Reviewed and Accepted')){

                System.debug(LoggingLevel.DEBUG,'The case has been accepted.  Starting to do baseline access.');
                if (!Test.isRunningTest())
                    EMSEntitlementAssignment.assignEntitlements(so.Related_External_User__c+'',true);
            }
            else if (so.Status.startswith('Reviewed and Denied')){
               User u = [SELECT Id,Contact.Id from User where id=:so.Related_External_User__c LIMIT 1];
               /* Contact c = new Contact(id=u.Contact.Id);
                 c.Registration_Denied__c = true;
                 update c;*/
                ContactWebService.updateContact(u.Contact.Id);

            } else if (so.Status.equalsIgnoreCase('Approve')){

                System.debug(LoggingLevel.DEBUG,'The manual case has been finished. Starting to do baseline access.');
                UserProvisioningRequest upr = [SELECT Account_Address__c,Account__c,Ag2Ag_ID__c,Application__c,AppName,ApprovalStatus,BusinessLink_URL__c,Collected_Information__c,ConnectedAppId,CreatedById,CreatedDate,ExternalUserId,Id,IsDeleted,LastModifiedById,LastModifiedDate,ManagerId,Name,Needed_ManualProv__c,Needs_Email__c,Operation,Other_Details__c,OwnerId,Prov_Case__c,Responsible_Rule__c,SalesforceUserId,ScheduleDate,State,Support_Email__c,Support_Phone__c,SystemModstamp,Target_Email__c,Target_User_Name__c,UserProvAccountId,UserProvConfigId,User_Reason__c 
                FROM UserProvisioningRequest WHERE Id=:so.RelatedRequest__c LIMIT 1];
                ID jobID = System.enqueueJob(new StartFlowQueueable(upr));
            }
            else if (so.Status.equalsIgnoreCase('Deny')){
                UserProvisioningRequest upr = [SELECT Account_Address__c,Account__c,Ag2Ag_ID__c,Application__c,AppName,ApprovalStatus,BusinessLink_URL__c,Collected_Information__c,ConnectedAppId,CreatedById,CreatedDate,ExternalUserId,Id,IsDeleted,LastModifiedById,LastModifiedDate,ManagerId,Name,Needed_ManualProv__c,Needs_Email__c,Operation,Other_Details__c,OwnerId,Prov_Case__c,Responsible_Rule__c,SalesforceUserId,ScheduleDate,State,Support_Email__c,Support_Phone__c,SystemModstamp,Target_Email__c,Target_User_Name__c,UserProvAccountId,UserProvConfigId,User_Reason__c 
                FROM UserProvisioningRequest WHERE Id=:so.RelatedRequest__c LIMIT 1];
                upr.Overall_status__c='Rejected';
                update upr;
            }
        }


    }

}