global without sharing class MFISignupController {
   
    public String startURL  {get; set;}
    public String siteURL  {get; set;}
    
    public Boolean IsDiscovery {get; set;}
    public Boolean IsOTPChallenged {get; set;} 
    public Boolean IsBack {get; set;}
    
    public string phone {get; set;}
    public string email {get; set;}
    public string firstname {get; set;}
    public string lastname {get; set;}
    public string password {get; set;}
    
    public List<Auth.VerificationMethod> methods;
    
    
    public String expid {get; set;}
    
    public String label;
    public String error {get; set;}
    
    public Component.Apex.OutputPanel outPanel; 
    
    global MFISignupController()
    {   
        expid = ApexPages.currentPage().getParameters().get('expid');
        
        startURL = ApexPages.currentPage().getParameters().get('startURL');
        if (startURL == null) startURL = '/';
       
        invokeDiscovery();
        
        // Add verification methods
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.SMS);
        
        
    }
    
    global String getEncodedSiteUrl() {
        return EncodingUtil.urlEncode(siteURL, 'UTF-8');
    }
    
    global String getEncodedStartUrl() {
        return EncodingUtil.urlEncode(startURL, 'UTF-8');
    }
    
    global void invokeDiscovery() {
        IsDiscovery = true; 
        IsOTPChallenged = false;
        IsBack = false;
        
        // label= 'Sign Up..';
    }
      
    
    
    global PageReference signup() {
        
        Integer len = 10;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        password = key.substring(0,len);
        
        // TODO: assign the Is Single Sign-On Enabled user perm to the user
        
        // Empty input
        if(firstname == null || firstname == '')
        {
            error = 'First name is required';
            return null;
        }
        
        if(lastname == null || lastname == '')
        {
            error = 'Last name is required';
            return null;
        }
        
        if(email == null || email == '')
        {
            error = 'Email is required';
            return null;
        }
            
        if(password == null || password == '')
        {
            error = 'Password is required';
            return null;
        }
           
        List<User> users = [select id from User where username=:email ];
        if(users != null && users.isEmpty() == false)
        {
            error = 'User already exists';
            return null;
        }
        
        // Create a new user
        Profile p = [SELECT Id FROM profile WHERE name='Customer Community User'];
        Account a = [SELECT Id FROM account WHERE name='Customers'];
        
        User u = new User();
          
        u.username = email;
        u.email = email;
        u.lastName = lastname;
        u.firstName = firstname;
        u.CommunityNickname = u.username;
        u.profileid = p.id; 
        
        try {
           String userId = Site.createExternalUser(u, a.id, password);
        }
        catch(Site.ExternalUserCreateException ex)
        {
            error = ex.getMessage();
            return null;
        }
     
        return site.login(u.username, password, startURL);
    } 
    
    
    public Component.Apex.OutputPanel getTheLabelPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        
        Component.Apex.outputLabel outputLabel = new Component.Apex.outputLabel();
        outputLabel.styleClass = 'style';
        outputLabel.value = label;
        outputLabel.id = 'labelPanel';
                
        outPanel.childComponents.add( outputLabel );
     
        return outPanel;
    }
    
    public Component.Apex.OutputPanel getTheFooterPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        Component.Apex.commandLink cmdLink = new Component.Apex.commandLink();
        
        cmdLink.value = 'Back';
        cmdLink.styleClass = 'footer';
        
        cmdLink.expressions.action = '{!invokeDiscovery}';
        
        outPanel.childComponents.add( cmdLink );
      
        return outPanel;
    }
}
