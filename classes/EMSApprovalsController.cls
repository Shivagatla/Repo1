/**********************************
Class Name: EMSApprovalsController
Description: This is an apex controller for the Items to Approve 
Version: 1.0
***********************************/
public class EMSApprovalsController {

   
        

       class PendingApproval{
        public Id recordId {get;set;}
        public String recordName {get;set;}
        public String approvalInstanceId {get;set;}
        public String approvalStepId {get;set;}
        public String sObjectLabel {get;set;}
        public String sObjectName {get;set;}
        public String submitterName {get;set;}
        public String submitterPhotoUrl {get;set;}
        public String submitDate {get;set;}
        public boolean firstOfSObjectType {get;set;}
        public String username {get;set;}
        public String appname{get;set;}
        public String operation{get;set;}
        public String requestedRoles{get;set;}
        public String requestedFEnts{get;set;}
        public Id appId{get;set;}
        public Id userId{get;set;}
        public String actor{get;set;}
        public Id actorId{get;set;}
        public String overallStatus{get;set;}
        public String approvalStatus{get;set;}
        
        public PendingApproval(ProcessInstanceWorkitem p){

            recordId = p.ProcessInstance.TargetObjectId;
            recordName = p.ProcessInstance.TargetObject.Name;
            approvalInstanceId = p.ProcessInstanceId;
            sObjectName = p.ProcessInstance.TargetObject.Type;
            submitterName = p.ProcessInstance.CreatedBy.Name;      
            submitterPhotoUrl = p.ProcessInstance.CreatedBy.SmallPhotoUrl; 
            
        }


        public PendingApproval(UserProvisioningRequest upr){
            recordId = upr.Id;
            submitterName = upr.CreatedBy.Name;
            actor = upr.Prov_Case__r.Owner.Name;
            recordName=upr.Name;


        }

    }
     public List<PendingApproval> approvalItems { get; set; }
     public Map<ID,UserProvisioningRequest> uprMap {get;set;}
  
