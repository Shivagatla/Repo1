@isTest
private class EMSMyProfileCntrlTest {
	
	@isTest static void test_method_one() {
		EMSMyProfileCntrl cntrl = new EMSMyProfileCntrl();


		System.assert(cntrl.getUser()!=null);
		System.assert(cntrl.getIsEdit()==false);

		cntrl.edit();
		System.assert(cntrl.getIsEdit()==true);
			



	}
	


	
}