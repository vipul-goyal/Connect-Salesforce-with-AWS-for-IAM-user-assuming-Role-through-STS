# Connect-Salesforce-with-AWS-for-IAM-user-assuming-Role-through-STS

This library can be used by any user who is trying to use STS Assume role to get the Access Key,Secret Key and Session Id for using any other API like SNS.

To execute the code you have call the following function of Amazon_Callout Class : sendRequest(objectId)

Ensure that the named credential has been updated before making any callout, as that will result in failure.

Steps to make callout : 

1)Create an object Amazon_Callout class i.e. Amazon_Callout amz=new Amazon_Callout(resource,region,service,contentType,body);
    Here body is the content of the request body.

    
2)Call the request function i.e. amz.sendRequest(objectId)
    This method will return a response object, in case we are unable to obtain atoken from aws ,we will get a new HttpResponse object without any data.
 

Please note that separate comments to handle error are already present in the class, please add your logic there.




Please star the solution , if it helps.


If you have any suggestions , please message me on : me@vipulgoyal.dev
