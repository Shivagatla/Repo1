public without sharing class EMSUPRController {

   
    
    public UserProvisioningRequest upr{get;set;}
    public List<EntWrapper> requestedFEnts{get;set;}
    public String addtnComments{get;set;}
    public Cart_Application__c parentApp {get;set;}
    public boolean isFineGrain{get;set;}
    public String uprId{get;set;}
    public List<EntWrapper> allEntitlements { get; set; }
   
    public List<EntWrapper> allAccts { get; set; }
    public boolean hasCGEnts{get;set;}
    public boolean hasFGEnts{get;set;}
    public boolean isApproved{get;set;}
    public Case provCase {get;set;}
    public boolean isCompleted {get;set;}
    public String message{get;set;}
    public boolean canApprove{get;set;}
    public Id currentUser{get;set;}

    private final UserProvisioningRequest upr2;

    public boolean canChangeState{get;set;}
    public String instructions{get;set;}


    public List<Account> selectedAccts{get;set;}

    transient public ApprovalList aSW {get; private set;}

    private Id retURLRecordId;

    
    public Contact newContact{get;set;}
    
    
    public Id entToRemove{get;set;}
    public Id entToAdd{get;set;}
    ApplicationHelper ah;
    List<Entitlements__c> availableEnts;
    List<Account> availAccounts;
    public String approvalComments{get;set;}
       public boolean isDelegated{get;set;}
        public boolean canBeOverridden {get;set;}

   
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public EMSUPRController() {
        
        uprId = System.currentPageReference().getParameters().get('uprId');
        this.upr = [SELECT Account_Address__c,Account__c,Ag2Ag_ID__c,Application__c,AppName,ApprovalStatus,BusinessLink_URL__c,Collected_Information__c,Comments__c,
          ConnectedAppId,CreatedById,CreatedDate,ExternalUserId,Id,LastModifiedById,LastModifiedDate,Name,Needed_ManualProv__c,Needs_Email__c,Operation,Other_Details__c,
          Overall_Status__c,OwnerId,Parent_Account_Info__c,Prov_Case__c,Requestor__c,Responsible_Rule__c,SalesforceUserId,State,Support_Email__c,Support_Phone__c,
          Target_Email__c,Target_User_Name__c,UserProvAccountId,UserProvConfigId,User_Reason__c, Owner.Name,SalesforceUser.Name, Application__r.Name,
          UserProvAccount.Name,Responsible_Rule__r.Name,SalesforceUser.External_Fed_Id__c,
            DA_Approval_needed__c,DA_Bypass__c,Delegated_Admin_2__c,Delegated_Admin__c,Internal_Approval__c
          from UserProvisioningRequest where id=:uprId];
        System.debug('Approval Status:'+ this.upr.ApprovalStatus);
         if (this.upr.ApprovalStatus.equalsIgnoreCase('Approved') || this.upr.ApprovalStatus.equalsIgnoreCase('NotRequired')) isApproved = true;
         else isApproved = false;

        Id connectedAppId = upr.ConnectedAppId;
        ah = new ApplicationHelper(connectedAppId);
        isFineGrain = ah.hasFineGrainEnts();
        requestedFEnts = new List<EntWrapper>();
        availableEnts = new List<Entitlements__c>();
        allEntitlements = new List<EntWrapper>();
        availAccounts = new List<Account>();
        isDelegated = false;
        canBeOverridden = false;
        currentUser = UserInfo.getUserId();
       
        allAccts = new List<EntWrapper>();
        newContact = new Contact();
        availableEnts = [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name,Description__c FROM Entitlements__c where ParentApp__c=:ah.getApplication().Id];
        
       
        availAccounts = ah.getFineGrainAccounts(upr.SalesforceUserId);
  
        requeryEnts();
        hasCGEnts = allEntitlements.size()>0;
        hasFGEnts = allAccts.size()>0;

         Set<Id> memberOfQueueIds = new Set<Id>();
        memberOfQueueIds.add(UserInfo.getUserId());
        Map<Id,String> queues = new Map<Id,String>();
        for (GroupMember m : [  select GroupId,Group.Name,UserOrGroupId from GroupMember where 
                                UserOrGroupId= :UserInfo.getUserId() 
                                and Group.Type = 'Queue']){
            memberOfQueueIds.add(m.GroupId);   
            queues.put(m.GroupId,m.Group.Name);                 
        }

     
        instructions = String.IsBlank(ah.getApplication().FG_Admin_Instructions__c)?'':ah.getApplication().FG_Admin_Instructions__c;
         if (this.upr.Overall_Status__c != null && this.upr.Overall_Status__c.equalsIgnoreCase('Completed')) isCompleted = true;
         else isCompleted = false;

         if (this.upr.ApprovalStatus.equalsIgnoreCase('Approved') || this.upr.ApprovalStatus.equalsIgnoreCase('NotRequired')) isApproved = true;
         else isApproved = false;

         if (upr.Prov_Case__c != null && !isCompleted) canChangeState = true;
         else canChangeState = false;

         if (isApproved && upr.Prov_Case__c != null){
             try{
                provCase = [SELECT AccountId,AssetId,Description,Id,IsClosed,Reason,RecordType.DeveloperName,RelatedRequest__c,Related_Cart__c,Related_External_User__c,Status,Subject 
                FROM Case 
                WHERE Id = :upr.Prov_case__c LIMIT 1];
             }
             Catch(Exception e){
                canChangeState = false;
             }
        } else canChangeState = false;
        if (provCase == null) canChangeState = false;
        message = '';
      
           
         aSW = generateData();
          
    }
    

    public ApprovalList generateData(){
        ApprovalList approvalResultForObject = new ApprovalList();
        List<ApprovalStepWrapper> aSW = new List<ApprovalStepWrapper>();
        String recallApprovalProcessLink;
        Boolean isSubmitForApproval = true;
        for(ProcessInstance pI:getProcessHistory(upr.Id).values()){
            Map<Id,List<ProcessInstanceHistory>> mapOfProcessNodeIdAndProcessInstanceHistory = new Map<Id,List<ProcessInstanceHistory>>();
            Set<Id> processNodeId= new Set<Id>(); 
            
            for(ProcessInstanceHistory sWI:pI.StepsAndWorkitems){
                if(processNodeId.size() ==0)
                    processNodeId.add(sWI.ProcessNodeId);
                else if(processNodeId.size()>0 && processNodeId.contains(sWI.ProcessNodeId)!= NULL)
                    processNodeId.add(sWI.ProcessNodeId);
            }
            
            for(Id pNId: processNodeId){
                ApprovalStepWrapper aSWr = new ApprovalStepWrapper();
                for(ProcessInstanceHistory sWI:pI.StepsAndWorkitems){
                    if(sWI.processNodeId == pNID){
                        aSWr.listOfSteps.add(sWI);
                        if( isMemberOf(currentUser,sWI.ActorId)) aSWr.canApproveStep = true;

                    }
                    if(sWI.StepStatus == 'Pending'){

                        System.debug('***Actor id: ' + sWI.ActorId +' and upr:' + upr.Delegated_admin__c + ' and can bypass delegate:' + ah.canBypassDelegate());

                        if (upr.Delegated_Admin__c == sWI.ActorId || upr.Delegated_Admin_2__c == sWI.ActorId)
                            isDelegated = true;
                        if (isDelegated && ah.canBypassDelegate())
                            canBeOverridden = true;
                        isSubmitForApproval = false;
                    }
                    
                }
                aSW.add(aSWr);
            }
        }
        approvalResultForObject.approvals = aSW;
        approvalResultForObject.recordId = upr.Id;
        approvalResultForObject.isSubmitForApproval = isSubmitForApproval;
        approvalResultForObject.recallApprovalProcessLink = recallApprovalProcessLink;
        return approvalResultForObject;
    }
    private Map<Id,ProcessInstance> getProcessHistory(Id objectId){
       return new Map<Id,ProcessInstance>([SELECT Id, (SELECT ID, ProcessNodeId,
            StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending,
            OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,
            OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by CreatedDate DESC ) 
            FROM ProcessInstance where TargetObjectId =:objectId order by CreatedDate DESC]);
    }

    public class ApprovalStepWrapper{

        public List<ProcessInstanceHistory> listOfSteps {get;set;}
        public boolean canApproveStep{get;set;}
     
        
        public ApprovalStepWrapper(){
            listOfSteps = new  List<ProcessInstanceHistory>();
            canApproveStep=false;
           

        }
    }
    public class ApprovalList{
        public List<ApprovalStepWrapper> approvals {get;set;}
        public String recallApprovalProcessLink {get;set;}
        public Boolean isSubmitForApproval {get;set;}
        public Id recordId {get;set;}
        public ApprovalList(){
            approvals = new List<ApprovalStepWrapper>();
            isSubmitForApproval = true;
        }
    }
    
    public void removeEnt(){
        Cart_Entitlement__c cEnt = new Cart_Entitlement__c(id=entToRemove);
        delete cEnt;
        entToRemove = null;
        requeryEnts();
        
    }
    
     public void addEntitlement(){
        
        if (numberOfFGEntsInList() < ah.getMaxEnts()){
         Account acct = [SELECT GUID__c,Name, PAES_Number__c, Customer_Number__c,AIMS_Number__c, BillingAddress From Account where id=:entToAdd limit 1];
            Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
                    cEnt.Account__c = acct.Id;
                    cEnt.Parent_App__c = [SELECT id from Cart_Application__c where UPR_Number__c=:upr.Id LIMIT 1].Id;
                    cEnt.RelatedUPR__c = upr.Id;
                    cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_FG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
                    insert cEnt;
        entToAdd = null;
        String desc2 = '';
            String appGuid = getAppGUID(acct);
            if (appGuid == acct.GUID__c)
                desc2 = '(Global ID:'+acct.GUID__c +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
            else 
                desc2 = '(Global ID:'+acct.GUID__c +', ' + appGuid +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
            
            EntWrapper entw = new EntWrapper(acct.Id,acct.Id,acct.Name,desc2,EMSConstants.CART_FG_LABEL);
            entw.selected = true;
            requestedFEnts.add(entw);
            if (containsEntWrapper(allAccts,entw) && indexOf(allAccts,entw)>-1){
               
                allAccts.remove(indexOf(allAccts,entW));
            }
       
        requeryEnts();
        }
        else {
            message = 'This application is only allowed ' + ah.getMaxEnts() + ' account(s) to be assigned to the user.  Please unselect some accounts to add others.';

        }
     
    }
    
    private integer numberOfFGEntsInList(){
        integer count = 0;
        for(EntWrapper entw : requestedFEnts){
            if (entw.entType == EMSConstants.CART_FG_LABEL) count++;
        }
        return count;
    }

    public void addAccount(){
        if (requestedFEnts.size() < ah.getMaxEnts()){
            if (newContact.AccountId!=null){
                System.debug('Contact info:' + newContact.AccountId);
      
                Account acct = [SELECT GUID__c,Name, PAES_Number__c, Customer_Number__c,AIMS_Number__c, BillingAddress From Account where id=:newContact.AccountId limit 1];
                Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
                        cEnt.Account__c = acct.Id;
                        cEnt.Parent_App__c = [SELECT id from Cart_Application__c where UPR_Number__c=:upr.Id LIMIT 1].Id;
                        cEnt.RelatedUPR__c = upr.Id;
                        cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_FG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
                        insert cEnt;
                String desc2 = '';
                String appGuid = getAppGUID(acct);
                if (appGuid == acct.GUID__c)
                    desc2 = '(Global ID:'+acct.GUID__c +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
                else 
                    desc2 = '(Global ID:'+acct.GUID__c +', ' + appGuid +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
                
                EntWrapper entw = new EntWrapper(acct.Id,acct.Id,acct.Name,desc2,EMSConstants.CART_FG_LABEL);
                entw.selected = true;
                requestedFEnts.add(entw);

                if (containsEntWrapper(allAccts,entw) && indexOf(allAccts,entw)>-1){
                   
                    allAccts.remove(indexOf(allAccts,entW));
                }
              
                
            }
            else System.debug('something when wrong in adding the account -- it was null');
            
           
           newContact.Account = null;
            requeryEnts();
        }
        else {
            message = 'This application is only allowed ' + ah.getMaxEnts() + ' account(s) to be assigned to the user.  Please unselect some accounts to add others.';

        }
      
    }

      public void addRole(){
        
         Entitlements__c ent = [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name,Description__c FROM Entitlements__c where id=:entToAdd limit 1];
            Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
                    cEnt.Ent_Code__c = ent.Id;
                    cEnt.Parent_App__c = [SELECT id from Cart_Application__c where UPR_Number__c=:upr.Id LIMIT 1].Id;
                    cEnt.RelatedUPR__c = upr.Id;
                    cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_CG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
                    insert cEnt;
        entToAdd = null;
      EntWrapper entw = new EntWrapper(ent.id,ent.id,ent.Name,ent.Description__c,EMSConstants.CART_CG_LABEL);
            entw.selected = true;
            requestedFEnts.add(entw);
            if (containsEntWrapper(allEntitlements,entw) && indexOf(allEntitlements,entw)>-1){
               
                allEntitlements.remove(indexOf(allEntitlements,entw));
            }
          
        //requeryEnts();
     
    }

    public integer indexOf(List<EntWrapper>listtoCheck,EntWrapper entw){
        integer count = 0;
        for (EntWrapper ew:listtoCheck){
            if (ew.objId == entw.objId) return count;
            count++;
        }
        return -1;
    }


    public boolean containsEntWrapper(List<EntWrapper> tocheck, EntWrapper objToCheck){

        boolean found = false;

        for (EntWrapper ew:tocheck){
            if (ew.objId == objToCheck.objId) return true;
        }
        return found;

    }
    
    private void requeryEnts(){
       
        message = '';
        requestedFEnts = new List<EntWrapper>();
        allEntitlements = new List<EntWrapper>();
        allAccts = new List<EntWrapper>();
        Set<Id> selectedIds = new Set<Id>();
        Cart_Application__c[] cartApps = [Select  UPR_Number__c, Name, Catalog_App__c, (SELECT Id, Ent_Code__c,Ent_Code__r.ParentApp__c,Ent_Code__r.Name,
        Ent_Code__r.Description__c,
        Account__r.Customer_Number__c,Account__r.Id,Account__r.AIMS_Number__c,Account__r.PAES_Number__c,Account__r.Name,
        Account__r.GUID__c,Account__r.BillingAddress, RecordType.DeveloperName from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c =:upr.Id];
        if (cartApps != null && cartApps.size()>0){
            
            for (Cart_Application__c cartApp:cartApps){
                parentApp=cartApp;
                
                Cart_Entitlement__c[] cartEnts = cartApp.Cart_Entitlements__r;
                if (cartEnts != null && cartEnts.size()>0){
                    for (Cart_Entitlement__c ent:cartEnts){
                        System.debug('Cart Ent: ' + ent);
                        if (ent.RecordType.DeveloperName == null || ent.RecordType.DeveloperName ==  EMSConstants.CART_CG_RT){
                            EntWrapper entw = new EntWrapper(ent.id,ent.Ent_Code__c,ent.Ent_code__r.Name,(String.ISBLANK(ent.Ent_code__r.description__c)?' ':ent.Ent_code__r.description__c),EMSConstants.CART_CG_LABEL);
                         
                            requestedFEnts.add(entw);
                          
                            selectedIds.add(entw.objId);
                            
                            
                        }
                        else {
                            
                            String desc2 = '';
                            String appGuid = getAppGUID(ent.Account__r);
                            if (appGuid == ent.Account__r.GUID__c)
                                desc2 = '(Global ID:'+ent.Account__r.GUID__c +') ' + (ent.Account__r.BillingAddress == null ? '' : ', '+getAddressString(ent.Account__r.BillingAddress));
                            else 
                                desc2 = '(Global ID:'+ent.Account__r.GUID__c +', ' + appGuid +') ' + (ent.Account__r.BillingAddress == null ? '' : ', '+getAddressString(ent.Account__r.BillingAddress));
                            
                            EntWrapper entw = new EntWrapper(ent.id,ent.Account__c,ent.Account__r.Name,desc2,EMSConstants.CART_FG_LABEL);
                         
                            requestedFEnts.add(entw);
                            selectedIds.add(entw.objId);
                           
                           
                        }

                    }
                }
            }
        }
         //add selected ents to select options
        if (availableEnts != null){
            for(Entitlements__c ent:availableEnts){
                EntWrapper entw = new EntWrapper(ent.id,ent.id,ent.Name,(String.ISBlank(ent.Description__c)?' ':ent.Description__c),EMSConstants.CART_CG_LABEL);
                
                //if an available ent has been selected, don't include in the available ents
                System.debug('Comparing id: ' + entw.objid);
                if (!selectedIds.contains(ent.Id)){
                   
                    allEntitlements.add(entw);
                }
            }
        }
       
        if (availAccounts != null){
            for(Account acct : availAccounts){
              
                
               
                if (!selectedIds.contains(acct.Id)){
                    String desc2 = '';
                    String appGuid = getAppGUID(acct);
                    if (appGuid == acct.GUID__c)
                        desc2 = '(Global ID:'+acct.GUID__c +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
                    else 
                        desc2 = '(Global ID:'+acct.GUID__c +', ' + appGuid +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
                 
                    allAccts.add(new EntWrapper(acct.id,acct.id,acct.Name,desc2,EMSConstants.CART_FG_LABEL));
                }
            }
        }
        hasCGEnts = allEntitlements.size()>0;
        hasFGEnts = allAccts.size()>0;
    }
    
    
    
    public static String getAddressString(Address addy){
        if (addy==null) return null;
        String assignedTo = (String.isNotBlank(addy.getStreet()) ? addy.getStreet()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getCity()) ? addy.getCity()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getState()) ? addy.getState()+ Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getPostalCode()) ? String.valueOf(addy.getPostalCode())+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) +
            (String.isNotBlank(addy.getCountry()) ? addy.getCountry() : Constants.EMPTY);
        assignedTo = assignedTo.trim().removeEnd(',');
        return assignedTo;
    }
    
    public  String getAppGUID(Account acct){
        String fieldName = ah.getAcctFieldName();
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

    public class EntWrapper{
        public String name{get;set;}
        public String description{get;set;}
        public String entType{get;set;}
        public Id id{get;set;}
        public Id objid{get;set;}
        public boolean selected{get;set;}
        public EntWrapper(Id id,Id objId,String name, String description,String entType){
            this.name = name;
            this.id = id;
            this.objId = objId;
            this.description=description;
            this.entType = entType;
        }
    }
    
    public void saveComments(){

        upr.Comments__c = (String.isNotBlank(upr.Comments__c))?upr.Comments__c + '<br>(User Name: '+ UserInfo.getName()+' on '+system.today().format()+') -- '+ addtnComments:'<br>(User Name: '+ UserInfo.getName()+' on '+system.today().format()+') -- '+ addtnComments;
        update upr;
        
    
    }
    public ApexPages.StandardController saveState(){
        update provCase;
        provCase = [SELECT AccountId,AssetId,Description,Id,IsClosed,Reason,RecordType.DeveloperName,RelatedRequest__c,Related_Cart__c,Related_External_User__c,Status,Subject 
        FROM Case 
                WHERE Id = :upr.Prov_case__c LIMIT 1];

         if (this.upr.Overall_Status__c.equalsIgnoreCase('Completed')) isCompleted = true;
         else isCompleted = false;

         if (this.upr.ApprovalStatus.equalsIgnoreCase('Approved')) isApproved = true;
         else isApproved = false;

         if (upr.Prov_Case__c != null && !provCase.isClosed) canChangeState = true;
         else canChangeState = false;

        return null;
    }


    public void approveRequest(){

    
     Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(approvalComments);
        req.setAction(EMS_DA_Request.REQ_ACTION_APPROVE);

        boolean isApprover = false;
        Id nextapproverId =  null;
        ApplicationHelper ah = new ApplicationHelper(upr.ConnectedAppId);
        Application__c targetApp = ah.getApplication();
        if (targetApp.ApproverType__c.equalsIgnoreCase('QUEUE')){
            Group reviewer = [select Id from Group where Type = 'Queue' and DeveloperName=:targetApp.Queue_Name__c limit 1];
            if (reviewer == null){
                System.debug('There is a big error.  Queue is null. ');
       
            } else {nextapproverId = reviewer.Id;
                if (isMemberOf(UserInfo.getuserId(),reviewer.Id)) isApprover = true;
            }
        }
        else {nextapproverId = targetApp.Approver__c;
            if (targetApp.Approver__c == UserInfo.getUserId()) isApprover= true;
        }
        if (isApprover){
            //update the upr
            UserProvisioningRequest upr2 = new UserProvisioningRequest(id=upr.id);
            upr2.Internal_Approval__c = false;
            update upr2;
        }
        else {
            UserProvisioningRequest upr2 = new UserProvisioningRequest(id=upr.id);
            upr2.Current_Step__c = 'INTERNAL';
            update upr2;
        }
        if (nextapproverId != null) req.setNextApproverIds(new Id[] {nextapproverId});
    
        Id workItemId = EMS_DA_Request.getWorkItemId(upr.Id); 
        if(workItemId == null){
            System.debug('There has been an error procesing delegated admin approval.');
           
        }else{
            req.setWorkitemId(workItemId);
            // Submit the request for approval
            Approval.ProcessResult result =  Approval.process(req);
        }
    }

    public static boolean isMemberOf(Id userId, Id groupId){
        List<GroupMember> gms  = [ select GroupId,Group.Name,Group.DeveloperName from GroupMember where 
                                UserOrGroupId= :userId and GroupId=:groupid];
        if (gms !=null && gms.size()>0) return true;
        else return false;

  
    }

    public void rejectRequest(){
          Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(approvalComments);
        req.setAction(EMS_DA_Request.REQ_ACTION_DENY);

       
    
        Id workItemId = EMS_DA_Request.getWorkItemId(upr.Id); 
        if(workItemId == null){
            System.debug('There has been an error procesing delegated admin approval.');
           
        }else{
            req.setWorkitemId(workItemId);
            // Submit the request for approval
            Approval.ProcessResult result =  Approval.process(req);
        }

    }

 }