public class EMSRequestQueuable implements Queueable,Database.AllowsCallouts{

	private List<CatalogWrapper> cwList;
	private User targetUser;

	public EMSRequestQueuable(List<CatalogWrapper> cwListIn, String userIn) {

		cwList = cwListIn;
	
		targetUser = [SELECT Id,Ag2Ag_Id__c,External_Fed_Id__c from User where Id=:userIn LIMIT 1];
		
	}

    public void execute(QueueableContext context){

    	List<CatalogWrapper> needsUPRs = new List<CatalogWrapper>();

    	for (CatalogWrapper cw:cwList){

    		if (cw.isChecked()==true){
	        	Application__c targetApp = cw.getApp();
	        	Entitlements__c ent = cw.getSelectedEnt();

	        	Set<Entitlements__c> ents = new Set<Entitlements__c>();
	        	ents.add(ent);

	            if (!Boolean.valueOf(targetApp.Migrated__c)) {
	            	UserProvisioningService ups = new UserProvisioningService();

	            	if (ent!=null){
	            		try{
	                		ups.entitleUser(targetUser,targetApp,ents,cw.getReason());
	                	}
	                	Catch(Exception e){

	                	}
	            	}
	                else{
	                	try{
	                		ups.entitleUser(targetUser,targetApp,null,cw.getReason()); 

	                	}
	                	catch(Exception e){

	                	}
	                }

	            }  
	            else needsUPRs.add(cw);      
	  
                   
        	} 
        }//for

         ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(needsUPRs,targetUser));
	}
}