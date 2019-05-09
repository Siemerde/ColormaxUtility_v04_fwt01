// READ ME
// This version of ColormaxUtility_v04 is for firmware testing - namely V011-48 (and, if need be, V011-046 and V011-047) for the GYB Colormax

// Need G4P library
import g4p_controls.*;
import java.awt.Toolkit;

// Variables for finding connected colormaxes
// We MUST define how big these arrays are, even if
// the number of connected colormaxes is variable.. so
// we're just gonna make 100 slots, then check for nulls.
final int slots = 100;
boolean colormaxFoundMap[] = new boolean[slots];
Serial ports[] = new Serial[slots];
Serial colormaxPorts[] = new Serial[slots];
String colormaxPortsDroplistStrings[] = new String[slots];
boolean populatingColormaxes = false;

// Colormax serial settings
static int cmaxBaudRate = 115200;
char cmaxParity = 'E';
int cmaxDataBits = 7;
float cmaxStopBits = 1.;

// Alignment table directory
static String alignmentTableDirectory = "//Diskstation/engineering/EMX_Automation/ColorMax - Biotech/Production Notes/MASTER CALIBRATION/COLOR TARGETS.txt";

Colormax colormaxes[] = new Colormax[100];
GOption[] colorOptions = new GOption[12];

//****************************************************************************************************
// Setup
//****************************************************************************************************v
public void setup() {
  size(1024, 576, JAVA2D);
  createGUI();
  customGUI();

  // Place your setup code here
  int i = 0;
  for (i = 0; i < colormaxes.length; i++) {
    colormaxes[i] = new Colormax("colormax" + i);
  }

  colorOptions[0] = optnColorOne;
  colorOptions[1] = optnColorTwo;
  colorOptions[2] = optnColorThree;
  colorOptions[3] = optnColorFour;
  colorOptions[4] = optnColorFive;
  colorOptions[5] = optnColorSix;
  colorOptions[6] = optnColorSeven;
  colorOptions[7] = optnColorEight;
  colorOptions[8] = optnColorNine;
  colorOptions[9] = optnColorTen;
  colorOptions[10] = optnColorEleven;
  colorOptions[11] = optnColorTwelve;  

  populateColormaxes();
  updateColormaxInfo(colormaxes[listColormaxSelect.getSelectedIndex()]);
}

//****************************************************************************************************
// Draw
//****************************************************************************************************

public void draw() {
  background(230);
}

//****************************************************************************************************
//  Methods
//****************************************************************************************************

// Set boolean array **************************************************
void setBooleanArray(boolean[] inputArray, boolean set) {
  for (int i = 0; i < inputArray.length; i++) {
    colormaxFoundMap[i] = set;
  }
}

// Nullify String arrays **************************************************
void nullifyStringArray(String[] inputArray) {
  for (int i = 0; i < inputArray.length; i++ ) {
    inputArray[i] = null;
  }
}

// colormaxPorts Reset **************************************************
void colormaxPortsReset() {
  int i = 0;
  for (i = 0; i < colormaxes.length; i++) {
    colormaxes[i].endSerial();
  }

  //for(i = 0 ; i < colormaxPorts.length ; i++){
  //  if(colormaxPorts[i] != null){
  //    colormaxPorts[i].clear();
  //    colormaxPorts[i].stop();
  //    colormaxPorts[i] = null;
  //  }
  //}
}

// Update the droplist **************************************************
void updateColormaxDroplist() {
  int i = 0;

  // Clear colormax Droplist
  for (i = 0; i < slots; i++) {
    listColormaxSelect.removeItem(i);
  }

  // Check if we even have colormaxes connected
  // If we do, EZ Clap
  if (colormaxPortsDroplistStrings[0] != null) {
    listColormaxSelect.setItems(colormaxPortsDroplistStrings, 0);
  }
  // If we don't, display a message
  else {
    listColormaxSelect.setItems(new String[] {"No Colormaxes Available"}, 0);
  }
}

