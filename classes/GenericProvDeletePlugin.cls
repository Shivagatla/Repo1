global class GenericProvDeletePlugin extends UserProvisioning.UserProvisioningPlugin {

    private static String PARAM_USERNAME = 'username';
    private static String PARAM_FAMILY_NAME = 'familyName';
    private static String PARAM_GIVEN_NAME = 'givenName';
    private static String PARAM_NICK_NAME = 'nickName';
    private static String PARAM_EMAIL = 'email';
    private static String PARAM_PROFILEID = 'profileId';
    private static final String PARAM_CONNECTED_APPID = 'ConnectedAppId';

    global override Process.PluginDescribeResult buildDescribeCall() { 
        Process.PluginDescribeResult describeResult = new Process.PluginDescribeResult();
        describeResult.tag = 'Generic Deactivate Provisioned Users';
        describeResult.Name = 'Deactivate Provisioned User';
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
     

        String userName =  (String) request.inputParameters.get(PARAM_USERNAME);

        String ConnectedAppId = (String) request.inputParameters.get(PARAM_CONNECTED_APPID);
              
        User targetUser = [SELECT Id, Ag2Ag_ID__c,External_Fed_Id__c,username,email,firstName,lastname FROM User where username=:userName];

            


        try {
            UserProvisioningUtils.init(uprId);
            
            EMSUPRHelper uprInfo = new EMSUPRHelper(uprId,ConnectedAppId);
            UserProvAccount upa = UserProvisioningUtils.getLinkedUserProvAccount(uprInfo.getUPRApplication().Connected_App_Id__c);
            if (upa==null){
                //return success
                UserProvisioningUtils.log('No active UserProvAccount was found to deactivate.');
                result.put('Status','Completed');
                UserProvisioningRequest upr = uprInfo.getUPR();
                //upr.UserProvAccount = upaNew;
                upr.Overall_Status__c='Completed';
                update upr;
            }
            else{ //we need to update the upe objects..
                System.debug('The user was already provisioned.');
                //we do need to add on additional entitlements

                Application__c targetApp = uprInfo.getUPRApplication();
                ApplicationHelper ah = new ApplicationHelper(targetApp);
                UserProvisioningService ups = new UserProvisioningService();
                boolean needManual = false;
                Set<Entitlements__c> provEnts = new Set<Entitlements__c>(ah.getProvisionedEnts(targetUser.Id, targetApp.Id));
                Set<Account> provAccts = new Set<Account>(ah.getProvisionedFEnts(targetUser.Id));
                if(Test.isRunningTest()==false){
                    if (Boolean.valueOf(targetApp.Connected_App__c)){
                        System.debug(targetApp.Name + ' is a connected app.  Calling the web service.');
                        try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c)){
                                ups.disableUserAccess(targetUser,targetApp,provEnts,provAccts,uprInfo.getReason());
                            }
                            else 
                                    ups.disableUserAccess(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                            UserProvisioningUtils.log('Made Web service call for User:' +targetUser );
                            UserProvisioningUtils.log('For  app:' + targetApp );
                            UserProvisioningUtils.log(' with entitlements: '+ uprInfo.getUPREntitlements());
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                    }
                    else{
                      
                        try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c)){
                                ups.disableUserAccess(targetUser,targetApp,provEnts,provAccts,uprInfo.getReason());
                            }
                            else 
                                ups.disableUserAccess(targetUser,targetApp,provEnts,uprInfo.getReason());
                            UserProvisioningUtils.log('Called web service for app that has no AD groups');
                            UserProvisioningUtils.log('Made Web service call for' +targetUser + ' for app:' + targetApp + ' with entitlements: '+ uprInfo.getUPREntitlements());
             
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Eception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                        
                    }
                }
                if (needManual){
                   //need to send email or start flow or something
                   UserProvisioningUtils.log('Need to manually provisioned the user');

                    result.put('Details','User needs to be manually deactivated from: ' + targetApp + ', and the account entitlements: ' + uprInfo.getCartEntitlements() );            
                }
                else{
                     result.put('Status', 'Completed');
                    result.put('Details','User successfully deactivated from: ' + targetApp + ', and the account entitlements: ' + uprInfo.getCartEntitlements() );            
                    UserProvisioningUtils.log('User successfully deactivated from: ' + targetApp + ', and the account entitlements: ' + uprInfo.getCartEntitlements() );            
 
                    UserProvisioningUtils.log('User deactivated successfully with ' + upa);
                }

              
                result.put('Status','Completed');
                result.put('ExternalUserId', targetUser.Ag2Ag_ID__c);
                result.put('ExternalUsername', targetUser.External_Fed_Id__c);
                result.put('NeedManual',needManual);
                //result.put('Details', 'User updated successfully with ' + upa);
                UserProvisioningRequest upr = uprInfo.getUPR();
                //upr.UserProvAccount = upaNew;
                upr.Overall_Status__c='Completed';
                update upr;
                  ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id,'Deactivate'));
            }
            
            
        } catch(Exception e) {
            UserProvisioningUtils.handleException(result, 'Exception found when calling service: ', e);
        } finally {
            UserProvisioningUtils.insertLogs();
        }

        return new Process.PluginResult(result);
    }
}