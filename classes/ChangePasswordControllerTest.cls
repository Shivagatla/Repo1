/**
 * An apex page controller that exposes the change password functionality
 */
@IsTest public with sharing class ChangePasswordControllerTest {
   	@IsTest(SeeAllData=true) public static void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
       Test.setMock(HttpCalloutMock.class, new ChangePasswordControllerTest.MockHttpResponseGenerator());

        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';
        Test.startTest();
        PageReference fp = controller.changePassword();
        Test.stopTest();
        System.assertEquals(fp,null);                           
    }

      class MockHttpResponseGenerator implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint and method.
            System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
        
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
            return res;
        }
    }
}