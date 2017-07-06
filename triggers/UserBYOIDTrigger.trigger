trigger UserBYOIDTrigger on User (before update) {

    for (User u : Trigger.new) {
        
        if (Trigger.oldMap.get( u.Id ).Ag2Ag_Id__C == null && Trigger.newMap.get( u.Id ).Ag2Ag_Id__c <> null && Trigger.newMap.get( u.Id ).Ag2Ag_Id__c.length() > 1){

	        Boolean byoid = 'Farmer'.equalsIgnoreCase(u.JobClassification__c);
	        u.External_Fed_Id__c = byoid?u.email:u.Ag2Ag_ID__c;
	        u.BYOID__c = byoid;
	        u.Grower__c = byoid;
	        u.FederationIdentifier = u.Ag2Ag_Id__c;
	        //need to update contact
	        Contact[] contacts = [SELECT Id, Ag2Ag_ID__c,Ex_Username__c, Related_External_User__c from Contact where Id=:u.ContactId LIMIT 1];
				Contact c = contacts[0];
				c.Ag2Ag_ID__c = u.Ag2Ag_ID__C;
				c.Ex_Username__C = byoid?u.email:u.Ag2Ag_Id__c;
				c.Related_External_User__c = u.Id;
				update c;
    	}
      }

}