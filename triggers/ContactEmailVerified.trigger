trigger ContactEmailVerified on Contact (before update) {

	List<Contact> toBeProcessed = new List<Contact>();
	for(Contact a :Trigger.new){

		Boolean oldVerifiedValue = Trigger.oldMap.get( a.Id ).Email_Verified__c;
		Boolean newVerifiedValue = Trigger.newMap.get( a.Id ).Email_Verified__c;
		//need to update user
		if (oldVerifiedValue != newVerifiedValue && newVerifiedValue ==true){
		
			try{
				
				Account[] managerIds = [SELECT Id, Name, Customer_Manager__c from Account where id =:a.AccountId];
				if (managerIds != null && managerIds.size()>0){
					System.debug('The account is:'+ managerIds[0].Name);
					a.Manager__c = managerIds[0].Customer_Manager__c;
				//	a.MailingState= managerIds[0].BillingState;
				//	a.MailingCity = managerIds[0].BillingCity;
				}
				User[] users = [SELECT Id, External_Fed_Id__c, Email_Verified__c from User where ContactId=:a.Id LIMIT 1];
				User u = users[0];
				u.Email_Verified__c = true;
				update u;
				System.debug('updated the user.');
				//Need to create case here
				toBeProcessed.add(a);
				
			}
			catch(Exception e){
				System.debug('Unable to update the user for contact: '+a.Email);
			}
		}
	

	}

	//now create the cases
	EMSContactReviewCaseCreation.createCase(toBeProcessed);
	System.debug('Finished processing contact trigger. Processed: '+ toBeProcessed.size());

}