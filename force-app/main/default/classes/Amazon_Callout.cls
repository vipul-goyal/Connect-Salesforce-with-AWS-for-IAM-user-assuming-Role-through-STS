public class Amazon_Callout {

    public String host;
    public String region;
    public String service;
    public String resource;
    public String accessKey;
    public String payloadSha256;
    public String contentType;  
    public Url endpoint;
    public HttpMethod method;
    public Blob payload;
    public String caseId;
    public String sessionKey;
    public String body;
    public Boolean hasError=false;
    
    Blob signingKey;
    String signature;
    String canonicalRequest;
    DateTime requestTime;
    Map<String, String> queryParams;
    Map<String, String> headerParams;
    Map<String,String> responseMap;
    
    public enum HttpMethod {XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST}
    
    public void init()
    {
        accessKey = responseMap.get('AccessKeyId');
        createSigningKey(responseMap.get('SecretAccessKey'));
        sessionKey=responseMap.get('SessionToken');
        payload = Blob.valueOf(body); 
    }
    
    //	Call this constructor with all the values
    public Amazon_Callout(String resource,String region,String service,String contentType,String body) {
        requestTime = DateTime.now();
        queryParams = new Map<String, String>();
        headerParams = new Map<String, String>();
        responseMap=Amazon_STS.getToken();
        if(responseMap.containsKey('error'))
        {
            hasError=true;
            //Logic to log error
        }
        this.resource=resource;
        this.region=region;
        this.service=service;
        //content type for AWS is usually 'application/x-www-form-urlencoded'
        this.contentType=contentType;
        this.endpoint=new Url('https://' + service + '.' + region + '.amazonaws.com/');
        this.method=HttpMethod.XPOST;
        this.body=body;       
    }
    
    //	Send a default request
    public HttpResponse sendRequest(String caseId) {
        this.caseId=caseId;
        if(hasError)
        {
            return new HttpResponse();
        }
        return sendRequest(new Set<Integer> { 200,201 });
    }    
    
    //	Actually perform the request, and throw exception if response code is not valid
    public HttpResponse sendRequest(Set<Integer> validCodes) {
        HttpRequest request = createQuerySignedRequest();
        HttpResponse response = new HttpResponse();
        if(!Test.isRunningTest())
        {
            response=new Http().send(request);
        }else
        {
            response.setStatusCode(200);
        }
        
        System.debug('Status : '+response.getStatusCode());
        System.debug('Body : '+response.getBody());
        
        if(!validCodes.contains(response.getStatusCode())) {
            throw new ServiceException(response.getBodyDocument().getRootElement());
        }
        
        return response;
    }
    
    HttpRequest createQuerySignedRequest(){
        String stringToSign;
        String finalEndpoint;
        String queryString;
        String canonicalHeaders;
        HttpRequest request = new HttpRequest();
        
        init();
        
        request.setMethod(method.name().removeStart('X'));
        payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', payload));
        request.setBodyAsBlob(payload);
        
        if(host == null) {
            host = service + '.' + region + '.amazonaws.com';
        }
        
        setHeader('Content-type', contentType);
        setHeader('Host', host);
        if(!String.isNotBlank(sessionKey))
            setHeader('X-Amz-Security-Token',sessionKey);
        
        request.setHeader('Content-type', contentType);
        request.setHeader('X-Amz-Security-Token',sessionKey);        
        request.setHeader('X-Amz-Algorithm','AWS4-HMAC-SHA256');
        request.setHeader('X-Amz-Credential', String.join(new List<String> {
            accessKey,
                requestTime.formatGMT('yyyyMMdd'),
                region,
                service,
                'aws4_request' 
                },'/'));
        request.setHeader('X-Amz-Date',requestTime.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\''));
        request.setHeader('X-Amz-SignedHeaders', + String.join(new List<String>(headerParams.keySet()),';').toLowerCase());
        
        //Create the signature
        queryString = createCanonicalQueryString();
        System.debug('queryString : '+queryString);
        canonicalHeaders = createCanonicalHeaders();
        System.debug('canonicalHeaders : '+canonicalHeaders);
        canonicalRequest = createCanonicalRequest(queryString,canonicalHeaders);
        System.debug('canonicalRequest : '+canonicalRequest);
        stringToSign = createStringToSign(canonicalRequest);
        System.debug('stringToSign : '+stringToSign);
        createSignature(stringToSign);
        
        String authorizationHeader = 'AWS4-HMAC-SHA256' + ' ' 
            + 'Credential=' + accessKey + '/' 
            + String.join(new List<String> {
                requestTime.formatGMT('yyyyMMdd'),
                    region,
                    service,
                    'aws4_request' 
                    },'/') + ', ' 
            +  'SignedHeaders=' + String.join(new List<String>(headerParams.keySet()),';').toLowerCase() + ', ' 
            + 'Signature=' + signature;
        
        
        request.setHeader('Authorization', authorizationHeader);        
        //Add the signature at the end
        queryString += '&X-Amz-Signature=' + signature;
        System.debug('authorizationHeader : '+authorizationHeader);
        System.debug('signature : '+signature);
        
        finalEndpoint = new Url(endpoint, resource).toExternalForm() ;//+ '?'+ queryString;
        
        request.setEndpoint(finalEndpoint);
        
        return request;
    }    
    
    public void createSigningKey(String secretKey)
    {
        Blob dateKey = signString(Blob.valueOf(requestTime.formatGMT('yyyyMMdd')),Blob.valueOf('AWS4'+secretKey));
        Blob dateRegionKey = signString(Blob.valueOf(region),dateKey);
        Blob dateRegionServiceKey = signString(Blob.valueOf(service),dateRegionKey);
        signingKey = signString(Blob.valueOf('aws4_request'),dateRegionServiceKey);
    }
    
    //	Create a canonical query string (used during signing)
    String createCanonicalQueryString() {
        List<String> results = new List<String>();
        List<String> keys = new List<String>(queryParams.keySet());
        
        keys.sort();
        
        for(String key: keys) {
            results.add(key + '=' + queryParams.get(key));
        }
        
        return String.join(results, '&');
    }
    
    //	Create the canonical headers (used for signing)
    String createCanonicalHeaders() {
        List<String> results = new List<String>();
        List<String> keys = new List<String>(headerParams.keySet());
        
        keys.sort();
        
        for(String key: keys) {
            results.add(key + ':' + headerParams.get(key));
        }
        
        return String.join(results, '\n')+'\n';
    }
    
    // Create the entire canonical request
    String createCanonicalRequest(String queryString, String canonicalHeaders) {
        String result = String.join(
            new List<String> {
                method.name().removeStart('X'),	
                    new Url(endPoint, resource).getPath(),				
                    queryString,							
                    canonicalHeaders,						
                    String.join(new List<String>(headerParams.keySet()), ';'),	
                    payloadSha256							
                    },
            '\n');
        
        return result;
    }
    
    //	Create the entire string to sign
    String createStringToSign(String canonicalRequest) {
        String result = String.join(
            new List<String> {
                'AWS4-HMAC-SHA256',
                    requestTime.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\''),
                    String.join(new List<String>{requestTime.formatGMT('yyyyMMdd'), region, service, 'aws4_request' },'/'),
                    EncodingUtil.convertToHex(Crypto.generateDigest('sha256', Blob.valueof(canonicalRequest)))
                    },
            '\n'
        );
        
        return result;
    }
    
    private void createSignature(String stringToSign){
        signature =  EncodingUtil.convertToHex(signString(blob.valueof(stringToSign),signingKey));
    }
    
    public string uriEncode(String value) {
        return value==null? null: EncodingUtil.urlEncode(value, 'utf-8').replaceAll('%7E','~').replaceAll('\\+','%20');
    }
    
    public void setHeader(String key, String value) {
        headerParams.put(key.toLowerCase(), value);
    }
    
    public void setQueryParam(String key, String value) {
        queryParams.put(key.capitalize(), UriEncode(value));
    }  
    
    private Blob signString(Blob msg, Blob key)
    {
        return Crypto.generateMac('HMACSHA256', msg, key);
    }
    
    //U can modify it to show the user the error as you like
    public class ServiceException extends Exception {
        public String Code, Message, Resource, RequestId;
        
        public ServiceException(Dom.XmlNode rootNode) {
        }
        
        public String toString() {
            return JSON.serialize(this);
        }
    }
}
