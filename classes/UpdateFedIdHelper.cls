public class UpdateFedIdHelper {

    @invocableMethod(label='Update Federation Id' description='Updates a federation id for a user')
    public static void updateFedID(List<Id> uList){
        for (Id user:uList){
            updateFedID(user);
        }
    }

    @future public static void updateFedID(Id userId){
        User[] users = [SELECT Id, isActive, FederationIdentifier, Ag2Ag_Id__c FROM User WHERE Id=:userId LIMIT 1];
        if (users == null)
            return;
        User user = users[0];
        if (!user.isActive)
            System.DEBUG(LoggingLevel.WARN,'WARN: Changing Federation ID for inactive user:' +user.Ag2Ag_Id__c );
        user.FederationIdentifier = user.Ag2Ag_Id__c;
        update user;
    }
}