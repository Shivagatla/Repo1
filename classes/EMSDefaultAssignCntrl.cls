public with sharing class EMSDefaultAssignCntrl {

	public String userIDforAssign { get; set; }
    public String messages{get;set;}
    public boolean basePolicy {get;set;}

	public EMSDefaultAssignCntrl() {
        messages='';
        basePolicy = false;
		
	}

	 public void assignEntitlements(){
        try{
            messages='';
         
            String username = '';
            if (userIDforAssign.indexOf('@')<0)
                username = userIDforAssign + '@%';
            else
                username = userIDforAssign;
            List<User> usersL = [SELECT Id, FirstName, LastName,External_fed_id__c FROM User WHERE isActive = true AND username like :username LIMIT 1];
            if (usersL.isEmpty() || usersL.size() != 1 ){
                messages = messages+ 'A unique user was not found for:' + userIDforAssign;
                
                
            }
            else {
                User users = usersL[0];
                if (basePolicy)
                EMSEntitlementAssignment.assignEntitlementsByUsername(username,true);
                else
                EMSEntitlementAssignment.assignEntitlementsByUsername(username,false);

                
            }
            
        }
        catch(Exception e){
            
            messages = messages +'There was an error assigning the entitlements.  ' + e.getMessage();
            System.debug(e.getMessage());
            
            
        }
    }
}