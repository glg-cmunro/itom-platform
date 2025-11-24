package com.hp.opr.api.ws.adapter;
//import com.hp.opr.api.ws.adapter.ExternalProcessAdapter;

import com.hp.opr.api.ws.adapter.InitArgs;
import com.hp.opr.api.ws.adapter.PingArgs;
import com.hp.opr.api.ws.adapter.ReceiveChangeArgs;
import com.hp.opr.api.ws.adapter.GetExternalEventArgs;
import com.hp.opr.api.ws.adapter.ForwardEventArgs;
import com.hp.opr.api.ws.adapter.ForwardChangeArgs;

import com.hp.opr.api.ws.model.event.OprEvent;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import groovy.json.JsonBuilder;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import java.net.URL;
import java.util.Base64;

//class EventForwarderScript {
class EventForwarderScript implements ExternalProcessAdapter {
    private static final Log e_log = LogFactory.getLog(EventForwarderScript.class.canonicalName);
    private static final String targetContext = "dev/event";
    private String targetUrl; //API Endpoint including PROTOCOL://HOST_FQDN:PORT/CONTEXT
    private String targetHost;
    private String targetPort;
    private String targetProtocol;
    private String targetUser;
    private String targetPass;
    private String encAuthString;

    //def init(def args) {
    void init(InitArgs args) {
        e_log.debug("Event Forward Script - init");
        e_log.info("ARGS: ${args}");
        
        //String connectedServer = args.getConnectedServerDisplayName();
        //String connectedServerCert = args.getConnectedServerCertificate();

        //this.targetHost = "gvz679xsmh-vpce-07875b10af3d0925e.execute-api.us-east-1.amazonaws.com";
        this.targetHost = args.getNode();
        if (this.targetHost == null || this.targetHost.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Hostname from Connected Server properties");
            throw new IllegalArgumentException("Target Hostname not configured in Connected Server properties.");
        }
        
        //this.targetPort = "443";
        this.targetPort = args.getPort();
        if (this.targetPort == null || this.targetPort.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Port from Connected Server properties");
            throw new IllegalArgumentException("Target Port not configured in Connected Server properties.");
        }
        
        Boolean isSSL = args.isNodeSsl();
        this.targetProtocol = "https";
        if (this.isSSL == null || this.isSSL.isEmpty() || this.isSSL == false ) {
            e_log.fatal("Unable to retrieve Target Protocol from Connected Server properties");
            throw new IllegalArgumentException("Target Protocol not configured in Connected Server properties.");
        }
        
        this.targetUrl = targetProtocol + "://" + targetHost + ":" + targetPort + "/" + targetContext
        //this.targetUrl = "https://gvz679xsmh-vpce-07875b10af3d0925e.execute-api.us-east-1.amazonaws.com/dev/event"
        
        EventForwarderScript.targetUrl = this.targetUrl;
        e_log.info("Event Forward TargetURL: ${EventForwarderScript.targetUrl}");
    }

    //def ping(def args) {
    Boolean ping(PingArgs args) {
        e_log.debug("Event Forward Script - ping");

        this.targetUser = args.credentials?.userName;
        //this.targetUser = "omi-todw-user";
        //this.targetUser = args.getCredentials().getUserName();
        if (this.targetUser == null || this.targetUser.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Username from Connected Server properties");
            throw new IllegalArgumentException("Target UserName not configured in Connected Server properties.");
        }

        this.targetPass = args.credentials?.password;
        //this.targetPass = "338~~da7f6f9d854AD1e64461815c1074a";
        //this.targetPass = args.getCredentials().getPassword();
        if (this.targetPass == null || this.targetPass.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Password from Connected Server properties");
            throw new IllegalArgumentException("Target Password not configured in Connected Server properties.");
        }
        
        private String authString = targetUser + ":" + targetPass;
        this.encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        EventForwarderScript.encAuthString = this.encAuthString;

        e_log.info("Event Forward - Ping - Authorization: Basic ${EventForwarderScript.encAuthString}");

        try {
            URL url = new URL(targetUrl);
            HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
            connection.setDefaultHostnameVerifier(allHostsValid);
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Authorization", "Basic ${encAuthString}");
            int responseCode = connection.getResponseCode();
            return responseCode == HttpsURLConnection.HTTP_OK;
        } catch (Exception e) {
            e_log.error("Event Forward - ping - Failed: " + e.getMessage());
            return false;
        }
    }

