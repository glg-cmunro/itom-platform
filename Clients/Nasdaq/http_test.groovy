//import org.apache.commons.logging.Log;
//import org.apache.commons.logging.LogFactory;

import java.util.Base64;
import groovy.json.JsonBuilder;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import java.net.URL;

println "Java Home (java.home): ${System.getProperty('java.home')}"

String authString = "Username:Password";
String encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());

HostnameVerifier allHostsValid = new HostnameVerifier() {
    @Override
    public boolean verify(String hostname, SSLSession session) {
        // This is highly insecure and should only be used in specific, controlled testing environments.
        return true;
    }
};

println "Auth String: $encAuthString";

URL url = new URL("https://tkcloudkey.TK.int.jcthepcguy.com");
HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);
HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
connection.setRequestMethod("HEAD");
connection.setDoOutput(true);

println connection.getHostnameVerifier();
int responseCode = connection.getResponseCode();
println "Response Code: $responseCode";
String responseMessage = connection.getResponseMessage();
println "Response Message: $responseMessage";

DataOutputStream out = connection.getOutputStream();
println out;
return responseCode == HttpsURLConnection.HTTP_OK;



/*
class httpForwarder {

    private String targetUrl;
    private String encodedAuthString;

    void init(final InitArgs args) {
        private String user;
        private String pass;
        private String authString = user + ":" pass
        this.encodedAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
    }

    void destroy() {

    }
    
    Boolean ping(final PingArgs args) {
        // Implement a ping to the external service to check connectivity
        try {
            URL url = new URL(targetUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("HEAD");
            int responseCode = connection.getResponseCode();
            return responseCode == HttpURLConnection.HTTP_OK;
        } catch (Exception e) {
            args.getLogger().error("Ping failed: " + e.getMessage());
            return false;
        }
    }
}
*/