// Populate Colormaxes **************************************************
void populateColormaxes() {
  int i = 0;
  int j = 0;
  int responseTimeout = 500;
  populatingColormaxes = true;

  //debugging
  //println("resetting stuff");

  // Reset some stuff
  setBooleanArray(colormaxFoundMap, false);
  colormaxPortsReset();
  nullifyStringArray(colormaxPortsDroplistStrings);

  //debugging
  //println("starting population");

  // Populate ports[] with all current serial ports
  // initialize with colormax settings
  for (i = 0; i < Serial.list().length; i++) {
    try {
      ports[i] = new Serial(this, Serial.list()[i], cmaxBaudRate, cmaxParity, cmaxDataBits, cmaxStopBits);
      ports[i].bufferUntil(13);
    }
    catch(Exception e) {
      println(e);
    }
  }

  // Send a value over every connected serial port 
  // and wait for a colormax response (handled in serialEvent())
  // If we don't get a response within the timeout period
  // then we assume there's no colormax and move on
  for (i = 0; i < Serial.list().length; i++) {
    if (ports[i] != null) {
      ports[i].write(13);
      int startMillis = millis();
      while (!colormaxFoundMap[i]) {
        delay(1); // we need to slow the program down for some reason.. leave this here
        if (millis() - startMillis > responseTimeout) {
          println("@@@@@@@@@@", ports[i].port.getPortName(), "response timeout @@@@@@@@@@");
          break;
        }
      }
    }
  }

  // Initialize colormaxPorts[], then populate it
  // with ports that we know have colormaxes attached
  for (i = 0; i < ports.length; i++) {
    if (colormaxFoundMap[i] == true
      && ports[i] != null) {
      colormaxPortsDroplistStrings[j] = ports[i].port.getPortName();
      colormaxes[j].setSerial(ports[i]);
      colormaxPorts[j] = ports[i];
      j++;
    }  
    // If there's no colormax on that port, close it
    // and return that slot to null
    else if (ports[i] != null) {
      ports[i].clear();
      ports[i].stop();
      ports[i] = null;
    }
  }

  // Last thing to do is update the droplist
  updateColormaxDroplist();
  //println("colormaxes populated");
  populatingColormaxes = false;
  return;
}

// Update Colormax Info **************************************************
void updateColormaxInfo(Colormax inColormax) {
  if (inColormax.getSerial() != null) {
    final int commandDelay = 25;
    
    // Each command needs a short delay (at least 25ms) to get a response.
    // And I'm too dumb to figure out how to make an array of methods to call with a for(){} loop
    // No need for so many lines of code, so I've put the delay in-line with each method call
    // like so: inColormax.readCLT();delay(commandDelay);
    inColormax.readData();delay(commandDelay);
    inColormax.readTemperature();delay(commandDelay);
    inColormax.readIlluminationAlgorithm();delay(commandDelay);
    inColormax.readSettings();delay(commandDelay);
    inColormax.readIdentity();delay(commandDelay);
    inColormax.readVersion();delay(commandDelay);
    inColormax.readIlluminationFactor();delay(commandDelay);
    
    lblRedPercentData.setText(String.format("%.2f", inColormax.getRedPercent() - 0.005));
    lblGreenPercentData.setText(String.format("%.2f", inColormax.getGreenPercent() - 0.005));
    lblBluePercentData.setText(String.format("%.2f", inColormax.getBluePercent() - 0.005));
    lblRedHexData.setText(String.valueOf(inColormax.getRed()));
    lblGreenHexData.setText(String.valueOf(inColormax.getGreen()));
    lblBlueHexData.setText(String.valueOf(inColormax.getBlue()));
    lblTemperatureData.setText(String.format("%.2f", inColormax.getTemperature() - 0.005));
    ////lblLEDCurrentData.setText(inColormax.getLedMa());
    lblLEDCurrentData.setText(String.format("%.2f", inColormax.getLedMaFloat() - 0.005));
    lblDACSettingData.setText(inColormax.getLedDac());
    lblLedStabilityData.setText(inColormax.getLedStability());
    lblAveragingData.setText(inColormax.getAveraging());
    lblTriggeringData.setText(inColormax.getTriggering());
    lblOutputDelayData.setText(inColormax.getOutputDelay());
    lblIlluminationData.setText(String.valueOf(inColormax.getIllumination()));
    lblModelData.setText(inColormax.getModel());
    lblFirmwareVersionData.setText(inColormax.getVersion());
    lblSerialNumberData.setText(inColormax.getSerialNumber());
  } else {
    println("no colormax, UwU");
  }
}

