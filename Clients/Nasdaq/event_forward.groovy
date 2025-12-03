package com.hp.opr.api.ws.adapter;
import com.hp.opr.api.scripting.Event;
//import com.hp.opr.api.ws.adapter.ExternalProcessAdapter;
import com.hp.opr.api.ws.adapter.ForwardChangeArgs;
import com.hp.opr.api.ws.adapter.ForwardEventArgs;
import com.hp.opr.api.ws.adapter.GetExternalEventArgs;
import com.hp.opr.api.ws.adapter.InitArgs;
import com.hp.opr.api.ws.adapter.PingArgs;
import com.hp.opr.api.ws.adapter.ReceiveChangeArgs;
import com.hp.opr.api.ws.model.event.OprAnnotation;
import com.hp.opr.api.ws.model.event.OprAnnotationList;
import com.hp.opr.api.ws.model.event.OprEvent;
import groovy.json.JsonBuilder;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import java.net.URL;
import java.util.Base64;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

//class EventForwarderScript implements ExternalProcessAdapter {
class EventForwarderScript {
    
    private static final Log e_log = LogFactory.getLog(EventForwarderScript.class.canonicalName);
    private static final String targetContext = "dev/event";
    private String targetUrl; //API Endpoint including PROTOCOL://HOST_FQDN:PORT/CONTEXT
    private String targetHost;
    private String targetPort;
    private String targetProtocol;
    private String targetUser;
    private String targetPass;
    private String encAuthString;
    
    //void init(InitArgs args) {
    def init(def args) {
        e_log.info("Event Forward Script - init");
        
        e_log.debug("Event Forward - init - ARGS: ${args}");
        String connectedServer = args.getConnectedServerDisplayName();
        String connectedServerCert = args.getConnectedServerCertificate();
        String connectedServerId = args.getConnectedServerId();
        String connectedServerName = args.getConnectedServerName();
        String connectedServerFQDN = args.getForwardingServerFqdn();
        e_log.info("Connected Server Details - Id: ${connectedServerId}");
        e_log.info("Connected Server Details - Label: ${connectedServer}");
        e_log.info("Connected Server Details - Name: ${connectedServerName}");
        e_log.info("Connected Server Details - FQDN: ${connectedServerFQDN}");
        
        this.targetHost = args.getNode();
        if (this.targetHost == null || this.targetHost.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Hostname from Connected Server properties");
            throw new IllegalArgumentException("Unable to retrieve Target Hostname from Connected Server properties.");
        }
        
        this.targetPort = args.getPort();
        if (this.targetPort == null || this.targetPort.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Port from Connected Server properties");
            throw new IllegalArgumentException("Unable to retrieve Target Port from Connected Server properties.");
        }
        
        this.targetProtocol = "https";
        //Boolean isSSL = args.isNodeSsl();
        //if (this.isSSL == null || this.isSSL.isEmpty() || this.isSSL == false ) {
        //    e_log.fatal("Unable to retrieve Target Protocol from Connected Server properties");
        //    throw new IllegalArgumentException("Target Protocol not configured in Connected Server properties.");
        //}
        
        this.targetUrl = "${targetProtocol}://${targetHost}:${targetPort}/${targetContext}";
        //this.targetUrl = "https://gvz679xsmh-vpce-07875b10af3d0925e.execute-api.us-east-1.amazonaws.com/dev/event"
        
        e_log.info("Event Forward - init - TargetURL: ${targetUrl}");
    }
    
    //Boolean ping(PingArgs args) {
    def ping(def args) {
        e_log.info("Event Forward Script - ping");
        
        this.targetUser = args.credentials?.userName;
        if (this.targetUser == null || this.targetUser.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Username from Connected Server properties");
            throw new IllegalArgumentException("Unable to retrieve Target Username from Connected Server properties.");
        }
        
        this.targetPass = "338~~da7f6f9d854AD1e64461815c1074a";
        //this.targetPass = args.credentials?.password;
        //if (this.targetPass == null || this.targetPass.isEmpty()) {
        //    e_log.fatal("Unable to retrieve Target Password from Connected Server properties");
        //    throw new IllegalArgumentException("Unable to retrieve Target Password from Connected Server properties.");
        //}
        e_log("Event Forward Script - ping - credentails: ${args.credentials.getPassword()}");
        
        String authString = targetUser + ":" + targetPass;
        this.encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        
        EventForwarderScript.encAuthString = this.encAuthString;
        e_log.info("Event Forward - ping - Authorization: Basic ${EventForwarderScript.encAuthString}");
        
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
        
        return true;
    }
    
