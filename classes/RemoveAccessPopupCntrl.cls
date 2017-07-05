public without sharing class RemoveAccessPopupCntrl {

	private String userId;
	private String applicationId;
	public User userForRequest{get;set;}
	public Application__c app{get;set;}
	public String comments{get;set;}
	ApplicationHelper ah;

	public String comment{get;set;}

	public RemoveAccessPopupCntrl() {
		userId = System.currentPageReference().getParameters().get('userId');
		applicationId = System.currentPageReference().getParameters().get('appId');
		//get user information
		//userForRequest = [SELECT Id, Name from User where Id=:userId LIMIT 1];
		userForRequest = [Select Id,Name,Username,External_Fed_Id__c,FirstName,LastName,Email,Ag2Ag_ID__c from User where Id = :userId LIMIT 1];
  
		
		//get application information
		ah = new ApplicationHelper(applicationId);
		app = ah.getApplication();
	
	}

	public void submitRequest(){
		List<Entitlements__c> provEnts = ah.getProvisionedEnts(userId, app.Id);
     	System.debug('About to submit a deactivate request.');      
        ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(ah.getApplication(),userForRequest,comments,UserInfo.getName(),(new Set<Entitlements__c>(provEnts)),'Deactivate'));
     }

	public void cancel(){


	}


}