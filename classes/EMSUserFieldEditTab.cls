public without sharing class EMSUserFieldEditTab {
	public User userToEdit{get;set;}
    
	boolean isEdit = false;
    public list<SelectOption> items;

	public EMSUserFieldEditTab() {
       userToEdit = [SELECT Ag2Ag_ID__c,Name,External_fed_id__c,jobClassification__c,purina__c,lol__c,corporate__c,seed__c,FGI__c,id from User where Id=:getCurrentUser()];
	}

	public String getCurrentUser(){
        return ApexPages.currentPage().getParameters().get('sfdc.userId');
    }

    public Boolean getIsEdit() {
        return isEdit;
    }

    public void edit() {
        isEdit=true;
    }

    public void save() {
        if(!Test.isRunningTest())
    		update userToEdit;
    	isEdit=false;
    }

    public PageReference cancel(){
  		isEdit = false;
        return null;	
    }

    public List<SelectOption> getItems(){
        List<SelectOption> plValues = new List<SelectOption>();
        
        Schema.DescribeFieldResult dfr = User.JobClassification__c.getDescribe();
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
            plValues.add(new SelectOption(ple.getValue(), ple.getLabel(), !ple.isActive()));
        }
        
        return plValues;
    }
}