    //Boolean forwardEvent(final ForwardEventArgs args) {
    def forwardEvent(def args) {
        e_log.info("Event Forward Script - forwardEvent");
        
        this.targetUser = args.credentials?.userName;
        if (this.targetUser == null || this.targetUser.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Username from Connected Server properties");
            throw new IllegalArgumentException("Target UserName not configured in Connected Server properties.");
        }
        
        this.targetPass = "338~~da7f6f9d854AD1e64461815c1074a";
        //this.targetPass = args.credentials?.password;
        if (this.targetPass == null || this.targetPass.isEmpty()) {
            e_log.fatal("Unable to retrieve Target Password from Connected Server properties");
            throw new IllegalArgumentException("Target Password not configured in Connected Server properties.");
        }
        
        String authString = targetUser + ":" + targetPass;
        this.encAuthString = Base64.getEncoder().encodeToString(authString.getBytes());
        
        e_log.info("Event Forward - forwardEvent - Authorization: Basic ${EventForwarderScript.encAuthString}");
        
        for (OprEvent event : args.getEvent()) {
            e_log.debug("Event Forward - forwardEvent - Event ID: ${event.id}");
            
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
                connection.setRequestProperty("Authorization", "Basic ${encAuthString}");
                connection.setDoOutput(true);
                
                connection.getOutputStream().write(eventJson.getBytes("UTF-8"));
                //connection.getOutputStream().close();
                
                String responseMessage = connection.getResponseMessage();
                e_log.info("Event Forward - forwardEvent - HTTP Response Message: ${responseMessage}");
                
                int responseCode = connection.getResponseCode();
                e_log.info("Event Forward - forwardEvent - HTTP Response Code: ${responseCode}");

                if (responseCode != HttpURLConnection.HTTP_OK && responseCode != HttpURLConnection.HTTP_ACCEPTED) {
                    e_log.error("Event Forward FAILED for EventID ${event.getId()}. HTTP response code: ${responseCode}");
                    
                    //Add failure to forward annotation if Payload sent
                    try {
                        OprEvent update = annotateEvent(event, "Event Forward FAILED: EndPoint Response Code: ${responseCode} :: Message: ${responseMessage}");
                        args.submitChanges(update);
                    } catch (Exception updateE) {
                        e_log.fatal("Event Forward Script - forwardEvent - Update Annotation Failed: ${event.id} - ${updateE.getMessage()}");
                    }
                    return false; // Indicate failure for this event
                }
                
                e_log.info("Event Forward Successful for event: ${event.id}");
                
                //Add failure to forward annotation if Payload sent
                try {
                    OprEvent update = annotateEvent(event, "Event Forward SUCCESS: EndPoint Response Code: ${responseCode} :: Message: ${responseMessage}");
                    args.submitChanges(update);
                } catch (Exception updateE) {
                    e_log.fatal("Event Forward Script - forwardEvent - Update Annotation Failed: ${event.id} - ${updateE.getMessage()}");
                }
                
            } catch (Exception e) {
                e_log.fatal("Event Forward - Error forwarding event ${event.getId()}: " + e.getMessage());
                
                //Add failure to forward annotation unable to send Payload
                try {
                    OprEvent update = annotateEvent(event, "Event Forward FAILED: Payload failed to send: ${e.getMessage()}");
                    args.submitChanges(update);
                } catch (Exception updateE) {
                    e_log("Event Forward Script - forwardEvent - Update Annotation Failed: ${event.id} - ${updateE.getMessage()}");
                }
                
                return false; // Indicate failure for this event
            }
        }
        
        e_log.info("Event Forward Successful for ALL Events");
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
    
    //void destroy() {
    def destroy() {
        e_log.debug("Event Forward Script - destroy");
    }
    
    def annotateEvent(OprEvent event, String msg) {
        e_log.info("Event Forward Script - annotateEvent");
        
        //Get current Annotations
        OprAnnotationList annotationList = event.getAnnotations();
        if (annotationList == null) {
            e_log.fatal("Event Annotations: Currently NULL");
            annotationList = new OprAnnotationList();
            event.setAnnotations(annotationList);
        }
        List<OprAnnotation> annoList = annotationList.getAnnotations();
        if (annoList == null) {
            e_log.fatal("Event Annotation List: Currently NULL");
            annoList = new ArrayList<OprAnnotation>();
            annotationList.setAnnoatations(annoList);
        }
        OprAnnotation annotation = new OprAnnotation();
        annotation.setAuthor("testuser_techops");
        annotation.setText(msg);
        annotation.setTimeCreated(new Date());
        annoList.add(annotation);
        annotationList.setAnnotations(annoList);
        
        return event;
    }
    
    def HostnameVerifier allHostsValid = new HostnameVerifier() {
        @Override
        public boolean verify(String hostname, SSLSession session) {
            // This is highly insecure and should only be used in specific, controlled testing environments.
            return true;
        }
    };
}
