global class LightningMFILoginFormController {

    public LightningMFILoginFormController() 
    {
    }

    @AuraEnabled
    public static String login(String username, String startUrl) 
    {
        List<Auth.VerificationMethod> methods = new List<Auth.verificationMethod>();
        // Add verification methods
        //methods.add(Auth.VerificationMethod.Password);
        methods.add(Auth.VerificationMethod.SMS);
        methods.add(Auth.VerificationMethod.EMAIL);  
        
        Profile p = [select id from profile where name = 'MFI Community User' Limit 1];
        
        String phone = UserManagement.formatPhoneNumber('+1', username);
        
        List<user> users = [select name, username, id, email from User where mobilephone=:phone and isActive=true and profileId=:p.Id];
        if(users == null || users.isEmpty() == true)
        {
        	//error = 'Can\'t find a user';   
            return null;
        }
            
            
        if(users.size() > 1)
        {
        	//error = 'Can\'t find a unique user';
            return null;
        }
              
        Id uid = users[0].id;     
        
        try{
            ApexPages.PageReference lgn = Site.passwordLessLogin(uid, methods, startUrl);
            aura.redirect(lgn);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();            
        }
    }
    
    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }
    
    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }
    }   
}
