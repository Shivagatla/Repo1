public without sharing class AccountHierarchy {

	public Account acct{get;set;}
	public String filter{get;set;}
	public boolean applyFilter{get;set;}

	public AccountHierarchy(Account acct,String filter, boolean applyFilter) {
		this.acct = acct;
		this.filter = filter;
		this.applyFilter = applyFilter;
		
	}

	public AccountHierarchy(Id acctId, String filter, boolean applyFilter){
		this.acct = [SELECT BillingAddress,GUID__c,Customer_number__c, PAES_Number__c, AIMS_NUmber__c, Id,IsDeleted,Name,OwnerId,ParentId FROM Account where Id = :acctId LIMIT 1];
		this.filter = filter;
		this.applyFilter = applyFilter;
	}


	public Account getSelf(){
		return acct;
	}

	public Account getParent(){
		System.debug('The parent id is:' + acct.ParentId);
		if(!isChildAccount()) return this.acct;
		Account acct = [SELECT BillingAddress,GUID__c,Id,Customer_number__c, PAES_Number__c, AIMS_NUmber__c,IsDeleted,Name,OwnerId,ParentId FROM Account where Id = :acct.ParentId LIMIT 1];
		return acct;
	}


	public boolean isChildAccount(){
		if (acct.ParentId == null || acct.ParentId == acct.Id)
			return false;
		else
			return true;

	}

	public List<Account> getChildren(boolean allLevels){
		//if alllevels = true then we return all, else, we only return the first level
		integer count = (allLevels)?5:1;
	
		AcctChild ac = new AcctChild(count,this.filter,applyFilter);
		return ac.getRecord(acct);
		
	}

	public List<Account> getParentAndChildren(boolean allLevels){
		integer count = (allLevels)?5:1;
	
		AcctChild ac = new AcctChild(count,this.filter,applyFilter);
		return ac.getRecord(getParent());
	}


public class AcctChild {
   
   public List<Account> acs;
   integer maxlevels = 1;
   integer count = 0;
   String filter;
   boolean applyFilter;
   
   public AcctChild(integer levels,String filter,boolean applyFilter) {
   
      acs = new List<Account>();
      this.filter = filter;
      this.applyFilter = applyFilter;
      this.maxlevels = levels;
     
   }
   
   public List<Account> getRecord(Account ac) {
      
      List<Account> accts = new List<Account>();
      
      try {
      
      	if(!applyFilter)
			accts = [SELECT BillingAddress,GUID__c,Customer_number__c, PAES_Number__c, AIMS_NUmber__c,Id,IsDeleted,Name,OwnerId,ParentId FROM Account where ParentId = :ac.Id LIMIT 10000];
		else
			accts = [SELECT BillingAddress,GUID__c,Id,Customer_number__c, PAES_Number__c, AIMS_NUmber__c,IsDeleted,Name,OwnerId,ParentId FROM Account where ParentId = :ac.Id and GUID_Prefix__c = :filter LIMIT 10000];
		count++;
         
      }
      catch(Exception e) {
        
         accts = null;
        
      }  
             
      if (accts != null) {
         
         for(Account temp:accts) {
            
                       
            acs.add(temp);
            if (count < maxlevels)        
            	this.getRecord(temp);

         
         }
      
      }
      
      return acs; 
     
   }

}


}