package com.hp.opr.api.ws.adapter;
import com.hp.opr.api.ws.model.event.OprEvent;

//import com.hp.opr.api.ws.adapter.ExternalProcessAdapter;
import com.hp.opr.api.ws.adapter.InitArgs;
import com.hp.opr.api.ws.adapter.PingArgs;
import com.hp.opr.api.ws.adapter.ReceiveChangeArgs;
import com.hp.opr.api.ws.adapter.GetExternalEventArgs;
import com.hp.opr.api.ws.adapter.ForwardEventArgs;
import com.hp.opr.api.ws.adapter.ForwardChangeArgs;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import groovy.json.JsonBuilder;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Base64;

//class EventForwarderScript implements ExternalProcessAdapter {
class EventForwarderScript {

    private static final Log e_log = LogFactory.getLog(EventForwarderScript.class.canonicalName);
    private static final String targetContext = "/bsmc/rest/events/nasdaq_test_json";
    private String targetHost;
    private String targetPort;
    private String targetProtocol;
    private String targetUser;
    private String targetPass;
    private String targetUrl;
    private String encAuthString;

    //void init(InitArgs args) {
    def init(def args) {
        e_log.debug("Event Forward Script - init");
        
        this.targetHost = "us02mgmomidbp03.nasdaq.com";
        //this.targetHost = args.getNode();
        if (this.targetHost == null || this.targetHost.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Hostname from Connected Server properties");
            throw new IllegalArgumentException("Target Hostname not configured in Connected Server properties.");
        }

        this.targetPort = "30005";
        //this.targetPort = args.getPort();
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
    }

    //void destroy() {
    def destroy() {
        s_log.debug("Event Forward Script - destroy")
    }

    //Boolean ping(PingArgs args) {
    def ping(def args) {
        s_log.debug("Event Forward Script - ping");

        this.targetUser = args.credentials?.userName;
        //this.targetUser = args.getCredentials().getUserName;
        if (this.targetUser == null || this.targetUser.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Username from Connected Server properties");
            throw new IllegalArgumentException("Target UserName not configured in Connected Server properties.");
        }

        this.password = args.credentials?.password;
        //this.password = args.getCredentials().getPassword();
        if (this.password == null || this.password.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Password from Connected Server properties");
            throw new IllegalArgumentException("Target Password not configured in Connected Server properties.");
        }
        
        private String authString = username + ":" + password;
        this.encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        
        try {
            URL url = new URL(targetUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("HEAD");
            int responseCode = connection.getResponseCode();
            return responseCode == HttpURLConnection.HTTP_OK;
        } catch (Exception e) {
            e_log.error("Ping failed: " + e.getMessage());
            return false;
        }
    }

    //Boolean forwardEvent(final ForwardEventArgs args) {
    def forwardEvent(def args) {
        s_log.debug("Event Forward Script - forwardEvent");
        for (OprEvent event : args.getEvents()) {
            s_log.debug("Event Forward Script - forwardEvent - Event");
            try {
                // Construct the JSON payload from the OprEvent object
                def eventPayload = [
                    Object: event.getId(),
                    Title: event.getTitle(),
                    Severity: event.getSeverity().name(),
                    Node: event.getNode(),
                    Application: event.getApplication(),
                    //state: event.getState().name(),
                    // Add other relevant event properties
                    //customAttributes: event.getCustomAttributes().collectEntries { it.getName() : it.getValue() }
                    Date: event.getTimeCreated()
                ]

                def eventJson = new JsonBuilder(eventPayload).toString()

                // Send the JSON payload to the external web service
                URL url = new URL(targetUrl);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json");
                connection.setRequestProperty("Authorization", "Basic ${encAuthString}");
                connection.setDoOutput(true);

                connection.getOutputStream().write(eventJson.getBytes("UTF-8"));

                int responseCode = connection.getResponseCode();
                if (responseCode != HttpURLConnection.HTTP_OK && responseCode != HttpURLConnection.HTTP_ACCEPTED) {
                    args.getLogger().error("Failed to forward event ${event.getId()}. HTTP response code: ${responseCode}");
                    return false; // Indicate failure for this event
                }
                args.getLogger().info("Successfully forwarded event ${event.getId()} to ${targetUrl}");
            } catch (Exception e) {
                e_log.fatal("Error forwarding event ${event.getId()}: " + e.getMessage());
                return false; // Indicate failure for this event
            }
        }
        return true; // All events in the batch were processed successfully
    }
    
    //Boolean receiveChange(final ReceiveChangeArgs args) {
    def receiveChange(def args) {
        s_log.debug("Event Forward Script - receiveChange");
        return true;
    }

    //Boolean forwardChange(final ForwardChangeArgs args) {
    def forwardChange(def args) {
        s_log.debug("Event Forward Script - forwardChange");
        return true;
    }
    
    //Boolean getExternalEvent(final GetExternalEventArgs args) {
    def getExternalEvent(def args) {
        s_log.debug("Event Forward Script - getExternalEvent");
        return false;
    }

    //String toExternalEvent(final OprEvent event) {
    def toExternalEvent(final OprEvent event) {
        s_log.debug("Event Forward Script - toExternalEvent");
        return event.getId();
    }
}
