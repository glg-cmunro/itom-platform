import java.util.List;
import java.lang.StringBuffer;
import com.hp.opr.api.scripting.Event;
import java.net.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import com.hp.opr.api.ws.model.event.OprEvent
import com.hp.opr.api.ws.model.event.OprEventChange
import com.hp.opr.api.ws.model.event.OprEventList
import com.hp.opr.api.ws.model.event.OprGroup
import com.hp.opr.api.ws.model.event.OprPriority
import com.hp.opr.api.ws.model.event.OprSeverity
import com.hp.opr.api.ws.model.event.OprState
import com.hp.opr.api.ws.model.event.OprUser
import com.hp.opr.api.ws.model.event.ci.OprConfigurationItem
import com.hp.opr.api.ws.model.event.ci.OprForwardingInfo
import com.hp.opr.api.ws.model.event.OprAnnotationList
import com.hp.opr.api.ws.model.event.OprAnnotation

class TeamsConnector
{
               private static final Log s_log = LogFactory.getLog(TeamsConnector.class.canonicalName);
               
               private final String TeamsWebhookURL = “<YOUR TEAMS WEBHOOK>”;
               
               private static final int OK = 200;
               // server response if Downtime wasn't created
               private static final int BAD_REQUEST = 400;
               // server response if Downtime wasn't created
               private static final int INTERNAL_SERVER_ERROR = 500;
               
               private static final String PROXY_SERVER = "<SOME_PROXY>";
               private static final int PROXY_PORT = 8080;
               private static final boolean USE_PROXY = true;
               
  def init(def args)
  {
                 s_log.fatal("init TeamsConnector was invoked");
  }

  def destroy()
  {
  }
  
  def ping(def args)
  {
    args.outputDetail = "Success."
    return true
  }

               def forwardEvent(def args)
    {
    try
    {    
                 OprEvent event = args.getEvent(args.event.id, false)
      //event.setTitle("Modified by CA/EPI: " + event.getTitle())
                              
                              if (sendToTeams(event))
                                             args.externalRefId = event.id;
                              
/*                           s_log.fatal("trying to add annotation");
                              OprEvent update = args.getEvent(args.event.id, true)

                              OprAnnotationList annotationList = update.getAnnotations();
                              if (annotationList == null) {
                                             annotationList = new OprAnnotationList();
                                             s_log.fatal("OprAnnotationList was NULL")
                                             update.setAnnotations(annotationList);
                              }
                              List<OprAnnotation> annoList = annotationList.getAnnotations();
                              if (annoList == null) {
                                             annoList = new ArrayList<OprAnnotation>();
                                             s_log.fatal("annoList was NULL");
                                             annotationList.setAnnotations(annoList);
                              }
                              s_log.fatal("Creating annotation");
                              OprAnnotation annotation = new OprAnnotation();
                              annotation.setAuthor("Asaf");
                              annotation.setText("This is custom annotation");
                              annotation.setTimeCreated(new Date());
                              annoList.add(annotation);
                              annotationList.setAnnotations(annoList);

                              s_log.fatal("Going to submit changes");
        args.submitChanges(update)
*/                           
      return true;
      
    }
    catch(InterruptedException e)
    {
      return
    }
  }
  
  def forwardEvents(def args)
  {
                 OprEventList events = args.events

    for (OprEvent event in events.eventList)
    {
                              event.setTitle("Modified by CA/EPI: " + event.getTitle())
                              if (sendToTeams(event))
                                             args.setForwardSuccess(event.id, event.id, null);
               }
               return true;
  }
  
  def forwardChange(def args)
  {
    
    return true
  }

  def forwardChanges(def args)
  {
                 return true
  }
  
  private boolean sendToTeams(OprEvent event) {
                 // preparing request URL
                              URL url = new URL(TeamsWebhookURL);
                              Proxy proxy = null;
                              if (USE_PROXY)
                                             proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(PROXY_SERVER, PROXY_PORT));
                              
                              s_log.fatal("-------------- the URL: " + url);                           
                   
                   // connecting to Teams Webhook via URL
                   HttpURLConnection connection = null;
                              if (USE_PROXY)
                                             connection = (HttpURLConnection)url.openConnection(proxy);
                              else
                                             connection = (HttpURLConnection)url.openConnection();
                              
                   // Setting request type
                   connection.setRequestMethod("POST");
                   // a URL connection can be used for input and/or output. Set the DoOutput flag to true if you intend to use the URL connection for output.
                   connection.setDoOutput(true);
                   // set content type parameter
                   connection.setRequestProperty("Content-Type", "applicaiton/json; charset=utf-8");              
                              // get JSON from event
                              String json = createJSONFromEvent(event);
                   // write request body JSON
                              if (json != null) {
                                             s_log.fatal("JSON=" + json);
                                             // get connection output
                                             OutputStream outputStream = connection.getOutputStream();
                                             outputStream.write(json.getBytes());
                                             outputStream.flush();
                              }
                   // show request result status
                              switch(connection.getResponseCode()){
                              case OK: s_log.fatal("\nRequest was successfully perfomed\n");
                                             // print the newly created Downtime in XML format
                                             /*if (readResult) {
                                                                           DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                                                                           DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                                                                           resultDoc = dBuilder.parse(connection.getInputStream());
                                                            }
                                                            */
                                             return true;
                              case BAD_REQUEST: s_log.error("\nRequest wasn't perfomed due to incorrect or malformed URL\n");
                                             return false;
                              case INTERNAL_SERVER_ERROR:         s_log.error("\nRequest wasn't perfomed due to internal server error\n");
                                             return false;
                              default: s_log.error("\nRequest wasn't perfomed\n");
                                             return false;
                   }
                   // close connection
                   connection.disconnect();          
  }
  
  private String createJSONFromEvent(OprEvent event) {
                 StringBuffer sb = new StringBuffer();
                 sb.append("{\n");
                              sb.append("\"text\": \"<h1 style='background-color:yellow'>This is test from OBM<br>If you are able to see this, then my test is working.<br>Event title=" + event.title + "<br>Event severity=<span style='color:red'>" + event.severity + "</span><br>Click <a href='https://<OBM URL>/opr-web/eventDetails/app?eventId=" + event.id + "&mode=popup#/'>here</a> to see event details.</h1>\",\n");

                 sb.append("}")
                 return sb.toString();
  }
}


