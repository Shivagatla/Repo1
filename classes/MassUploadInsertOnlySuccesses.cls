/**
* @author Gurditta Garg
* @date March 2016
* @description This is batch class for Mass Upload
*/

public class MassUploadInsertOnlySuccesses {
    public static boolean firstRun = true;
    public void insertRecords(List<PayLoadUser> validDataList) {
        
        List<UserProvAccount> upaList = new List<UserProvAccount>();
        List<UserProvAccount> upaListToBeUpdated = new List<UserProvAccount>();
        
        Set<String> conAppIds = new Set<String>();
        Set<String> userids = new Set<String>();
        for(PayLoadUser aue : validDataList) {
            conAppIds.add(aue.connectedAppId);userids.add(aue.userId);
        }
        
        Map<String, UserProvAccount> hashUPA = new Map<String, UserProvAccount>();
        for(UserProvAccount upa : [Select Id,SalesforceUserId,Status,ConnectedAppId from UserProvAccount where 
                                   SalesforceUserId IN: userids AND ConnectedAppId IN: conAppIds]) 
        {
            hashUPA.put(upa.SalesforceUserId+Constants.HASH+upa.ConnectedAppId, upa);
        }
        for(PayLoadUser aue : validDataList) {
            String hashKey = aue.userId+Constants.HASH+aue.connectedAppId;
            UserProvAccount upaDb = hashUPA.get(hashKey);
            if(hashUPA.get(hashKey) != null && upaDb.Status.equalsIgnoreCase('Deactivated')) {
                upaDb.Status = 'Active';
                upaListToBeUpdated.add(upaDb);
            } else {
                UserProvAccount upa = new UserprovAccount
                    (
                        ConnectedAppId = aue.connectedAppId,
                        SalesforceUserId = aue.userId,
                        Status = 'Active',
                        LinkState = 'Linked',
                        ExternalUserId = aue.payload.Ag2agId,
                        ExternalUsername = aue.payload.Ag2agId,
                        ExternalEmail = aue.email,
                        ExternalFirstName = aue.firstname,
                        ExternalLastName = aue.lastname
                    );
                upaList.add(upa);
            }
        }
        System.debug('############upaListToBeUpdated############## => ' + JSON.serializePretty(upaListToBeUpdated));
        firstRun = false;
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        srList = Database.insert(upaList, false);
        firstRun = true;
        List<Database.SaveResult> urList = Database.update(upaListToBeUpdated, false);
        Set<Id> successIds = new Set<Id>();
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                successIds.add(sr.getId());
            } 
        }
        for (Database.SaveResult sr : urList) {
            if (sr.isSuccess()) {
                successIds.add(sr.getId());
            } 
        }
        Map<String, Id> UPAKeyID = new Map<String, Id>();
        for(UserProvAccount UPA : [Select SalesforceUserId,ConnectedAppId FROM UserProvAccount where Id IN :successIds]) {
            UPAKeyID.put(String.valueOf(UPA.SalesforceUserId)+UPA.ConnectedAppId, UPA.Id);
        }
        
        List<UserProvisionEntitlement__c> UPEList = new List<UserProvisionEntitlement__c>();
        for(PayLoadUser aue : validDataList) {
            
            if(UPAKeyID.get(aue.userId+aue.connectedAppId) != null) {
                UserProvisionEntitlement__c upe = new UserProvisionEntitlement__c
                    (
                        ParentApp__c = aue.appId,
                        Entitlement_Code__c = aue.entId,
                        Related_SF_User__c = aue.userId,
                        UPA_Parent__c = UPAKeyID.get(aue.userId+aue.connectedAppId)
                    );
                UPEList.add(upe);
            }
        }
        
        Database.SaveResult[] srLists = Database.insert(UPEList, false);
    }
}