    //def forwardEvent(def args) {
    Boolean forwardEvent(final ForwardEventArgs args) {
        e_log.debug("Event Forward - forwardEvent");
        e_log.info("Event Forward - forwardEvent - 'PRE' Authorization: Basic ${EventForwarderScript.encAuthString}");
        
        this.targetUser = args.credentials?.userName;
        //this.targetUser = "omi-todw-user";
        //this.targetUser = args.getCredentials().getUserName();
        if (this.targetUser == null || this.targetUser.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Username from Connected Server properties");
            throw new IllegalArgumentException("Target UserName not configured in Connected Server properties.");
        }

        this.targetPass = args.credentials?.password;
        //this.targetPass = "338~~da7f6f9d854AD1e64461815c1074a";
        //this.targetPass = args.getCredentials().getPassword();
        if (this.targetPass == null || this.targetPass.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Password from Connected Server properties");
            throw new IllegalArgumentException("Target Password not configured in Connected Server properties.");
        }
        
        private String authString = targetUser + ":" + targetPass;
        this.encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        EventForwarderScript.encAuthString = this.encAuthString;

        e_log.info("Event Forward - forwardEvent - Authorization: Basic ${EventForwarderScript.encAuthString}");

        for (OprEvent event : args.getEvent()) {
            e_log.debug("Event Forward Script - forwardEvent - Event ID: ${event.id}");
            try {
                // Construct the JSON payload from the OprEvent object
                def eventPayload = [
                    EventID: event.id,
                    Object: event.object,
                    Title: event.title,
                    Severity: event.severity,
                    Node: event.node.node.primaryDnsName,
                    Application: event.application,
                    Date: event.timeCreated
                ]
                e_log.debug("Event Forward - forwardEvent - eventPayload: ${eventPayload}");

                def eventJson = new JsonBuilder(eventPayload).toString()
                e_log.debug("Event Forward - forwardEvent - eventJson: ${eventJson}");
                
                // Send the JSON payload to the external web service
                URL url = new URL(targetUrl);
                HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
                connection.setDefaultHostnameVerifier(allHostsValid);
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json");
                connection.setRequestProperty("Accept", "application/json");
                connection.setRequestProperty("Authorization", "Basic ${encAuthString}");
                connection.setDoOutput(true);


                connection.getOutputStream().write(eventJson.getBytes("UTF-8"));
                connection.getOutputStream().close();

                String responseMessage = connection.getResponseMessage();
                int responseCode = connection.getResponseCode();
                
                if (responseCode != HttpURLConnection.HTTP_OK && responseCode != HttpURLConnection.HTTP_ACCEPTED) {
                    args.getLogger().error("Failed to forward event ${event.getId()}. HTTP response code: ${responseCode}");
                    
                    //Add failure to forward annotation if Payload sent
                    event.addAnnotation("Event Forward FAILED: EndPoint Response: ${responseMessage}", def author);

                    return false; // Indicate failure for this event
                }
                
                args.getLogger().info("Successfully forwarded event ${event.getId()} to ${targetUrl}");
                                
            } catch (Exception e) {
                e_log.fatal("Event Forward - Error forwarding event ${event.getId()}: " + e.getMessage());

                //Add failure to forward annotation unable to send Payload
                event.addAnnotation("Event Forward FAILED: Payload failed to send: ${e.getMessage()}", def author);

                return false; // Indicate failure for this event
            }
        }
        return true; // All events in the batch were processed successfully
    }
    
    //Boolean receiveChange(final ReceiveChangeArgs args) {
    def receiveChange(def args) {
        e_log.debug("Event Forward Script - receiveChange");
        return true;
    }

    //Boolean forwardChange(final ForwardChangeArgs args) {
    def forwardChange(def args) {
        e_log.debug("Event Forward Script - forwardChange");
        return true;
    }
    
    //Boolean getExternalEvent(final GetExternalEventArgs args) {
    def getExternalEvent(def args) {
        e_log.debug("Event Forward Script - getExternalEvent");
        return false;
    }

    //String toExternalEvent(final OprEvent event) {
    def toExternalEvent(final OprEvent event) {
        e_log.debug("Event Forward Script - toExternalEvent");
        return event.getId();
    }

    //def destroy() {
    void destroy() {
        e_log.debug("Event Forward Script - destroy")
    }

    def HostnameVerifier allHostsValid = new HostnameVerifier() {
        @Override
        public boolean verify(String hostname, SSLSession session) {
            // This is highly insecure and should only be used in specific, controlled testing environments.
            return true;
        }
    };
}

                /* //From def eventForward after URL Connection
                try {
                    OutputStream os = connection.getOutputStream();
                    byte[] input = eventJson.getBytes("utf-8");
                    os.write(input, 0, input.length);
                    os.flush();
                } catch (Exception e) {
                    e_log.error("Error formating EventJSON Payload ${event.getId()}: " + e.getMessage());
                }
                */
