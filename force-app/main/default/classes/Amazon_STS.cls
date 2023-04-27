public without sharing class Amazon_STS {
    
    Static String dateStamp = Datetime.now().formatGMT('yyyyMMdd');
    Static String amzDate = Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    
    public static String makeCallout()
    {    
        try
        {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            //Please Provide ExternalId,Your_Role_ARN
            //Make sure in Named Credential , u have provided all the required values too(Name of Named Credential :AWS_STS)
            request.setEndpoint('callout:AWS_STS/?Action=AssumeRole&DurationSeconds=3600&ExternalId=<Your_External_Id>&RoleArn=<Your_Role_ARN>&RoleSessionName=Session_1&Version=2011-06-15');
            
            request.setMethod('GET');
            
            HttpResponse response = new HttpResponse();
            
            if(!Test.isRunningTest())
            	response=http.send(request);
            else
            {
                response.setStatusCode(200);
                response.setBody('<AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"><AssumeRoleResult><AssumedRoleUser><AssumedRoleId>AssumedRoleId</AssumedRoleId><Arn>ArnId</Arn></AssumedRoleUser><Credentials><AccessKeyId>AccessKey</AccessKeyId><SecretAccessKey>SecretKey</SecretAccessKey><SessionToken>sessiontoken</SessionToken><Expiration>ExpirationDate</Expiration></Credentials></AssumeRoleResult><ResponseMetadata><RequestId>requestId</RequestId></ResponseMetadata></AssumeRoleResponse>');
            }
            
            if(response.getStatusCode()==200)
            {
                System.debug('response.getBody() : '+response.getBody());
                return response.getBody();
            }
            else
                return '';
        }catch(Exception e)
        {
            system.debug('Exception : '+e);
            return '';
        }
    }
        
    public static Map<String,String> getToken()
    {
        String response=makeCallout();
        Map<String,String> responseMap=new Map<String,String>();
        if(String.isNotBlank(response))
        {
            try{
                Dom.Document doc = new Dom.Document();  
                doc.load(response);  
                Dom.XMLNode rootElement = doc.getRootElement();  
                for ( Dom.XMLNode childElement : rootElement.getChildElements() ) {
                    responseMap.put(childElement.getName(),(String.isBlank(childElement.getText())==true?'':childElement.getText()));
                    for (Dom.XMLNode detailElement : childElement.getChildElements()){
                        responseMap.put(detailElement.getName(),(String.isBlank(detailElement.getText())==true?'':detailElement.getText()));
                        for (Dom.XMLNode detailElement1 : detailElement.getChildElements()){
                            responseMap.put(detailElement1.getName(),(String.isBlank(detailElement1.getText())==true?'':detailElement1.getText()));
                            for (Dom.XMLNode detailElement2 : detailElement1.getChildElements()){
                                responseMap.put(detailElement2.getName(),(String.isBlank(detailElement2.getText())==true?'':detailElement2.getText()));
                            }
                        }
                    } 
                } 
            }
            catch(Exception ex){
                System.debug(ex.getCause());
                System.debug(ex.getMessage());
                System.debug(ex.getStackTraceString());
            }
            for(String key:responseMap.keySet())
                System.debug(key+' : '+responseMap.get(key));
            
        }
        return responseMap;
        
    }

}