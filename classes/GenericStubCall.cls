global class GenericStubCall extends UserProvisioning.UserProvisioningPlugin {

    private static String PARAM_USERNAME = 'username';
    private static String PARAM_FAMILY_NAME = 'familyName';
    private static String PARAM_GIVEN_NAME = 'givenName';
    private static String PARAM_NICK_NAME = 'nickName';
    private static String PARAM_EMAIL = 'email';
    private static String PARAM_PROFILEID = 'profileId';
    private static final String PARAM_CONNECTED_APPID = 'ConnectedAppId';

    global override Process.PluginDescribeResult buildDescribeCall() { 
        Process.PluginDescribeResult describeResult = new Process.PluginDescribeResult();
        describeResult.tag = 'Generic UPR Processing';
        describeResult.Name = 'Create UPA Account';
        describeResult.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{ 
               new Process.PluginDescribeResult.InputParameter(PARAM_USERNAME, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_FAMILY_NAME, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_GIVEN_NAME, Process.PluginDescribeResult.ParameterType.STRING, false),
               new Process.PluginDescribeResult.InputParameter(PARAM_NICK_NAME, Process.PluginDescribeResult.ParameterType.STRING, false),
               new Process.PluginDescribeResult.InputParameter(PARAM_EMAIL, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_PROFILEID, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(UserProvisioningUtils.PARAM_DEBUG_LOGGING, Process.PluginDescribeResult.ParameterType.BOOLEAN, false),
                new Process.PluginDescribeResult.InputParameter(PARAM_CONNECTED_APPID, Process.PluginDescribeResult.ParameterType.STRING, true)
            }; 
                
           describeResult.outputParameters = new 
            List<Process.PluginDescribeResult.OutputParameter>{ 
               new Process.PluginDescribeResult.OutputParameter('User ID', 
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
        UserProvisioningUtils.debug('Inside creating subaccount');
        UserProvisioningRequest upr = [SELECT connectedAppId, User_Reason__c,SalesforceUserId,operation,state, UserProvAccount.Id,Overall_Status__c FROM UserProvisioningRequest WHERE id = :uprId LIMIT 1];
        String userName =  (String) request.inputParameters.get(PARAM_USERNAME);
        String familyName =  (String) request.inputParameters.get(PARAM_FAMILY_NAME);
        String givenName =  (String) request.inputParameters.get(PARAM_GIVEN_NAME);
        String nickName =  (String) request.inputParameters.get(PARAM_NICK_NAME);
        String email =  (upr.Operation=='Create')?'StubAccount@foo.com':(String) request.inputParameters.get(PARAM_NICK_NAME);
        String profileId =  (String) request.inputParameters.get(PARAM_PROFILEID);
        String ConnectedAppId = (String) request.inputParameters.get(PARAM_CONNECTED_APPID);
              
        User targetUser = [SELECT Id, Ag2Ag_ID__c,External_Fed_Id__c,username,email,firstName,lastname FROM User where username=:userName];

            


        try {
            UserProvisioningUtils.init(uprId);
            

               
                             
                result.put('ExternalUserId', targetUser.Ag2Ag_ID__c);
                result.put('ExternalUsername', targetUser.External_Fed_Id__c);
                result.put('ExternalEmail', email);
                result.put('ExternalFirstName', (givenName != null) ? givenName : '' );
                result.put('ExternalLastName', familyName);
                result.put('UserID',targetUser.Id);
                result.put('Status', 'Completed');  
             
     
            
            
        } catch(Exception e) {
            UserProvisioningUtils.handleException(result, 'Exception found when calling service: ', e);
        } finally {
            UserProvisioningUtils.insertLogs();
        }

        return new Process.PluginResult(result);
    }
}