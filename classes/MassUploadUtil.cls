/**
* @author Gurditta Garg
* @date March 2016
* @description This class is a Utility for Mass Upload
*/

public class MassUploadUtil {
    
    /*******************************************************************************************************
* @description This method is the utility for parsing the CSV file and getting the list of Rows
* @param CSV file's as a String and a boolean flag for skipping headers or not
* @return List of Rows
*/    
    public List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        //System.debug('#####contents####' + contents);
        List<List<String>> allFields = new List<List<String>>();
        try {
            if(safeSplit(contents, '\r\n').size() > 5002) {
                //System.debug('#####sizeExceeded####');
                return null;
            }
            contents = contents.replaceAll(',"""', ',"DBLQT').replaceall('""",', 'DBLQT",');
            contents = contents.replaceAll('""', 'DBLQT');
            List<String> lines = new List<String>();
            try {
                lines = contents.split('\n');
                //lines = contents.split('\r'); // using carriage return accomodates windows, unix, and mac files
            } catch (System.ListException e) {
                System.debug('Limits exceeded?'+ e.getMessage());
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Error in Parsing the CSV file. Please contact Admin'));
                return null;
            }
            Integer num = 0;
            //system.debug('#########lines#############' + lines);
            for (String line :lines) {
                List<String> cleanFields = new List<String>();
                // check for blank CSV lines (only commas)
                if (line.replaceAll(',', '').trim().length() != 0){
                    String compositeField;
                    Boolean makeCompositeField = false;
                    for (String field :line.split(',')) {
                        if (field.startsWith('"')&&field.endsWith('"')) {
                            cleanFields.add(field.replaceAll('DBLQT', '"'));
                        } else if (field.startsWith('"')) {
                            makeCompositeField = true;
                            compositeField = field;
                        } else if (field.endsWith('"')) {
                            compositeField +=','+ field;
                            cleanFields.add(compositeField.replaceAll('DBLQT', '"'));
                            makeCompositeField = false;
                        } else if (makeCompositeField) {
                            compositeField +=','+ field;
                        } else {
                            cleanFields.add(field.replaceAll('DBLQT', '"'));
                        }
                    }
                }
                allFields.add(cleanFields);
            }
            if (skipHeaders)allFields.remove(0);
        } catch(Exception e){
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Error in Parsing the CSV file. Please contact Admin'));
            return null;
        }
        return allFields;
    }
    
    private List<String> safeSplit(String inStr, String delim){
        Integer regexFindLimit = 100;
        Integer regexFindCount = 0;    
        List<String> output = new List<String>();    
        Matcher m = Pattern.compile(delim).matcher(inStr);    
        Integer lastEnd = 0;
        while(!m.hitEnd()){
            while(regexFindCount < regexFindLimit && !m.hitEnd()){
                if(m.find()){
                    output.add(inStr.substring(lastEnd, m.start()));  
                    lastEnd = m.end();
                } else{
                    output.add(inStr.substring(lastEnd));
                    lastEnd = inStr.length();
                }            
                regexFindCount++;
            }
            m.reset(inStr);        
            m.region(lastEnd, m.regionEnd());        
            regexFindCount = 0;
        }    
        return output;
    }
    
    public PageReference uploadingFalied() {
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.WARN, 'Uploading file failed due to one of the following reasons :'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'File might contains more than 5000 records.'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'File might has no data or blank file'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'File might contain more than 1 Millions characters'));
        return null;
    }
    
    public PageReference validateProvisioning(){
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.WARN, 'Mass New Users Provisioning failed due to one of the following reasons :'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'There may be no new users for mass provisioning. Please upload new users first.'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'There may be some error while giving access to the Users. Please check your mail.'));
        return null;
    }
    
    public PageReference validateEmailNotification(){
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.WARN, 'Mass New Users Email Notification failed due to one of the following reasons :'));
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'There may be no new users for mass email notification. Please do mass provisioning for the new users first.'));
        return null;
    }
    
    /**
This function convers the input CSV file in BLOB format into a string
@param input    Blob data representing correct string in @inCharset encoding
@param inCharset    encoding of the Blob data (for example 'ISO 8859-1')
*/
    public String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }  
    
    public void sendEmail(String finalstr, String filename, String finalstr2, String filename2, String subject,String emailBody)  {
        List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
        if(finalstr != null && filename != null) {
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName(filename + '.csv');
            blob csvBlob = Blob.valueOf(finalstr);
            csvAttc.setBody(csvBlob);
            efaList.add(csvAttc);
        }
        if(finalstr2 != null && filename2 != null) {
            Messaging.EmailFileAttachment csvAttc1 = new Messaging.EmailFileAttachment();
            csvAttc1.setFileName(filename2 + '.csv');
            blob csvBlob1 = Blob.valueOf(finalstr2);
            csvAttc1.setBody(csvBlob1);
            efaList.add(csvAttc1);
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSaveAsActivity(false);
        List<String> toAddresses = new List<String>();
        toAddresses.add(UserInfo.getUserEmail());
        email.setSubject(subject);
        email.setToAddresses(toAddresses);
        email.setPlainTextBody(emailBody);
        email.setFileAttachments(efaList);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
    }
    
    public String createEmailBody(Id jobId) {
        AsyncApexJob asyncJob = [SELECT Id,ApexClass.Name,CompletedDate,CreatedDate,Status FROM AsyncApexJob WHERE Id = :jobId];
        String finalstr = Constants.HI+Constants.SPACE+UserInfo.getFirstName()+Constants.SPACE+UserInfo.getLastName()+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +'Mass Upload Batch has finished. Please see below for details'+Constants.COLON+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +'Task Status'+Constants.COLON+Constants.SPACE+asyncJob.Status+Constants.NEWLINE;
        finalstr = finalstr +'Start Date'+Constants.COLON+Constants.SPACE+ asyncJob.CreatedDate+Constants.NEWLINE;
        finalstr = finalstr +'End Date'+Constants.COLON+Constants.SPACE+ asyncJob.CompletedDate+Constants.NEWLINE+Constants.NEWLINE;
        return finalstr;
    }
    
    public String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    public String generateHash(String string2Hash){
        Blob hashSHA1 = Crypto.generateDigest('SHA1', Blob.valueOf(string2Hash));
        return base64URLencode (hashSHA1);
    }
    
    public String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }
}