package com.hp.opr.api.ws.adapter;

import com.hp.opr.api.ws.model.event.OprEvent;
import com.hp.opr.api.ws.adapter.ExternalProcessAdapter;
import com.hp.opr.api.ws.adapter.InitArgs;
import com.hp.opr.api.ws.adapter.PingArgs;
import com.hp.opr.api.ws.adapter.ReceiveChangeArgs;
import com.hp.opr.api.ws.adapter.GetExternalEventArgs;
import com.hp.opr.api.ws.adapter.ForwardEventArgs;
import com.hp.opr.api.ws.adapter.ForwardChangeArgs;

import groovy.json.JsonBuilder;
import java.net.HttpURLConnection;
import java.net.URL;

class EventForwarderScript implements ExternalProcessAdapter {

    private String targetUrl;
    private String username;
    private String password;

    void init(final InitArgs args) {
        // Initialize script parameters, e.g., the target URL from Connected Server properties
        this.targetUrl = args.getProperty("targetUrl"); // Define 'targetUrl' in Connected Server
        if (this.targetUrl == null || this.targetUrl.isEmpty()) {
            throw new IllegalArgumentException("Target URL not configured in Connected Server properties.");
        }
        // Need to get Username/Password for Basic Auth and establish encodedAuthString for Authorization
        this.username = args.getProperty("username");
        if (this.username == null || this.username.isEmpty()) {
            throw new IllegalArgumentException("Target UserName not configured in Connected Server properties.");
        }
        this.password = args.getProperty("password");
        if (this.password == null || this.password.isEmpty()) {
            throw new IllegalArgumentException("Target Password not configured in Connected Server properties.");
        }
        
        String authString = username + ":" + password;
        String encodedAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        
        /*
        String username = "your_username";
        String password = "your_password";
        
        // Encode username and password in Base64
        String authString = username + ":" + password;
        String encodedAuthString = Base64.getEncoder().encodeToString(authString.getBytes());

        // Later - Set the Authorization header for Basic Authentication
        connection.setRequestProperty("Authorization", "Basic " + encodedAuthString);
        */
    }

    void destroy() {
        // Clean up resources if necessary
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

    Boolean receiveChange(final ReceiveChangeArgs args) {
        // Handle event changes received from the external system if synchronization is enabled
        return true;
    }

    Boolean getExternalEvent(final GetExternalEventArgs args) {
        // Retrieve external event details if needed for synchronization
        return false;
    }

    Boolean forwardEvents(final ForwardEventArgs args) {
        for (OprEvent event : args.getEvents()) {
            try {
                // Construct the JSON payload from the OprEvent object
                def eventPayload = [
                    Object: event.getId(),
                    Title: event.getTitle(),
                    Severity: event.getSeverity().name(),
                    Node: event.getNode(),
                    Application: event.application,
                    Date: event.timeCreated
                    //state: event.getState().name(),
                    // Add other relevant event properties
                    //customAttributes: event.getCustomAttributes().collectEntries { it.getName() : it.getValue() }
                ]

                def json = new JsonBuilder(eventPayload).toString()

                // Send the JSON payload to the external web service
                URL url = new URL(targetUrl);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json");
                connection.setRequestProperty("Authorization", "Basic " + encodedAuthString);
                connection.setDoOutput(true);

                connection.getOutputStream().write(json.getBytes("UTF-8"));

                int responseCode = connection.getResponseCode();
                if (responseCode != HttpURLConnection.HTTP_OK && responseCode != HttpURLConnection.HTTP_ACCEPTED) {
                    args.getLogger().error("Failed to forward event ${event.getId()}. HTTP response code: ${responseCode}");
                    return false; // Indicate failure for this event
                }
                args.getLogger().info("Successfully forwarded event ${event.getId()} to ${targetUrl}");
            } catch (Exception e) {
                args.getLogger().error("Error forwarding event ${event.getId()}: " + e.getMessage());
                return false; // Indicate failure for this event
            }
        }
        return true; // All events in the batch were processed successfully
    }

    Boolean forwardChanges(final ForwardChangeArgs args) {
        // Handle forwarding of event changes if synchronization is enabled
        return true;
    }

    String toExternalEvent(final OprEvent event) {
        // Convert OBM event to an external event representation if needed
        return event.getId();
    }
}

 