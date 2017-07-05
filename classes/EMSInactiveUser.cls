public class EMSInactiveUser {
	public EMSInactiveUser() {
		
	}

	@InvocableMethod(label='Inactivate User' description='Inactivates a User')
    public static void inactivateUser(List<Id> aList){
        //for every new user, find the permission sets needed based on job classification and business unit
        //
        for(Id a: aList){
            inactivateUser(a);
            
        }    
    }


     @future  public static void inactivateUser(Id userId){
	   	User[] users = [SELECT Id, isActive, Email,Email_Verified__c,FirstName,LastName FROM User WHERE Id=:userId LIMIT 1];
	   	if (users == null)
	   		return;
	   	User user = users[0];
	   	user.isActive = false;
	   	update user;

     }
}