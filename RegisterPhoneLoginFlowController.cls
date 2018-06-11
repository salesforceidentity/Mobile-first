public with sharing class RegisterPhoneLoginFlowController {
    
    
    public PageReference finishFlow() {
       
        String userId = UserInfo.getUserId(); 
        String startURL = System.currentPageReference().getParameters().get('startURL');
        
        if (startURL == null) startURL = '/';
        
        List<TwoFactorMethodsInfo> methods = [SELECT Id, HasVerifiedMobileNumber FROM TwoFactorMethodsInfo WHERE userid=:userId]; 
        
        if (methods[0].HasVerifiedMobileNumber != true) {
            startURL = '/apex/registerphone';
       }
       
       Auth.SessionManagement.FinishLoginFlow();
       return new PageReference(startURL);
    }
}