// Align Colors **************************************************
void alignColor(final Colormax inColormax) {
  final int wait = 60000;
  Timer alignTimer = new Timer();

  // Check if the colormax is already busy or not
  if(inColormax.getStatus() != "idle"){
    println("@@@@@@@@@@ CANNOT CALIBRATE COLOR, COLORMAX IS BUSY @@@@@@@@@@");
    return;
  }
  
  // Change the button to yellow
  // Verify temp table is on, cuz we need that
  // Verify the Colormax is in AlmProcs (commented out for now, as this is verified when the timertask runs)
  btnCalibrateColor.setLocalColorScheme(GCScheme.YELLOW_SCHEME);
  inColormax.writeTempOn();
  //inColormax.writeStartAlign();
  inColormax.setStatus(inColormax.calibrating);
  
  // This will run after the timer expires
  alignTimer.schedule(new TimerTask() {
    public void run() {
      // Verify Colormax is in AlmProcs
      // 100ms delay to make sure colormax get sthe command
      // Tell colormax to take readings
      inColormax.writeStartAlign();
      delay(100);
      inColormax.writeAlignColor();
      inColormax.setStatus(inColormax.idle);
      
      // Move the radio selection for the user
      for (int i = 0; i < colorOptions.length; i++) {
        if (colorOptions[i].isSelected()) {
          try {
            colorOptions[++i].setSelected(true);
          }
          catch(ArrayIndexOutOfBoundsException e) {
            colorOptions[0].setSelected(true);
          }
          btnCalibrateColor.setLocalColorScheme(GCScheme.CYAN_SCHEME);
          
          if(chkBeepOnRead.isSelected()){
            Toolkit.getDefaultToolkit().beep();
          }
          
          break;
        }
      }
    }
  }
  // Set when the timer will go off
  , (long)(wait) );
}

// Align Colors **************************************************
void retakeRead(final Colormax inColormax, final int colorIndex) {
  final int wait = 60000;
  Timer retakeTimer = new Timer();

  // Check if the colormax is already busy or not
  if(inColormax.getStatus() != "idle"){
    println("@@@@@@@@@@ CANNOT RETAKE POINT COLOR, COLORMAX IS BUSY @@@@@@@@@@");
    return;
  }

  // Change the button to yellow
  // Verify temp table is on, cuz we need that
  // Verify the Colormax is in AlmProcs (commented out for now, as this is verified when the timertask runs)
  btnRetakePoint.setLocalColorScheme(GCScheme.YELLOW_SCHEME);
  inColormax.writeTempOn();
  //inColormax.writeStartAlign();
  inColormax.setStatus(inColormax.retakingPoint);
  
  // This will run after the timer expires
  retakeTimer.schedule(new TimerTask() {
    public void run() {
      // Tell colormax to take readings
      inColormax.writeRetakeRead(colorIndex);
      inColormax.setStatus(inColormax.retakingPoint);
      btnRetakePoint.setLocalColorScheme(GCScheme.CYAN_SCHEME);
      inColormax.setStatus(inColormax.idle);
      
      if(chkBeepOnRead.isSelected()){
        Toolkit.getDefaultToolkit().beep();
      }
    }
  }
  // Set when the timer will go off
  , (long)(wait) );
}

// Test Bit
// for checking bit flags
boolean testBit(int inInt, int bit) {
  if ((inInt & (0x01 << bit)) != 0) {
    return true;
  } else {
    return false;
  }
}

boolean continuePopup(String message) {


  return false;
}