    public EMSApprovalsController() {
      this.approvalItems = getPendingApprovals();
    }
    
    
    public  List<PendingApproval> getPendingApprovals(){
        List<PendingApproval> pendingApprovals = new List<PendingApproval>();
        Set<Id> processInstanceIds = new Set<Id>();
        Map<String, String> sObjectName2Label = new Map<String, String>();

        String prevSObjectType;
        
        Set<Id> memberOfQueueIds = new Set<Id>();
        memberOfQueueIds.add(UserInfo.getUserId());
        Map<Id,String> queues = new Map<Id,String>();
        for (GroupMember m : [  select GroupId,Group.Name from GroupMember where 
                                UserOrGroupId= :UserInfo.getUserId() 
                                and Group.Type = 'Queue']){
            memberOfQueueIds.add(m.GroupId);   
            queues.put(m.GroupId,m.Group.Name);                 
        }
        
        List<ProcessInstanceWorkitem> approvals;
         if(Test.isRunningTest()==true){
            ProcessInstance testInstance = new ProcessInstance();
            testInstance.targetObjectId = new Contact(LastName = 'Test').id;
            ProcessInstanceWorkitem testP = new ProcessInstanceWorkitem(ActorId = UserInfo.getUserId(), 
                                                                        ProcessInstance = testInstance);
            approvals = new List<ProcessInstanceWorkitem>();
            approvals.add(testP);
        }else{
            approvals = [select ProcessInstanceId, ProcessInstance.TargetObjectId, 
                                         ProcessInstance.TargetObject.Name,
                                         ProcessInstance.TargetObject.Type, ProcessInstance.CreatedBy.Name,
                                         ProcessInstance.CreatedDate, ProcessInstance.CreatedBy.SmallPhotoUrl,
                                         ActorId 
                                         from ProcessInstanceWorkitem 
                                         where isDeleted=false and ActorId IN :memberOfQueueIds and 
                                         ProcessInstance.status='Pending' order by 
                                         ProcessInstance.TargetObject.Type, SystemModstamp desc];
        }
                 

        List<Id> uprIds = new List<Id>();                            
        for(ProcessInstanceWorkitem p : approvals) {
            PendingApproval pa = new PendingApproval(p);
            pa.actor = queues.get(p.actorId);
            
            if (p.ProcessInstance.CreatedDate != null){
                pa.submitDate = p.ProcessInstance.CreatedDate.format('yyyy-MM-dd hh:mm:ss'); // was: MMM dd
            }
            
            if (p.ProcessInstance.TargetObject.Type != prevSObjectType){
                pa.firstOfSObjectType = true;
            }else{
                pa.firstOfSObjectType = false;
            }
            uprIds.add(p.ProcessInstance.TargetObjectId);
          
                          
            prevSObjectType = p.ProcessInstance.TargetObject.Type;
            pa.sObjectLabel = sObjectName2Label.get(p.ProcessInstance.TargetObject.Type);

            if (pa.sObjectLabel == null){
                String sObjectType = p.ProcessInstance.TargetObject.Type;
                if (sObjectType != null){
                    if (sObjectType.endsWith('__kav')){
                        sObjectType = sObjectType.left(sObjectType.length()-1);
                    }
    
                    pa.sObjectLabel = Schema.describeSObjects(new String[]{sObjectType})[0].getLabelPlural();
                    sObjectName2Label.put(p.ProcessInstance.TargetObject.Type, pa.sObjectLabel);
                }
            }

            pendingApprovals.add(pa);
            processInstanceIds.add(p.ProcessInstanceId);
        }

        //inprogress 
        for(UserProvisioningRequest uprProg: [SELECT Id,Name,connectedAppId,CreatedBy.Name,AppName,Application__c, 
            SalesforceUser.Id,SalesforceUser.Name,SalesforceUser.External_Fed_Id__c,state,overall_Status__c,operation,Prov_Case__r.Owner.Name FROM UserProvisioningRequest where Overall_Status__c='Processing']){
         
            uprIds.add(uprProg.Id);
            PendingApproval pa = new PendingApproval(uprProg);

            pendingApprovals.add(pa);
            System.debug('adding upr');

        }
        

        this.uprMap = new Map<Id,UserProvisioningRequest>([SELECT Id,connectedAppId,CreatedBy.Name,AppName,Application__c, SalesforceUser.Id,SalesforceUser.Name,SalesforceUser.External_Fed_Id__c,state,overall_Status__c,operation FROM UserProvisioningRequest WHERE Id in :uprIds and (State='New' or Overall_Status__c <> 'Completed')]);
      
     
        Map<Id, Id> processInstance2Step = new Map<Id, Id>();
        for(ProcessInstanceStep step : [select id, ProcessInstanceId, Actor.Name, 
                                        StepStatus from ProcessInstanceStep 
                                        where ProcessInstanceId in :processInstanceIds]){
            processInstance2Step.put(step.ProcessInstanceId, step.Id);
        }
        Set<Id> uprs = new Set<Id>();
        Map<Id,PendingApproval> upr2PA = new Map<Id,PendingApproval>();
        List<PendingApproval> finalPendingApprovals = new List<PendingApproval>();
        for (PendingApproval p1 : pendingApprovals){
            try{
                if (processInstance2Step.get(p1.approvalInstanceId) != null)
                     p1.approvalStepId = processInstance2Step.get(p1.approvalInstanceId);
                
              // if (p1.approvalStepId != null) {
                       if (uprMap != null){
                             p1.username = uprMap.get(p1.recordId).SalesforceUser.Name + ' ('+uprMap.get(p1.recordId).SalesforceUser.External_Fed_Id__c+')';
                             p1.appname = uprMap.get(p1.recordId).AppName;
                             p1.operation = uprMap.get(p1.recordId).operation;
                             //EMSUPRHelper uprHelp = new EMSUPRHelper(p1.recordId,uprMap.get(p1.recordId).connectedAppId);
                             //p1.requestedRoles = getRoleDisplay(uprHelp.getUPREntitlements());
                             p1.appId = uprMap.get(p1.recordId).connectedAppId;
                             p1.userId = uprMap.get(p1.recordId).SalesforceUser.Id;
                             p1.overallStatus = uprMap.get(p1.recordId).Overall_Status__c;
                             p1.approvalStatus = uprMap.get(p1.recordId).state;
                             uprs.add(p1.recordId);
                         }
                         else{ System.debug('null map for ' + uprIds);}
                    upr2PA.put(p1.recordId,p1);
              //  }
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
     
        //required to bulkify
       
     

        Cart_Application__c[] cartApps = [Select  UPR_Number__c, Name, Catalog_App__c, (SELECT Id, Ent_Code__c,Ent_Code__r.ParentApp__c,Ent_Code__r.Name,Account__r.Name,Account__r.GUID__c,RecordType.DeveloperName from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c in :uprs];
        if (cartApps != null && cartApps.size()>0){
            for (Cart_Application__c cartApp:cartApps){
                
                PendingApproval pa1 = upr2PA.get(cartApp.UPR_Number__c);
               

                Cart_Entitlement__c[] cartEnts = cartApp.Cart_Entitlements__r;
                if (cartEnts != null && cartEnts.size()>0){
                    
                    pa1.requestedRoles = getRoleDisplay(cartEnts);
                    pa1.requestedFEnts = getEntDisplay(cartEnts);
                }
                finalPendingApprovals.add(pa1);
            }

        }

        

        return finalPendingApprovals;
    }

    public String getRoleDisplay(Cart_Entitlement__c[] ents){
      
        String entNames = '';
        Integer count=1;
        for (Cart_Entitlement__c ent:ents){
            if (ent.RecordType.DeveloperName == 'Role'){
                if (count < ents.size())
                entNames = entNames + ent.Ent_code__r.Name+', ';
                else
                entNames = entNames + ent.Ent_code__r.Name;
                count++;
            }
        }
        return entNames;

    }
     public String getEntDisplay(Cart_Entitlement__c[] ents){
      
        String entNames = '';
        Integer count=1;
        Integer maxCount = 2;
        for (Cart_Entitlement__c ent:ents){ //
            if (ent.RecordType.DeveloperName == 'Fine_Grained'){
                if (count < ents.size() && count <= maxCount)
                    entNames = entNames +  ent.Account__r.Name+' ('+ent.Account__r.GUID__c +'), ';
                else if (count == ents.size() && count <= maxCount)
                    entNames = entNames +  ent.Account__r.Name+' ('+ent.Account__r.GUID__c +')';
                else if (count == (maxCount+1)) entNames = entNames +' ... and ' + (ents.size()-count+1) + ' more';

                count++;
            }
        }
        return entNames;

    }
}