public without sharing class EMSRequestModificationPopup {

	public SelectOption[] selectedEntitlements { get; set; }
    public SelectOption[] allEntitlements { get; set; }
    private String userId;
	private Id applicationId;
	public User userForRequest{get;set;}
	public Application__c app{get;set;}
	public String comments{get;set;}
	ApplicationHelper ah;
	private Id uprId;
	private String mode;
	public boolean edit{get;set;}
	EMSUPRHelper uprHelper;
	public String operation{get;set;}



	public EMSRequestModificationPopup() {
		edit = false;
		userId = System.currentPageReference().getParameters().get('userId');
		applicationId = System.currentPageReference().getParameters().get('appId');
		uprId = System.currentPageReference().getParameters().get('uprId');
		mode = System.currentPageReference().getParameters().get('mode');
		if (mode.equalsIgnoreCase('edit')) edit = true;
		selectedEntitlements =  new List<SelectOption>();
		allEntitlements = new List<SelectOption>();
		//get user information
		//userForRequest = [SELECT Id, Name from User where Id=:userId LIMIT 1];
		userForRequest = [Select Id,Name,Username,External_Fed_Id__c,FirstName,LastName,Email,Ag2Ag_ID__c from User where Id = :userId LIMIT 1];
		System.debug('the user is:'+ userForRequest.Name);
		EMSUPRHelper uprHelper = new EMSUPRHelper(uprId,applicationId);
		comments = uprHelper.getUserReason();
		this.operation = uprHelper.getOperation();
		if (operation.equalsIgnoreCase('Deactivate')) edit=false;

		//get application information
		ah = new ApplicationHelper(applicationId);
		app = ah.getApplication();
		System.debug('The application name is:' + app.Name);
		List<Entitlements__c> availableEnts = [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:app.Id];
		System.debug('there are available ents:' + availableEnts.size());
		List<Entitlements__c> provEnts = new List<Entitlements__C>(uprHelper.getUPREntitlements());
		for(Entitlements__c ent:provEnts){
			selectedEntitlements.add(new SelectOption(ent.Id,ent.Name));
		}
		Set<SelectOption> sos = new Set<SelectOption>(selectedEntitlements);
		for(Entitlements__c ent:availableEnts){
			System.debug('the ent name is: '+ ent.Name);
			SelectOption so = new SelectOption(ent.Id,ent.Name);
			if (!sos.contains(so))
				allEntitlements.add(so);
		}

	
	}

	public void updateRequest(){
		List<Entitlements__c> ents2 = new List<Entitlements__c>();
		Set<Id> entIds = new Set<Id>();
		for ( SelectOption so : selectedEntitlements ) {
			entIds.add(so.getValue());
		}
		ents2 = [SELECT AD_Group_Optional__c,AD_Group__c,Approver__c,Ent_Code__c,Id,Name,ParentApp__c,Requires_Approval__c FROM Entitlements__c where Id in :entIds];
     	
		UserProvisioningRequest upr = new UserProvisioningRequest(id=uprId);
		upr.User_Reason__c = comments;
		update upr;

			//get cart app
		Cart_Application__c[] cartApps = [Select Name, Catalog_App__c, (SELECT Id, Ent_Code__c,Ent_Code__r.ParentApp__c from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c=:uprId LIMIT 1];
		if (cartApps != null && cartApps.size()>0){
			Cart_Application__c cartApp = cartApps[0];
   			
   		
   			Cart_Entitlement__c[] cartEnts = cartApp.Cart_Entitlements__r;
   			delete cartEnts;
        
            for (Entitlements__c ent : ents2){
            	
	                Cart_Entitlement__c cEnt = new Cart_Entitlement__c();
	                cEnt.Ent_code__c = ent.Id;
	                cEnt.Parent_App__c = cartApp.Id;
	                cEnt.RelatedUPR__c = uprId;
	                insert cEnt;
            }
            	
           }
        
        

     }

	public void cancel(){


	}

}