void fwtTestAllCommands(Colormax inColormax){
  final int commandDelay = 100;
  
  println("commence command cesting");
  
  inColormax.writeIlluminationFactor("AAA");  // ?
  println("?");
  delay(commandDelay);
  inColormax.writeIlluminationFactor("233");  // !A
  println("!A");
  delay(commandDelay);
  inColormax.readIlluminationFactor();        // !a,233
  println("!a,233");
  delay(commandDelay);
  inColormax.writeIlluminationFactor("3E8");  // !A
  println("!A");
  delay(commandDelay);
  inColormax.readIlluminationFactor();        // !a,3E8
  println("!a,3E8");
  delay(commandDelay);
  inColormax.serial.write("!C,0,1,1,1,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF\r");  // ?
  println("?");
  delay(commandDelay);
  inColormax.serial.write("!C,0,1,1,1,1111,1111,1111,1111,1111,1111\r");  // !C
  println("!C");
  delay(commandDelay);
  inColormax.serial.write("!c,0\r");          // !c,0,1,1,1,1111,1111,1111,1111,1111,1111
  println("!c,0,1,1,1,1111,1111,1111,1111,1111,1111");
  delay(commandDelay);
  inColormax.readData();                      // !d,etc..
  println("!d,...");
  delay(commandDelay);
  inColormax.readCoefficient();               // !f,
  println("!f,3");
  delay(commandDelay);
  inColormax.readIlluminationAlgorithm();     // !g,
  println("!g,...");
  delay(commandDelay);
  inColormax.readCLT();                       // !h,
  println("!h,...");
  delay(commandDelay);
  inColormax.readIdentity();                  // !i,4,
  println("!i,4,...");
  delay(commandDelay);
  inColormax.writePhase("FF");                // ?
  println("?");
  delay(commandDelay);
  inColormax.writePhase("AA");                // !L
  println("!L");
  delay(commandDelay);
  inColormax.readPhase();                     // !l
  println("!l,AA");
  delay(commandDelay);
  inColormax.writePhase("62");                // !L
  println("!L");
  delay(commandDelay);
  inColormax.readPhase();                     // !l
  println("!l,62");
  delay(commandDelay);
  inColormax.serial.write("!S,9,2,2,2,FF\r"); // ?
  println("?");
  delay(commandDelay);
  inColormax.serial.write("!S,2,1,1,1,22\r"); // !S
  println("!S");
  delay(commandDelay);
  inColormax.readSettings();                  // !s
  println("!s,8,0,0,0,64");
  delay(commandDelay);
  inColormax.serial.write("!S,8,0,0,0,64\r"); // !S
  println("!S");
  delay(commandDelay);
  inColormax.readSettings();                  // !s
  println("!s,8,0,0,0,64");
  delay(commandDelay);
  inColormax.serial.write("!T,1,1,1,1,FFFFF,FFFFF,FFFFF\r");  // ?
  println("?");
  delay(commandDelay);
  inColormax.serial.write("!T,1,1,1,1,11111,11111,11111\r");  // !T,1,
  println("!T,1,...");
  delay(commandDelay);
  inColormax.serial.write("!c,1\r");          // !c,1,
  println("!c,1,...");
  delay(commandDelay);
  inColormax.readVersion();                   // !v,
  println("!v,...");
  delay(commandDelay);
  inColormax.serial.write("!w\r");            // !w,
  println("!w,...");
  delay(commandDelay);
  
  println("demence demand desting");
}

