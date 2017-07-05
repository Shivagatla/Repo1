public class EMSUtils {

    public static String generateRandomString(Integer len) {
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        return key.substring(0,len);
    }

}