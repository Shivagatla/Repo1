trigger SyncCaseDetailsToCRM on Contact (after update) {
    System.debug('= in SyncCaseDetailsToCRM trigger =');
    Set<Id> setOfContactIds = new Set<Id>();
    Set<Id> setOfCaseIds = new Set<Id>();    
    
    RecordType rec = [select Id from RecordType where sObjectType = 'Case' AND Name = 'New Customer Registration' limit 1];
    
    for(Contact con : Trigger.new){
        if(Trigger.isUpdate && con.Job_Function__c == 'Farmer' && String.isBlank(Trigger.oldMap.get(con.Id).Ag2Ag_ID__c) && Trigger.oldMap.get(con.Id).Ag2Ag_ID__c != Trigger.newMap.get(con.Id).Ag2Ag_ID__c){
             setOfContactIds.add(con.Id);
         }
    }
    System.debug('= setOfContactIds size =' + setOfContactIds.size());
    if(!setOfContactIds.isEmpty()){
        for(Case c: [select id from Case where Status = 'Reviewed and Accepted' AND ContactId IN : setOfContactIds AND recordType.Id =: rec.Id AND IsClosed = true]) {
            setOfCaseIds.add(c.Id);
        }
    }        
    System.debug('= setOfCaseIds size =' + setOfCaseIds.size());
    if(!setOfCaseIds.isEmpty())
        EMSCallout.sendCases(setOfCaseIds);
}