boolean getUDID(Colormax inColormax){
  // To get the UDID, we need to send the !D command
  // To use the !D command, we need to use the !Z command first
  // To use the !Z command, we need the serial number reversed in pairs of two hex digits
  // e.g. inSN == "0123 4567 89AB CDEF", outSN == "EFCD AB89 6745 2301"
  
  final int commandDelay = 50;        // Delay in milliseconds required between serial commands (range: 25-infinity)
  final int responseTimeout = 250;    // Delay for colormax response timeout (range: 25 - infinity)
  String tempSerialNumber = inColormax.getSerialNumber();  // we may not need this
  inColormax.setSerialNumber(null);                        //serialNumber = null so we can check for if we've got an update or not
  inColormax.readIdentity();          // Ask for colormax's serial number - this is to make sure we have the right serial number as it's not updated if a new colormax is connected and its info not grabbed
  
  int startMillis = millis();         // Starting point for response timeout
  while(inColormax.getSerialNumber() == null){
    delay(1);                                             // Required, otherwise this function goes too fast
    if((millis() - startMillis) > responseTimeout){       // Check if we've timed out
      inColormax.setSerialNumber(tempSerialNumber);       // If not, set this back, I guess?
      println("@@@@@@@@@@", inColormax.serial.port.getPortName(),", getUDID serial number response timeout @@@@@@@@@@");  // Print out an error
      return false;                                             // Leave this function!
    }
  }
  
  // Now that we know for sure we have the right serial number
  char[] sn = inColormax.getSerialNumber().toCharArray();  // Make it an array; easier to maniuplate indiviudal characters like this
  char[] sn2 = new char[16];                               // Make a second array to store the deletion code (this will be used to make a string later)
  
  int i;                            // For iterating through sn
  int j = 0;                        // For iterating through sn2
  for(i = (sn.length - 1) ; i > 0 ; i -= 2){     // Start from the end of sn[], make sure we stay above 0, decrement by 2
    sn2[j++] = sn[i-1];             // Increment through sn2[], go half-backwards through sn[] (it's weird, i know)
    sn2[j++] = sn[i];
  }
  
  // We can finally send the !Z and !D commands
  String serialNumberDeletionCode = new String(sn2);              // The !Z command actually deletes the unit's serial number; we need it as a string for our function
  inColormax.writeDeleteSerialNumber(serialNumberDeletionCode);   // Tell the unit to delete its serial number; no worries, we have its serial number stored in the object for later
  delay(commandDelay);                                            // Wait a little while for the unit to do its thing
  inColormax.readUDID();                                          // Send the !D command
  delay(commandDelay);                                            // Wait a little while for the unit to do its thing
  inColormax.writeSerialNumber(inColormax.getSerialNumber());     // Send the !I command to have the unit rewrite its serial number!
  //println(inColormax.getUDID());
  return true;// All done
}

void calcUDIDcd(Colormax inColormax){
  // The UDIDcd is a strange beast..
  // We need to M xor N where:
  // M = hex values 18, 24, 4, 30, 23, and 12 from the UDID
  // N = The last 7 digits of the unit's serial number in reverse order, converted to a hex value
  if(!getUDID(inColormax)){  // Make sure we have the unit's UDID
    return;  // We couldn't get the UDID, leave now
  }
  else {     // We got it! Moving on...
    // Let's get M first
    char[] inUDID = inColormax.getUDID().toCharArray();        // Convert the UDID to an array of characters, because it's easier to deal with
    char[] tempM = { inUDID[17], inUDID[23], inUDID[3], inUDID[29], inUDID[22], inUDID[11]  };  // M = hex values 18, 24, 4, 30, 23, and 12 from the UDID
    String M = new String(tempM);                              // Turn that badboi into a string
    println("M:", M);  // for debugging
    
    // Now lets get N
    char[] inSN = inColormax.getSerialNumber().toCharArray();  // Convert the serial number to an array
    char[] tempN = new char[7];                                // Second array to temporarily hold N
    
    // We need the last 7 digits of inSN in reverse order
    int i = 0;                              // Just need one iterating variable
    for(i = 0 ; i < tempN.length ; i++){    // Start from the beginning, make sure we don't exceed our array length, increment once
      tempN[i] = inSN[inSN.length - (i + 1)];     // Go in reverse, bb
    }
    String N = new String(tempN);           // Chuck that into a string
    N = String.format("%X", Integer.parseInt(N));    // Do some fancy footwork to make that string a hex value
    println("N:", N);  // for debugging
    
    // Now we just xor those bois together
    String UDIDcd = String.format("%X", ((Integer.parseInt(M, 16)) ^ (Integer.parseInt(N, 16))));
    inColormax.setUDIDcd(UDIDcd);
    println("UDIDcd:", UDIDcd);  //for debugging
  }
}

