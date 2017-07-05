public  without sharing class EMSCreateUPRQueueable implements Queueable{

	List<EMSPolicyArtifactHelper> appsToAssign = null;
	User targetUser;
	AP_Rule__c entRule;
	List<CatalogWrapper> requestsToAssign = null;
	Application__c singleApp;
	String reqReason;
	String requestingUser;
	String operation;
	Set<Entitlements__c> entsList = null;
	List<RequestField> rfs;
	List<AccountWrapper> aws;
	Set<Account> acctList = null;

	public EMSCreateUPRQueueable(List<EMSPolicyArtifactHelper> appsToAssignIn, User userIdIn) {

		targetUser = userIdIn;
		this.appsToAssign = appsToAssignIn;
		operation='Create';
	
	}

	public EMSCreateUPRQueueable(List<CatalogWrapper> requests,User userIdIn){
		requestsToAssign=requests;
		targetUser = userIdIn;
		operation='Create';

	}

	public EMSCreateUPRQueueable(Application__c appIn, User userIdIn,String reason,String requestingUserIn){
		singleApp = appIn;
		targetUser = userIdIn;
		reqReason = reason;
		requestingUser = requestingUserIn;
		operation='Create';
	}



	public EMSCreateUPRQueueable(Application__c appIn, User userIdIn,String reason,String requestingUserIn,String operationIn){
		singleApp = appIn;
		targetUser = userIdIn;
		reqReason = reason;
		requestingUser = requestingUserIn;
		operation=operationIn;
	}

	public EMSCreateUPRQueueable(Application__c appIn, User userIdIn,String reason, List<RequestField> rfsIn, List<AccountWrapper> awsIn, String requestingUserIn,String operationIn){
		singleApp = appIn;
		targetUser = userIdIn;
		reqReason = reason;
		requestingUser = requestingUserIn;
		operation=operationIn;
		rfs = rfsIn;
		
		aws=awsIn;
	}

	public EMSCreateUPRQueueable(Application__c appIn, User userIdIn,String reason,String requestingUserIn,Set<Entitlements__c> entList, String operationIn){
		singleApp = appIn;
		targetUser = userIdIn;
		reqReason = reason;
		requestingUser = requestingUserIn;
		operation=operationIn;
		entsList = entList;
	}

	public EMSCreateUPRQueueable(Application__c appIn, User userIdIn,String reason,String requestingUserIn,Set<Entitlements__c> entList,Set<Account> accts, String operationIn){
		singleApp = appIn;
		targetUser = userIdIn;
		reqReason = reason;
		requestingUser = requestingUserIn;
		operation=operationIn;
		entsList = entList;
		acctList = accts;
	}

	public void execute(QueueableContext context){
		if (appsToAssign != null){

			for (EMSPolicyArtifactHelper polHelper : appsToAssign){
				for (Id polAppId : polHelper.getAppIdsForPolicy()) {
				    Application__c targetApp = polHelper.getApp(polAppId);
			        
					if (Boolean.valueOf(targetApp.Migrated__c)) {
						createUPR(targetApp,targetUser,polHelper.getPolicyId(),polHelper.getEntsforPolicyApp(polAppId),null,operation);
					}//end of migration
				}//end of app
			} //for
		}
		else if (requestsToAssign != null){
			for(CatalogWrapper cw : requestsToAssign){
				if (cw.isChecked()){
					Application__c targetApp = cw.getApp();
					Set<Entitlements__c> ents = new Set<Entitlements__c>();
					ents.add(cw.getSelectedEnt());
					createUPR(targetApp,targetUser,null,ents, cw.getReason(),operation);
				}
			}
		}
		else if(singleApp != null){
			if (Boolean.valueOf(singleApp.Migrated__c)) {

						createUPR(singleApp,targetUser,null,entsList,reqReason,operation);
					}
		}
	}//method

	public void createUPR(Application__c targetApp, User targetUser,Ap_Rule__c entRule, Set<Entitlements__c> entList, String reason, String operationIn){
	        UserProvisioningRequest upr = new UserProvisioningRequest();

        System.debug('About to start upr generation'); 
        if (isAlreadyRequested(targetApp.Connected_App_ID__c,targetUser.Id,entList,operationIn)){
        	System.debug(LoggingLevel.INFO, 'User has a pending request for '+targetApp.Name +' already.');
        	return;
        }
        upr.ApprovalStatus='Required';
        upr.Internal_Approval__c = true;
        upr.ExternalUserId = targetUser.External_Fed_Id__c;
        upr.DA_Approval_needed__c = false;
        if (operationIn.equalsIgnoreCase('Create') && Boolean.valueOf(targetApp.Requires_Approval__c)){
        	
        		upr.Internal_Approval__c = true;
        }
        else if ( operationIn.equalsIgnoreCase('Create') && !Boolean.valueOf(targetApp.Requires_Approval__c) && entRule == null && targetApp.Needs_Role__c && (entList == null || entList.size()<1)){
        	upr.Internal_Approval__c = true;
        }
        else if (Boolean.valueOf(targetApp.Requires_Approval__c) && !isRequestorAnApprover(targetApp))
            upr.Internal_Approval__c = true;
        else
            upr.Internal_Approval__c = false;
        if (Boolean.valueOf(targetApp.DA_Approval_Required__c) && operationIn.equalsIgnoreCase('Create')){
			upr.DA_Approval_needed__c = true;
			upr.DA_Bypass__c = Boolean.valueOf(targetApp.Internal_Delegated_Bypass__c);
			Id acctId = [SELECT AccountId from User where Id = :targetUser.Id].AccountId;
			List<Id> delegates = EMS_DA_UserList.getDelegatedAdmin(acctId);
			if (delegates == null || delegates.size() <1  || listContainsId(delegates,UserInfo.getUserId())){ 
				upr.DA_Approval_needed__c = false; 

			}
			else{
			upr.Delegated_Admin__c = (delegates.size()>0)?delegates.get(0):null;
			upr.Delegated_Admin_2__c = (delegates.size()>1)?delegates.get(1):delegates.get(0);
			}
        }

        upr.ConnectedAppId = targetApp.Connected_App_ID__c;
        upr.AppName = targetApp.Name;
        upr.Application__c = targetApp.ID;
        upr.Operation =operationIn;
        upr.State='New';
        upr.Overall_Status__c = 'New';
        upr.SalesforceUserId = targetUser.Id;
        
        upr.Requestor__c = UserInfo.getUserId();
        upr.Collected_Information__c = getCollectedInfo();

       
        upr.Current_step__c = (upr.DA_Approval_needed__c == true)?'DELEGATED':'INTERNAL';

       
		
		upr.ApprovalStatus = (upr.Internal_Approval__c || upr.DA_Approval_needed__c)? 'Required':'NotRequired';
        System.debug('The collect info is:' + getCollectedInfo());
        if (entRule != null)
        	upr.Responsible_rule__c = entRule.Id;
        
        else if (requestingUser <>null){
        	upr.Other_details__c = 'Requested through the Customer Access Site on ' + system.today().format() + ' by ' + requestingUser;
        }
        else{
        	 
		    upr.Other_details__c = 'Requested through the Customer Access Site on ' + system.today().format();
		  
        }
        upr.User_Reason__c = reason;
        if (operation.equalsIgnoreCase('Deactivate')){
        	//we need to set the upa on the request.
        	System.debug('setting the user prov account:' + getLinkedUserProvAccount(targetUser.Id,targetApp.Connected_App_ID__c));
        	upr.UserProvAccount = getLinkedUserProvAccount(targetUser.Id,targetApp.Connected_App_ID__c);
        }
        //upr.OwnerId = targetuser.Id;
        upr = setRequestFieldInfo(upr);

        if (targetApp.App_code__c == EMSConstants.DELEGATED_ADMIN_APPCODE){
        	List<User> owners = [SELECT Id from User where username like 'uprowner@landolakes.com.ems%'];
        	if (owners!=null && owners.size()>0){
	        	upr.OwnerId = owners.get(0).Id;
	        }
	       
        }

        insert upr;
        System.debug('Just generated upr:'+upr.Id);

        Cart_Application__c cApp = new Cart_Application__c();
        cApp.UPR_Number__c = upr.Id;
        cApp.Catalog_App__c = targetApp.Id;
        insert cApp;


        if (entList != null && entlist.size()>0){
        	Set<Id> provEnts = getProvisionedEnts(targetApp.Connected_App_ID__c,targetUser.Id);
            for (Entitlements__c polEnt : entList){
            	if (polEnt != null && provEnts.contains(polEnt.Id)==false ){
	                Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
	                cEnt.Ent_code__c = polEnt.Id;
	                cEnt.Parent_App__c = cApp.Id;
	                cEnt.RelatedUPR__c = upr.Id;
	                cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_CG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
	                insert cEnt;
            	}
            	
            }
        }

        if (acctList != null && acctList.size()>0){
        	for (Account acct:acctList){
        		Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
	                cEnt.Account__c = acct.Id;
	                cEnt.Parent_App__c = cApp.Id;
	                cEnt.RelatedUPR__c = upr.Id;
	                cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_FG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
	                insert cEnt;
        	}
        }

        if (targetApp.FG_mgmt__c == true && targetApp.FG_Default_user_acct__c == true && operation=='Create'){
        	 Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
	                cEnt.Account__c = [SELECT Contact.Account.Id from User where Id=:targetUser.Id].Contact.Account.Id;
	                cEnt.Parent_App__c = cApp.Id;
	                cEnt.RelatedUPR__c = upr.Id;
					cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_FG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;	    
	                insert cEnt;

        }

    
	     if (upr.ApprovalStatus == 'Required'){
	     	//find approver
            Id approverId = null;
            if (targetApp.ApproverType__c.equalsIgnoreCase('QUEUE')){
                Group reviewer = [select Id 
                from Group 
                where Type = 'Queue' 
                and DeveloperName=:targetApp.Queue_Name__c
                limit 1];
                if (reviewer == null){
                	System.debug('There is a big error.  Queue is null. ');
                } else {approverId = reviewer.Id;}
            }
            else {approverId = targetApp.Approver__c;}


            //setup approver Process
	        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
	        req.setComments('Submitted for approval. Please approve.');
	        req.setObjectId(upr.Id);
	        System.debug('Approver is: '+ targetApp.ApproverType__c +' and delegated admin approval is: '+ Boolean.valueOf(upr.DA_Approval_needed__c));
	        if (!Boolean.valueOf(upr.DA_Approval_needed__c)){
	        	req.setNextApproverIds(new Id[] {approverId});
	        	System.debug('setting the next approver because delegated admin is: ' + Boolean.valueOf(upr.DA_Approval_needed__c));
	        }

	        // submit the approval request for processing
	        Approval.ProcessResult result = Approval.process(req);
	        // display if the reqeust was successful
	        System.debug('Submitted for approval successfully: '+result.isSuccess());

	        //now we need to update the owner so we can have community plus users approver.
	          List<User> owners = [SELECT Id from User where username like 'uprowner@landolakes.com.ems%'];
	        if (owners!=null && owners.size()>0){
	        	upr.OwnerId = owners.get(0).Id;
	        }
	        else{
	        	System.debug(LoggingLevel.ERROR, 'Needed to find a new owner for this UPR, but could not.');
	        }
	        update upr;
	    }
	}

	public boolean isAlreadyRequested(Id connectedAppId, ID userId,Set<Entitlements__c> entList, String operation){
		List<UserProvisioningRequest> uprs = [SELECT Id from UserProvisioningRequest where SalesforceUserId=:userId and ConnectedAppId=:connectedAppId and Operation=:operation and State <> 'Completed' and State <> 'Failed'];
		if (uprs != null && uprs.size()>0) {
		

			if (entList != null && entList.size()>0){
				Set<Id> uprIds = new Set<id>();
				for (UserProvisioningRequest upr:uprs){
					uprIds.add(upr.Id);
				}
				Set<Id> entIds = new Set<id>();
				for (Entitlements__c ent:entList){
					if (ent<> null && ent.Id<>null)
						entIds.add(ent.Id);
				}
				Cart_Entitlement__c[] cartentss = [select Id from Cart_Entitlement__c where RelatedUPR__c in :uprIds and Ent_code__c in :entIds];
				System.debug('Found already requested apps for this entitlement.' + cartentss.size());
				if (cartentss.size() > 0){
					return true;
				}

			}else 
				return true;

		}

	

		return false;
	}

	public Set<Id> getProvisionedEnts(Id appId, Id userId){
		Set<Id> ids = new Set<Id>();
		UserProvAccount[] upaList = [SELECT name, externalUserId, externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE ConnectedappId=:appid and salesforceUserId = :userId AND linkState = 'Linked' ];
        if(upaList.size() > 0){
        	Set<Id> upaIds = new Set<Id>();
        	for(UserProvAccount upa:upaLIst){
        		upaIds.add(upa.Id);
        	}

        	UserProvisionEntitlement__c[] upes = [SELECT Entitlement_Code__c from UserProvisionEntitlement__c where UPA_parent__c in:upaIds];
        	for (UserProvisionEntitlement__c upe:upes){
        		ids.add(upe.Id);
        	}
        }
       	return ids;

	}

	public Set<Id> getProvisionedFGEnts(Id appId, Id userId){
		Set<Id> ids = new Set<Id>();
		UserProvAccount[] upaList = [SELECT name, externalUserId, externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE ConnectedappId=:appid and salesforceUserId = :userId AND linkState = 'Linked' and status='Active'];
        if(upaList.size() > 0){
        	Set<Id> upaIds = new Set<Id>();
        	for(UserProvAccount upa:upaLIst){
        		upaIds.add(upa.Id);
        	}

        	UserProvFineEntitlement__c[] upfes = [SELECT Entitled_Account__c from UserProvFineEntitlement__c where UPA_Parent__c in:upaIds];
        	for (UserProvFineEntitlement__c upfe:upfes){
        		ids.add(upfe.Id);
        	}
        }
       	return ids;

	}

 	public UserProvAccount getLinkedUserProvAccount(String userId, Id appId) {
        UserProvAccount upa;
        UserProvAccount[] upaList = [SELECT name, externalUserId, SalesforceUserId, externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE ConnectedappId=:appid and salesforceUserId = :userId AND linkState = 'Linked'];
        if(upaList.size() > 0)
            upa = upaList[0];
        return upa;
    }


    public boolean isRequestorAnApprover(Application__c targetApp){

 		if (targetApp.ApproverType__c.equalsIgnoreCase('QUEUE')){
              
                // check current user's queue membership

                GroupMember[] groups = [SELECT 
					    Group.Name
					FROM 
					    GroupMember 
					WHERE 
					    UserOrGroupId = :UserInfo.getUserId() 
					    AND Group.Type = 'Queue'
					    AND Group.DeveloperName = :targetApp.Queue_Name__c];
				if (groups == null || groups.size()<1) return false;
				else return true;
            }
            else {
            	return (UserInfo.getUserId() == targetApp.Approver__c);
            }


    	return false;
    }

    public String getCollectedInfo(){
    	String colInfo = '';
    	if (rfs != null){
    		
    		Set<Id> rfIds = new Set<Id>();
    		
	    		Map<Id,String> rfMap = new Map<Id,String>();

	    		for(RequestField rf:rfs){
	    			if (rf.rfId != null)
	    				rfIds.add(rf.rfId);
	    				
	    			
	    		}
	    		 Map<Id,Request_Field__c> rfcMap = new Map<Id,Request_Field__c>([SELECT Field_Label__c,Save_To_Object__c,Field_Type__c,Required__c,Field_Name__c FROM Request_Field__c WHERE Id IN :rfIds]);
    		
    		for(RequestField rf:rfs){
    		
    			String fieldTem = EMSConstants.REQ_FIELD_TEMPLATE;
    			fieldTem = fieldTem.replace('Label',rfcMap.get(rf.rfId).Field_Label__c);

    			fieldTem = fieldTem.replace('Value',(String.ISBLANK(rf.Value)?'Not provided':rf.Value));
    			
    			colInfo += fieldTem;
    		}
    	}
    

		if (aws != null){
    		
    		
    		
    		for(AccountWrapper aw:aws){
    		
    			String fieldTem = EMSConstants.REQ_FG_TEMPLATE;
    			fieldTem = fieldTem.replace('Name',(aw.Name==null)?'Not provided':aw.Name);
    			fieldTem = fieldTem.replace('Address',(aw.Address==null)?'Not provided':aw.Address);
    			fieldTem = fieldTem.replace('AcctNo',(aw.AcctNo==null)?'Not provided':aw.AcctNo);
    			colInfo += fieldTem;
    		}
    	}
    	return colInfo;
    }

    public UserProvisioningRequest setRequestFieldInfo(UserProvisioningRequest upr){

    	try{
			if (rfs != null){
	    		
	    		Set<Id> rfIds = new Set<Id>();
	    		Map<Id,String> rfMap = new Map<Id,String>();

	    		for(RequestField rf:rfs){
	    			if (rf.rfId != null)
	    				rfIds.add(rf.rfId);
	    				rfMap.put((Id)rf.rfId,rf.value);
	    			
	    		}

	    	    List<Request_Field__c> rfcs = [SELECT Field_Label__c,Save_To_Object__c,Field_Type__c,Required__c,Field_Name__c FROM Request_Field__c WHERE Id IN :rfIds];
	    	    SObject soUser = getNewSobject('User',targetUser.id);
	    	    SObject soContact = getNewSobject('Contact',[SELECT ContactId From User where Id =:targetUser.Id].ContactId);
	    		for(Request_Field__c rfc : rfcs){
		        	
		          	if( rfc.Save_To_Object__c.equalsIgnoreCase('User')){
		          		soUser.put(rfc.Field_Name__c, rfMap.get(rfc.Id));
		          	}
		          	else if( rfc.Save_To_Object__c.equalsIgnoreCase('Contact')){

	                	
	                	soContact.put(rfc.Field_Name__c, rfMap.get(rfc.Id));
	            	}
	            	else if(rfc.Save_To_Object__c.equalsIgnoreCase('Request')){
	            	            		upr.put(rfc.Field_Name__c,rfMap.get(rfc.Id));
	            	}
	        	}
	        	try{	
	        		update soUser;
	        	}
	        	catch(Exception e){
	        		upr.Other_details__c = upr.Other_details__c + ' **Unable to save collected information to User Object.';
	        	}
	        	try{
	        		update soContact;
	        	}
	        	catch(Exception e){
	        		upr.Other_details__c = upr.Other_details__c + ' **Unable to save collected information to Contact Object.';
	        	}
	        }
    	}
    	catch(Exception e){
    		System.debug('There was an exception in setting the Request Fields: '+ e.getMessage());
    	}
        return upr;

       
    }

    public static SObject getNewSobject(String gett,String objId) {
    
        /* Call global describe to get the map of string to token. */
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        
        /* Get the token for the sobject based on the type. */
        Schema.SObjectType st = gd.get(gett);
        System.assert(st != null,'Type provided: "' + gett + '" doesnt map to an sobject token in this org.');
        
        /* Instantiate the sobject from the token. */
        Sobject s = st.newSobject((ID)objId);
        
        return s;
    }

    private boolean listContainsId(List<Id> listToCompare, Id item){
    	for(Id idToCompare:listToCompare){
    		if (idToCompare == item) return true;
    	}
    	return false;
    }
	
}