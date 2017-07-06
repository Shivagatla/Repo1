global class EMSActiveDirectoryConnector extends UserProvisioning.UserProvisioningPlugin {

    private static String PARAM_USERNAME = 'username';
    private static String PARAM_FAMILY_NAME = 'familyName';
    private static String PARAM_GIVEN_NAME = 'givenName';
    private static String PARAM_NICK_NAME = 'nickName';
    private static String PARAM_EMAIL = 'email';
    private static String PARAM_PROFILEID = 'profileId';
    private static final String PARAM_CONNECTED_APPID = 'ConnectedAppId';

    //this is used for ag2ag id provisioning

    global override Process.PluginDescribeResult buildDescribeCall() { 
        Process.PluginDescribeResult describeResult = new Process.PluginDescribeResult();
        describeResult.tag = 'Active Directory Provisioning';
        describeResult.Name = 'Create Active Directory User';
        describeResult.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{ 
                new Process.PluginDescribeResult.InputParameter(PARAM_USERNAME, Process.PluginDescribeResult.ParameterType.STRING, true),
                new Process.PluginDescribeResult.InputParameter(UserProvisioningUtils.PARAM_DEBUG_LOGGING, Process.PluginDescribeResult.ParameterType.BOOLEAN, false),
                new Process.PluginDescribeResult.InputParameter(PARAM_CONNECTED_APPID, Process.PluginDescribeResult.ParameterType.STRING, true)
            }; 
                
           describeResult.outputParameters = new 
            List<Process.PluginDescribeResult.OutputParameter>{ 
               new Process.PluginDescribeResult.OutputParameter('User ID', 
                       Process.PluginDescribeResult.ParameterType.STRING),
                new Process.PluginDescribeResult.OutputParameter('Ag2Ag ID', 
                       Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('NeedManual', 
                       Process.PluginDescribeResult.ParameterType.BOOLEAN)
            };
        return describeResult;
    }
    
    global override Process.PluginResult invoke(Process.PluginRequest request) {
    
        Map<String,Object> result = new Map<String,Object>();
        result.put('Status', 'Failed'); // set default
        
        // Input parameters
        UserProvisioningUtils.isDebug = (Boolean)request.inputParameters.get(UserProvisioningUtils.PARAM_DEBUG_LOGGING);
        String uprId =  (String) request.inputParameters.get(UserProvisioningUtils.PARAM_UPR_ID);
        UserProvisioningUtils.debug('Inside Active Directiory Provisioning invoke()');


        String userName =  (String) request.inputParameters.get(PARAM_USERNAME);
          UserProvisioningUtils.debug(' Current Username is: ' + userName);
        String ConnectedAppId = (String) request.inputParameters.get(PARAM_CONNECTED_APPID);
        Map<String,String> inputParamValues = new Map<String,String>();
        inputParamValues.put(PARAM_USERNAME, userName);
        if(UserProvisioningUtils.areParamsBlank(inputParamValues, result)) {
            return new Process.PluginResult(result);
        } 
        User targetUser = [SELECT Id, Ag2Ag_ID__c,External_Fed_Id__c,username,email,firstName,phone,lastname,JobClassification__c,Contact.Account.BillingState,Contact.Account.AIMS_Number__c,Contact.Account.Name,Initial_Password__C FROM User where username=:userName];

            


        try {
            UserProvisioningUtils.init(uprId);
            
            EMSUPRHelper uprInfo = new EMSUPRHelper(uprId,ConnectedAppId);
            UserProvAccount upa = UserProvisioningUtils.getLinkedUserProvAccount(uprInfo.getUPRApplication().Connected_App_Id__c);
            if (upa==null){
                String nc = UserProvisioningUtils.getNamedCredential();
                // input validation
                String ag2agID='';
               
                boolean needManual = false;
				try{
                Application__c targetApp = uprInfo.getUPRApplication();
                UserProvisioningService ups = new UserProvisioningService();

				ag2agID = (!Test.isRunningTest())?ups.createUser(targetuser.Initial_Password__C, targetUser.firstName, targetUser.lastName, targetUser.email, targetUser.phone, targetUser.Contact.Account.Name, 'Winfield', targetUser.jobClassification__c,targetUser.Contact.Account.AIMS_Number__c,targetuser.Contact.Account.BillingState):'__dummyag2ag';
    	        UserProvisioningUtils.log('Made Web service call for' +targetUser + ' for app:' + targetApp + ' with entitlements: '+ uprInfo.getUPREntitlements());
                
                } 
                catch(Exception e){
                    UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                    needManual=true;
            	}
                    
                result.put('Status', 'Completed');               
                result.put('ExternalUserId', ag2agID);
                result.put('ExternalUsername', ag2agID);
                result.put('ExternalEmail', targetUser.email);
                result.put('ExternalFirstName', targetuser.firstName );
                result.put('ExternalLastName', targetUser.lastName);
                result.put('UserID',targetUser.Id);
                result.put('NeedManual',needManual);
                result.put('Ag2Ag ID',ag2agID);
                
                if (needManual){
                   //need to send email or start flow or something
                   UserProvisioningUtils.log('Need to manually provisioned the user');
                    result.put('Details','User needs to be manually provisioned with generated ag2ag id and email=' + targetUser.email );            }
                else{
                    result.put('Details','User created successfully in Active Directory with ExternalUserId=' + result.get('ExternalUserId') + ', and ExternalUsername=' + result.get('ExternalUsername') );                
                }

       
                
             
            }
            else{ //we need to update the upe objects..
                System.debug('The user was already provisioned.');
                ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id));
                result.put('Status','Completed');
                result.put('Details', 'User updated successfully with ' + upa);
            }
            
            
        } catch(Exception e) {
            UserProvisioningUtils.handleException(result, 'Exception found when calling service: ', e);
        } finally {
            UserProvisioningUtils.insertLogs();
        }

        return new Process.PluginResult(result);
    }
}