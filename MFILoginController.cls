global without sharing class MFILoginController {
  
    global String input {get; set;}
    global String password {get; set;}
    global String providedCode {get; set;}
       
    public String startURL  {get; set;}
    public String siteURL  {get; set;}
    
    public Boolean IsDiscovery {get; set;}
    public Boolean IsPasswordChallenged {get; set;} 
    public Boolean IsBack {get; set;}
    public Boolean IsChooser {get; set;}
    public Boolean IsSMS {get; set;}
    
    public List<Auth.VerificationMethod> methods;
    
    public String username;
    public Id userid;
    
    public String expid {get; set;}
    
    public String label;
    public String error;
    public String smsChallengeId;

    
    public Component.Apex.OutputPanel outPanel; 
    
    global MFILoginController()
    {
        startURL = System.currentPageReference().getParameters().get('startURL');
        
        if (startURL == null) startURL = '/'; 
        
        // Add verification methods
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.SMS);
        methods.add(Auth.VerificationMethod.EMAIL);
        methods.add(Auth.VerificationMethod.U2F);
        methods.add(Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        methods.add(Auth.VerificationMethod.TOTP);
       
        invokeDiscovery();
        
        expid = ApexPages.currentPage().getParameters().get('expid');
    }
    
    global String getEncodedSiteUrl() {
        return EncodingUtil.urlEncode(siteURL, 'UTF-8');
    }
    
    global String getEncodedStartUrl() {
        return EncodingUtil.urlEncode(startURL, 'UTF-8');
    }
    
    global PageReference chooser() {
        IsDiscovery = false; 
        IsChooser = true;
        IsPasswordChallenged = false;
        IsBack = true;
        IsSMS = false;
        
        label = 'Choose method:';

        return null;
    }
    
    global void invokeDiscovery() {
        IsDiscovery = true; 
        IsPasswordChallenged = false;
        IsBack = false;
        IsChooser = false;
        IsSMS = false;        
        
        label= 'Enter Email or Phone no';
    }

    // this method uses Salesforce's default page        
/*
    global PageReference invokeSMS()
    {
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.SMS);
        
        error = 'invoke SMS';

        return Site.passwordlessLogin(userid, methods, startURL);
    } 
*/
    
    global PageReference invokeEmail()
    {
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.Email);
        
        error = 'invoke Email';

        return Site.passwordlessLogin(userid, methods, startURL);
    } 
    
    global PageReference invokeAuthenticator()
    {
    
        error = 'invoke Authenticator';
        
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        
        return Site.passwordlessLogin(userid, methods, startURL);
    } 
    
    global PageReference invokeU2F()
    {
        error = 'invoke U2F';
        
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.U2F);
        
        return Site.passwordlessLogin(userid, methods, startURL);
    } 
   
    global PageReference login_with_sms(){
        IsDiscovery = false; 
        IsPasswordChallenged = false;
        IsBack = false;
        IsChooser = false;
        IsSMS = true;
        
        label= 'Enter code';  
        error = null;
        smsChallengeId = System.UserManagement.initPasswordlessLogin(userid, Auth.VerificationMethod.SMS);
        if (providedCode != null) {
            Auth.VerificationResult res = System.UserManagement.verifyPasswordlessLogin(userid, Auth.VerificationMethod.SMS, smsChallengeId, providedCode, startURL);
            if (res.success) {
                return res.redirect;
            } else {
                error = res.message;
                return null;
            }
        } else return null;
    }
      
    global PageReference login_with_password() 
    { 
        IsDiscovery = false; 
        IsPasswordChallenged = true;
        IsBack = false;
        IsChooser = false;
        
        label= 'Enter Password';
        
        User u = [select username from User where id=:userid limit 1];
        
        PageReference PageRef;
        
        if(u.username == null || u.username == '')
        {
            error = 'Username is missing';
            return null;
        }
        
        // Empty input
        if(password == null || password == '')
        {
            error = 'Enter your password...';
            return null;
        }
        
        
        // Invoke phone registration post login
        /*String redirect_url = '/apex/RegisterMethods';
        if(startURL != '')
            redirect_url+='?startURL=' + startURL;
            
        */
        try {
            PageRef = Site.login(u.username, password, startURL);
        }
        catch(Exception e) {
            error = 'Try again: ' + username;
        }
       
        return PageRef;
    }
    
    global PageReference login() {
        
        List<User> users = null;
        
        // Empty input
        if(input == null || input == '')
        {
            error = 'Enter Email or Phone';
            return null;
        }
        
    
        // If the input is a phone no.
        if (input.IsNumeric())
        {
            Profile p = [select id from profile where name = 'PasswordLess EI' Limit 1];
            
            String phone = UserManagement.formatPhoneNumber('+1', input);
            
            users = [select name, username, id, email from User where mobilephone=:phone and isactive=true and profileId=:p.Id];
            System.debug(users);
            if(users == null || users.isEmpty() == true)
            {
                error = 'Can\'t find a user';
                return null;
            }
            
            
            if(users.size() > 1)
            {
                error = 'Can\'t find a unique user';
                return null;
            }
            
            userid = users[0].id;
            
            return chooser();
        }
    
        users = [select name, username, id, email from User where username=:input ];
        if(users == null || users.isEmpty() == true)
        {
            error = 'Can\'t find a user';
            return null;
        }
    
        username = users[0].username;
        label = 'Etner your password';
        IsDiscovery = false; 
        IsPasswordChallenged = true;
        IsBack = true;
        error = '';
        
        return null;  
    } 
    
    public Component.Apex.OutputPanel getTheDiscoveryPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        Component.Apex.InputText inputTxt = new Component.Apex.InputText();
        
        inputTxt.expressions.value = '{!input}';
        
        Component.Apex.commandLink cmdLink = new Component.Apex.commandLink();
        cmdLink.value = 'NEXT';
        cmdLink.styleClass = 'signInButton';
        cmdLink.expressions.action = '{! login }';
        //cmdLink.expressions.reRender = '{labelPanel}';
        
        Component.Apex.outputLabel errorLabel = new Component.Apex.outputLabel();
        errorLabel.styleClass = 'error';
        errorLabel.value = error;
        errorLabel.id = 'errorlabel';
        
        outPanel.childComponents.add( inputTxt );
        outPanel.childComponents.add( errorLabel );
        outPanel.childComponents.add( cmdLink );
        
        return outPanel;
    }
    
    public Component.Apex.OutputPanel getThePasswordPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        
        Component.Apex.InputSecret inputSecret = new Component.Apex.InputSecret();
        inputSecret.expressions.value = '{!password}';
        
        Component.Apex.commandLink cmdLink = new Component.Apex.commandLink();
        cmdLink.value = 'Login';
        cmdLink.styleClass = 'signInButton';
        cmdLink.expressions.action = '{! login_with_password }';
        
        Component.Apex.outputLabel errorLabel = new Component.Apex.outputLabel();
        errorLabel.styleClass = 'error';
        errorLabel.value = error;
        //errorLabel.id = 'errorlabel';
        
        outPanel.childComponents.add( inputSecret );
        outPanel.childComponents.add( errorLabel );
        outPanel.childComponents.add( cmdLink );

        return outPanel;
    }
    
    public Component.Apex.OutputPanel getTheSMSPanel() {

        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        
        Component.Apex.InputText inputText = new Component.Apex.InputText();
        inputText.expressions.value = '{!providedCode}';
        
        Component.Apex.commandLink cmdLink = new Component.Apex.commandLink();
        cmdLink.value = 'Login';
        cmdLink.styleClass = 'signInButton';
        cmdLink.expressions.action = '{! login_with_sms }';
        
        Component.Apex.outputLabel errorLabel = new Component.Apex.outputLabel();
        errorLabel.styleClass = 'error';
        errorLabel.value = error;
        //errorLabel.id = 'errorlabel';
        
        outPanel.childComponents.add( inputText );
        outPanel.childComponents.add( errorLabel );
        outPanel.childComponents.add( cmdLink );

        return outPanel;
    }    
    
    public Component.Apex.OutputPanel getTheChooserPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        Component.Apex.OutputText htmlTxt = new Component.Apex.OutputText();
        Component.Apex.ActionFunction SMSfunction = new Component.Apex.ActionFunction(); 
        Component.Apex.ActionFunction Emailfunction = new Component.Apex.ActionFunction(); 
        Component.Apex.ActionFunction Authenticatorfunction = new Component.Apex.ActionFunction();
        Component.Apex.ActionFunction U2Ffunction = new Component.Apex.ActionFunction(); 
        Component.Apex.ActionFunction Passwordfunction = new Component.Apex.ActionFunction(); 
        
        SMSfunction.name = 'setSMSMethod';
        SMSfunction.expressions.action = '{!login_with_sms}';
        
        Emailfunction.name = 'setEmailMethod';
        Emailfunction.expressions.action = '{!invokeEmail}';
        
        Authenticatorfunction.name = 'setAuthenticatorMethod';
        Authenticatorfunction.expressions.action = '{!invokeAuthenticator}';
        
        U2Ffunction.name = 'setU2FMethod';
        U2Ffunction.expressions.action = '{!invokeU2F}';
        
        Passwordfunction.name = 'setPasswordMethod';
        Passwordfunction.expressions.action = '{!login_with_password}';
        
        
        htmlTxt.escape = false;
        
        htmlTxt.value = '<div class="scrollable">';
        htmlTxt.value += '<ul id="idlist">';
        htmlTxt.value += '<li><a href="#" onclick="setAuthenticatorMethod();"><img alt class="thumbnail" src="https://identitycms.herokuapp.com/DF17/phone.png"> <span>AUTHENTICATOR</span></a></li>';
        htmlTxt.value += '<li><a href="#" onclick="setU2FMethod();"><img alt class="thumbnail" src="https://identitycms.herokuapp.com/DF17/U2F.png"> <span>U2F</span></a></li>';
        htmlTxt.value += '<li><a href="#" onclick="setSMSMethod();"><img alt class="thumbnail" src="https://identitycms.herokuapp.com/DF17/phone.png"> <span>SMS</span></a></li>';
        htmlTxt.value += '<li><a href="#" onclick="setEmailMethod();"><img alt class="thumbnail" src="https://identitycms.herokuapp.com/DF17/phone.png"> <span>Email</span></a></li>';
        htmlTxt.value += '<li><a href="#" onclick="setPasswordMethod();"><img alt class="thumbnail" src="https://identitycms.herokuapp.com/DF17/phone.png"> <span>Password</span></a></li>';
        htmlTxt.value += '</ul>';
        htmlTxt.value += '</div>';
        
        outPanel.childComponents.add( htmlTxt );
        outPanel.childComponents.add( SMSfunction );
        outPanel.childComponents.add( Authenticatorfunction );
        outPanel.childComponents.add( U2Ffunction );
        outPanel.childComponents.add( Emailfunction );
        outPanel.childComponents.add( Passwordfunction );

        return outPanel;
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
    
    public Component.Apex.OutputPanel getTheErrorPanel() {
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel();
        
        Component.Apex.outputLabel outputLabel = new Component.Apex.outputLabel();
        //outputLabel.styleClass = 'itzik';
        outputLabel.value = error;
        outputLabel.id = 'errorPanel';
                
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