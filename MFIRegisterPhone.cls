global with sharing class MFIRegisterPhone {
    
    public List<Auth.VerificationMethod> methods;
    
    global PageReference verify() {
    
        // TBD - check if phone no. already exists in the org...
        
        String phone = ApexPages.currentPage().getParameters().get('phone');
        
        methods = new List<Auth.verificationMethod>();
        methods.add(Auth.VerificationMethod.SMS);
        
        Pagereference pageRef = System.UserManagement.registerVerificationMethod(Auth.VerificationMethod.SMS, '/');
        pageref.getParameters().put('p', phone);
        
        //Id uid = Userinfo.getUserId();
        //User u = [select communityNickname from User where id=:uid];
        //u.communityNickname = phone;
        //Update(u);
        
        return pageRef;
    } 
}