// cheat button for teaching 96 brightness paper to four channels
void cheatButton1337() {
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13); // clear buffer and whatnot
  
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write("!C,0,0,1,0,FE5C,FFC0,FE6D,FFC0,FE66,FFC0");
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
  delay(250);
  
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write("!C,1,0,1,0,FE5C,FFC0,FE6D,FFC0,FE66,FFC0");
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
  delay(250);
  
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write("!C,2,0,1,0,FE5C,FFC0,FE6D,FFC0,FE66,FFC0");
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
  delay(250);
  
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write("!C,3,0,1,0,FE5C,FFC0,FE6D,FFC0,FE66,FFC0");
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
  delay(250);
  
  colormaxes[listColormaxSelect.getSelectedIndex()].sendSettings("8", "0", "0", 100);
  delay(250);
  
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write("!A,3E0");
  colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
  
}

// Key Pressed Event Listener **************************************************
void keyPressed() {
  // Spacebar Shortcut Handler
  if(key == ' '
  && chkSpacebarShortcut.isSelected()) {
    btnCalibrateColor_click1(btnCalibrateColor, GEvent.CLICKED);
  }
}

// Serial Event Listener **************************************************
void serialEvent(Serial inPort) {
  String inString = inPort.readString();
  
  //debugging
  println("Recieved:", inString);
  
  // Check if it's a colormax response
  // If it is, and we're looking for colormaxes,
  // update the map
  if (inString.startsWith("?") ) {
    if (populatingColormaxes) {
      for (int i = 0; i < ports.length; i++) {
        if (inPort == ports[i]) {
          println("Colormax on", ports[i].port.getPortName());
          colormaxFoundMap[i] = true;
          break;
        }
      }
    }
    return;
  }


  if (inString.startsWith("!a")) {
    //println("got ia");
    //colormaxes[listColormaxSelect.getSelectedIndex()].parseIlluminationSetting(inString);
    return;
  }

  if (inString.startsWith("!d")) {
    //println(inString);
    if(colormaxes[listColormaxSelect.getSelectedIndex()].getStatus() == colormaxes[listColormaxSelect.getSelectedIndex()].calibratingIlluminationFactor) {
      //int blue = Integer.parseInt(blueChannel, 16);
      colormaxes[listColormaxSelect.getSelectedIndex()].lightAdjustmentCalibrateContinue(Integer.parseInt(inString.substring(13, 17), 16));
    }
    else {
      colormaxes[listColormaxSelect.getSelectedIndex()].parseData(inString);
    }
    return;
  }
  
  if (inString.startsWith("!g")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseIlluminationAlgorithm(inString);
    return;
  }

  if (inString.startsWith("!h")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseClt(inString);
    return;
  }

  if (inString.startsWith("!s")) {
    //println("got settings");
    colormaxes[listColormaxSelect.getSelectedIndex()].parseSettings(inString);
    return;
  }

  if (inString.startsWith("!i")) {
    //println("got identity");
    colormaxes[listColormaxSelect.getSelectedIndex()].parseIdentity(inString);
    return;
  }

  if (inString.startsWith("!v")) {
    //println("got version");
    colormaxes[listColormaxSelect.getSelectedIndex()].parseVersion(inString);
    return;
  }

  if (inString.startsWith("!O")) {
    
  }
  
  if(inString.startsWith("!D")){
    colormaxes[listColormaxSelect.getSelectedIndex()].parseUDID(inString);
  }
  
  if(inString.startsWith("!w")){
    colormaxes[listColormaxSelect.getSelectedIndex()].parseTemperature(inString);
  }
  
  // @@@@@@@@@@ End of serialEvent() @@@@@@@@@@
}

// Use this method to add additional statements
// to customise the GUI controls  
public void customGUI() {
}