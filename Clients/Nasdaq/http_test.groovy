import java.util.Base64;
import groovy.json.JsonBuilder;
import java.net.HttpURLConnection;
import java.net.URL;


String authString = "Username:Password";
String encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());

println "Auth String: $encAuthString";

URL url = new URL("https://www.google.com");
HttpURLConnection connection = (HttpURLConnection) url.openConnection();
connection.setRequestMethod("HEAD");
int responseCode = connection.getResponseCode();
println "Response Code: $responseCode";
return responseCode == HttpURLConnection.HTTP_OK;



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