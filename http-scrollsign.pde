import http.*;
import java.util.Map;

final int SERVER_CONTEXT_ADD_MESSAGE = 1;
final int SERVER_CONTEXT_RESET = 2;
final int SERVER_CONTEXT_COLOR = 3;

final int WEBSERVICE_PORT = 8000;
final String JSON_CONTENT_TYPE = "application/json";

String scrollMessage = "";

//Colors
  //250 FF 256
  //210 D7 215
  //0  01   1

final int TULIP_R = 250;
final int TULIP_G = 210;
final int TULIP_B = 0;

int txt_r = TULIP_R, txt_g = TULIP_G, txt_b = TULIP_B;

OPC opc;
PFont f;
PShader blur;

SimpleHTTPServer server;
DynamicResponseHandler responder1, responder2, responder3;

void setup()
{
  size(640, 360, P2D);

  startWebServices();

  // Horizontal blur, from the SepBlur Processing example
  blur = loadShader("blur.glsl");
  blur.set("blurSize", 50);
  blur.set("sigma", 8.0f);
  blur.set("horizontalPass", 1);

  // Connect to the local instance of fcserver. You can change this line to connect to another computer's fcserver
  opc = new OPC(this, "127.0.0.1", 7890);

 // Map one 24-LED ring to the center of the window
 int startHeight = 105;
 int spacingHeight = 20;
  for (int i=0; i<8; i++) {
    opc.ledStrip(i*64, 64, width/2, startHeight + i*spacingHeight, width / 70.0, 0, false);
  }  

  // Create the font
  f = createFont("Futura", 200);
  textFont(f);
}

void scrollMessage(String s, float speed)
{
  int x = int( width + (millis() * -speed) % (textWidth(s) + width) );
  text(s, x, 250);  
}

void draw()
{
  background(0);

  fill(txt_r, txt_g, txt_b);
  scrollMessage(scrollMessage, 0.05);
  
  filter(blur);
}

//------------------------------ web services  -------------------------
void startWebServices() {
  SimpleHTTPServer.setLoggerLevel(java.util.logging.Level.INFO);
  server = new SimpleHTTPServer(this, WEBSERVICE_PORT); //starts service on given port

  responder1 = new DynamicResponseHandler(new TextResponse(SERVER_CONTEXT_ADD_MESSAGE), JSON_CONTENT_TYPE);
  responder2 = new DynamicResponseHandler(new TextResponse(SERVER_CONTEXT_RESET), JSON_CONTENT_TYPE);
  responder3 = new DynamicResponseHandler(new TextResponse(SERVER_CONTEXT_COLOR), JSON_CONTENT_TYPE);
  server.createContext("add", responder1); 
  server.createContext("reset", responder2);
  server.createContext("color", responder3);
 
}

class TextResponse extends ResponseBuilder {
  int type;

  TextResponse(int type) {
    this.type = type;
  }

  public  String getResponse(String requestBody) {
    String output = "";
    String s;
    int r,g,b;
    Map<String, String> queryMap = getQueryMap(); //get parameter map as string pairs
    s = queryMap.getOrDefault("s", "");    
    r = int(queryMap.getOrDefault("r", "-1"));    
    g = int(queryMap.getOrDefault("g", "-1"));    
    b = int(queryMap.getOrDefault("b", "-1"));    
    JSONObject json = new JSONObject();
    switch (type) {
    case SERVER_CONTEXT_ADD_MESSAGE: 
      scrollMessage += s;
      scrollMessage += "     ";
      output = "added";
      break;
    case SERVER_CONTEXT_RESET: 
      scrollMessage = "";
      txt_r = TULIP_R;
      txt_g = TULIP_G;
      txt_b = TULIP_B;
      output = "reset";
      break;
    case SERVER_CONTEXT_COLOR:
      output = "set color: [";
      if (r>=0 && r<=255) { txt_r = r; output+="r"; }
      if (g>=0 && g<=255) { txt_g = g; output+="g"; }
      if (b>=0 && b<=255) { txt_b = b; output+="b"; }
      output+="]";
      break;
    default : 
      output = "Unknown instruction, I'll just ignore you...";
    }
    json.setString("result", output);
    println("responded to webservice request on context [" +type + "] with parameters: " + queryMap);
    println(scrollMessage);
    return json.toString();  //note that javascript may require: return "callback(" + json.toString() + ")"
  }
}
