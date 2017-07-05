public without sharing class EMS_DA_Request {
    
    public static String REQ_ACTION_APPROVE = 'Approve';
    public static String REQ_ACTION_DENY = 'Reject';
    
    public EMS_DA_Request() {
    }
    
    @RemoteAction
    public static UPRWrapper getUPRInfo(String uprId){
        
        UserProvisioningRequest upr = [SELECT Account_Address__c,Account__c,Ag2Ag_ID__c,Application__r.Name, Application__r.Description__c,AppName,ApprovalStatus,collected_Information__c,Comments__c,
                                       ConnectedAppId,CreatedById,CreatedDate,ExternalUserId,Id,LastModifiedById,LastModifiedDate,Name,Operation,Other_Details__c,
                                       Overall_Status__c,Requestor__c,SalesforceUserId,State,SalesforceUser.Name, Application__r.FG_Account_Field__c,
                                       Target_Email__c,Target_User_Name__c,User_Reason__c, SalesforceUser.External_Fed_Id__c
                                       from UserProvisioningRequest where id=:uprId];
        
        UPRWrapper uprW = new UPRWrapper(returnBlankOrVal(upr.SalesforceUser.Name, Constants.SPACE), 
                                         returnBlankOrVal(upr.Application__r.Name, Constants.SPACE), 
                                         returnBlankOrVal(upr.Application__r.Description__c,'N/A'),
                                         upr.Operation,
                                         returnBlankOrVal(upr.User_Reason__c, Constants.SPACE));
        Cart_Application__c[] cartApps = [Select  UPR_Number__c, Name, Catalog_App__c, 
                                          (SELECT Id, Ent_Code__c,Ent_Code__r.ParentApp__c,Ent_Code__r.Name,
                                           Ent_Code__r.Description__c,
                                           Account__r.Customer_Number__c,Account__r.Id,Account__r.AIMS_Number__c,Account__r.PAES_Number__c,Account__r.Name,
                                           Account__r.GUID__c,Account__r.BillingAddress, RecordType.DeveloperName 
                                           from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c =:upr.Id];
        
        if (cartApps != null && cartApps.size()>0){
            for (Cart_Application__c cartApp:cartApps){
                Cart_Entitlement__c[] cartEnts = cartApp.Cart_Entitlements__r;
                if (cartEnts != null && cartEnts.size()>0){
                    for (Cart_Entitlement__c ent:cartEnts){
                        if (ent.RecordType.DeveloperName == null || ent.RecordType.DeveloperName ==  EMSConstants.CART_CG_RT){
                            uprW.reqRoles.add(new EntWrapper(ent.Ent_code__r.Name,(String.ISBLANK(ent.Ent_code__r.description__c)?' ':ent.Ent_code__r.description__c)));                        
                        } else {
                            String desc2 = '';
                            String appGuid = getAppGUID(upr.Application__r.FG_Account_Field__c,ent.Account__r);
                            if (appGuid == ent.Account__r.GUID__c)
                                desc2 = '(Global ID:'+ent.Account__r.GUID__c +') ' + EMSUPRController.getAddressString(ent.Account__r.BillingAddress);
                            else 
                                desc2 = '(Global ID:'+ent.Account__r.GUID__c +', ' + appGuid +') ' +  EMSUPRController.getAddressString(ent.Account__r.BillingAddress);
                            uprW.reqAccounts.add(new EntWrapper(ent.Account__r.Name,desc2));
                        }
                    }
                }
            }
        }
        List<ProcessInstanceWorkitem> approvals = [select ProcessInstanceId, ProcessInstance.TargetObjectId, 
                                                   ProcessInstance.TargetObject.Name,
                                                   ProcessInstance.TargetObject.Type, ProcessInstance.CreatedBy.Name,
                                                   ProcessInstance.CreatedDate, ProcessInstance.CreatedBy.SmallPhotoUrl,ActorId 
                                                   from ProcessInstanceWorkitem where isDeleted=false and ActorId =:UserInfo.getUserId() and 
                                                   ProcessInstance.status='Pending' and ProcessInstance.TargetObjectId =:upr.Id ];
        System.debug('Approvals: ' + approvals);
        if (approvals != null && approvals.size()>0) uprW.isApprover = true;
        System.debug('User is approver: ' + uprW.isApprover);
        return uprW;
    }
    
 
    
    @RemoteAction
    public static String processRequest(String approverId, String uprId, String action, String comments){
        UserProvisioningRequest upr = [SELECT ConnectedAppId,DA_Approval_needed__c,
            DA_Bypass__c,Delegated_Admin_2__c,Delegated_Admin__c,Internal_Approval__c,Current_Step__c 
            FROM UserProvisioningRequest 
            WHERE Id=:uprId];
        if (upr.Delegated_Admin__c != UserInfo.getUserId() && upr.Delegated_Admin_2__c != UserInfo.getUserId()){
            System.debug('Current user: ' + UserInfo.getUserName() + ' is not an delegated approver: ' + upr.Delegated_Admin__c +' & '+upr.Delegated_Admin_2__c );
            return 'ERROR';
        }
        
        if (action=='Deny') action = EMS_DA_Request.REQ_ACTION_DENY;

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(comments);
        req.setAction(action);
        if (action == EMS_DA_Request.REQ_ACTION_APPROVE) {
            Id nextapproverId =  null;
            ApplicationHelper ah = new ApplicationHelper(upr.ConnectedAppId);
            Application__c targetApp = ah.getApplication();
            if (targetApp.ApproverType__c.equalsIgnoreCase('QUEUE')){
                Group reviewer = [select Id from Group where Type = 'Queue' and DeveloperName=:targetApp.Queue_Name__c limit 1];
                if (reviewer == null){
                    System.debug('There is a big error.  Queue is null. ');
                    return 'ERROR';
                } else {nextapproverId = reviewer.Id;}
            }
            else {nextapproverId = targetApp.Approver__c;}
            if (nextapproverId != null) req.setNextApproverIds(new Id[] {nextapproverId});
        }
        Id workItemId = EMS_DA_Request.getWorkItemId(upr.Id); 
        if(workItemId == null){
            System.debug('There has been an error procesing delegated admin approval. Action:' + action);
            return 'ERROR';
        }else{
            req.setWorkitemId(workItemId);
            // Submit the request for approval
            Approval.ProcessResult result =  Approval.process(req);
        }
        upr.Current_Step__c='INTERNAL';
        update upr;
        return 'SUCCESS';
    }
    
    public  static String getAppGUID(String fieldName, Account acct){
        if (fieldName.equalsIgnoreCase('GUID__C') && !String.isBlank(acct.GUID__c))
            return 'Global ID:'+ acct.GUID__c;
        else if (fieldName.equalsIgnoreCase('Customer_Number__c') && !String.isBlank(acct.Customer_Number__c))
            return 'Customer #:' +acct.Customer_Number__c; 
        else if (fieldName.equalsIgnoreCase('PAES_Number__c') && !String.isBlank(acct.PAES_Number__c))
            return 'PAES #:'+acct.PAES_Number__c; 
        else if (fieldName.equalsIgnoreCase('AIMS_Number__c') && !String.isBlank(acct.AIMS_Number__c))
            return 'AIMS #:'+acct.AIMS_Number__c;
        return fieldName + ' is null';
    }
    
   


    public static Id getWorkItemId(Id targetObjectId){
        Id retVal = null;
        for(ProcessInstanceWorkitem workItem  : [Select p.Id from ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId =: targetObjectId]){
            retVal  =  workItem.Id;
        }
        return retVal;
    }
    
    public EMS_DA_Request(EMS_DA_UserList controller) {
    }
    
    
    public class UPRWrapper{
        public String targetUser{get;set;}
        public String appName{get;set;}
        public String appDesc{get;set;}
        public String reqOperation{get;set;}
        public String userComments{get;set;}
        public List<EntWrapper> reqRoles{get;set;}
        public List<EntWrapper> reqAccounts{get;set;}
        public boolean isApprover{get;set;}
        public UPRWrapper(String targetUserIn, String appNameIn,String appDescIn, String reqOperationIn, String userCommentsIn){
            targetUser = targetUserIn;
            appName = appNamein;
            appDesc = appDescIn;
            userComments = userCommentsIn;
            reqOperation = reqOperationIn;
            reqRoles = new List<EntWrapper>();
            reqAccounts = new List<EntWrapper>();
            isApprover = false;
        }
    }
    public class EntWrapper{
        public String name{get;set;}
        public String description{get;set;}
        public EntWrapper(String name, String description){
            this.name = name;
            this.description=description;
        }
    }
    private static String returnBlankOrVal(String str, String returnForNull) {
        return (String.ISBLANK(str)?returnForNull:str);
    }
}