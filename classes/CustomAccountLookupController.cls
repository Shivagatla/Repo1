public with sharing class CustomAccountLookupController {
    
    public Account account {get;set;} // new account to create
    public List<Account> results{get;set;} // search results
    public string searchString{get;set;} // search keyword
    private string connectedAppId;
    private Id userId;
    private Application__c app;
    
    public CustomAccountLookupController() {
        account = new Account();
        // get the current search string
        searchString = System.currentPageReference().getParameters().get('lksrch');
        
        connectedAppId = System.currentPageReference().getParameters().get('appId');
        userid =  System.currentPageReference().getParameters().get('userId');
    }
    
    // performs the keyword search
    public PageReference search() {
        runSearch();
        return null;
    }
    
    // prepare the query and issue the search command
    private void runSearch() {
        // TODO prepare query string for complex serarches & prevent injections
        results = performSearch(searchString);               
    } 
    
    // run the search and return the records found. 
    private List<Account> performSearch(string searchString) {
        
        Boolean first = true;
        String tester = searchString;
        if(String.isBlank(searchString) || (tester.remove('*')).length()<2){
           ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Please enter at least 2 non-wildcard characters into the search field.');
            ApexPages.addMessage(msg);
            return null;
        }

        String soql = 'select Id,GUID__c,Name from account';

        ApplicationHelper ah = new ApplicationHelper(connectedAppId,false);
        app = ah.getApplication();
        List<Account> hierarchy = ah.getFineGrainAccounts(userId); 


        String whereClause = '';
        if (app.FG_Filter_prefix__c != null){
            List<String> pFilters = app.FG_Filter_prefix__c.split(';');
            List<String> buFilters = new List<String>();
            for(String s:pFilters){
                buFilters.add('\''+s+'\'');
            }
           whereClause = ' WHERE GUID_Prefix__c IN ('+ String.join(buFilters,',')+')'; 
        }
        String cleanSearch = String.escapeSingleQuotes(searchString);

        String searchquery = 'FIND :cleanSearch IN ALL FIELDS RETURNING Account(Name, GUID__c, Id, BillingAddress, BillingStreet, BillingCity,BillingState '+ whereClause + ' LIMIT 1000)';
        System.debug('Query: ' + searchQuery);
        List<List<SObject>> results = search.query(searchquery);  

        return ((List<Account>)results[0]);
      
    }
    
  
    
    // used by the visualforce page to send the link to the right dom element
    public string getFormTag() {
        return System.currentPageReference().getParameters().get('frm');
    }
    
    // used by the visualforce page to send the link to the right dom element for the text box
    public string getTextBox() {
        return System.currentPageReference().getParameters().get('txt');
    }

    

    
}