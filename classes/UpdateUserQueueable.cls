public without sharing class UpdateUserQueueable implements Queueable{

	public Id userId;
	String uField;
	String value;

	public UpdateUserQueueable(Id userIdIn,String field, String valueIn) {
		this.userId = userIdIn;
		this.uField = field;
		this.value = valueIn;
	}

	public void execute(QueueableContext context){

	

			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
	        
	        /* Get the token for the sobject based on the type. */
	        Schema.SObjectType st = gd.get('User');
	        
	        /* Instantiate the sobject from the token. */

	        Sobject soUser = st.newSobject(userId);
	        soUser.put(uField,value);
	        update soUser;

		 
	}

	  

}