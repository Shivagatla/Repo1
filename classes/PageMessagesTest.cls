@isTest
private class PageMessagesTest {
    
    @isTest 
    static void testStandardUse() {
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.FATAL,'Test Message'));
        System.assertEquals(1,PageMessages.getMessages().size());
    }

    @isTest 
    static void testFailDueToPageMessageInstantiation() {
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.FATAL,'Test Message'));
        System.assertEquals(1,PageMessages.getMessages().size());

        try {
            PageMessages instantiated = new PageMessages();
            System.assert(false);
        }
        catch (UnsupportedOperationException e) {
            //Correct behaviour
        }
    }

    @isTest 
    static void testController() {
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.FATAL,'Test Message'));
        System.assertEquals(1,PageMessages.getMessages().size());

        Controller_PageMessages controller = new Controller_PageMessages(); 

        System.assertEquals('',controller.CustomPageMessages_ClosableErrorsRenderPlaceHolder);
        System.assertEquals(1,controller.getPageMessages().size());
    }
}