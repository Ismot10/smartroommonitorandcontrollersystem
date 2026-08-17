/*
================================================================
                    AURORA SMART LIVING
                 SMART ROOM CONTROLLER

 STEP 10F — COMPLETE AUTOMATION + REAL HEARTBEAT
================================================================

PHYSICAL SENSORS
----------------------------------------------------------------
DHT22 DATA       -> GPIO4
PIR OUT          -> GPIO27
LDR DIGITAL OUT  -> GPIO34
RAIN AO          -> GPIO32
GAS DIGITAL OUT  -> GPIO33

PHYSICAL ACTUATORS
----------------------------------------------------------------
CURTAIN SERVO    -> GPIO18
BUZZER            -> GPIO23
RGB RELAY         -> GPIO25
WHITE LED PWM     -> GPIO26

DIGITAL TWINS
----------------------------------------------------------------
Fan
Door Lock

================================================================
AUTOMATION
================================================================

1. Rain
   Rain detected -> Curtain CLOSED
   Rain stops -> Curtain remains closed
   Manual control becomes available again

2. Motion + Low Light
   DARK -> automatic white light allowed
   BRIGHT -> automation-owned white light OFF
   Manual white light ON is preserved
   Motion filtered
   No motion 15 sec -> motion request released

3. Gas Emergency
   Filtered gas detection
   Buzzer ON
   RGB alarm ON
   White light ON
   Door digital twin UNLOCKED
   Critical Firebase alert
   Confirmed Firebase synchronization
   Phantom buzzer protection

4. Temperature Fan
   temperature >= triggerValue -> Fan ON at 70%
   temperature <= resetValue   -> previous manual Fan state

5. Firebase queue protection
   Sensor upload remains async
   Critical automation writes are synchronous

6. ESP32 HEARTBEAT
   Every 8 seconds:

   /rooms/room_01/system/esp32_status
        = "online"

   /rooms/room_01/system/esp32_last_seen
        = Firebase SERVER timestamp

   Flutter:
      heartbeat <= 25 seconds old -> ONLINE
      heartbeat > 25 seconds old  -> OFFLINE

================================================================
*/


// ================================================================
// OPTIONAL FEATURES
// ================================================================

// Door Lock is now present in Flutter.
#define ENABLE_DOOR_DIGITAL_TWIN 1

// Keep disabled because Flutter already handles temperature alerts.
#define ESP32_CREATES_TEMPERATURE_ALERT 0


// ================================================================
// FIREBASE FEATURES
// ================================================================

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE


// ================================================================
// LIBRARIES
// ================================================================

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include <time.h>


// ================================================================
// WIFI
// ================================================================


#define WIFI_SSID       "UFTB"
#define WIFI_PASSWORD   "Uftb@2018#"

#define API_KEY         "AIzaSyC9uaG6CwaNRF4iUrlNwtk8mpVfUrOE8As"

#define USER_EMAIL      "ismotaraprova@gmail.com"
#define USER_PASSWORD   "123456789P#"


#define DATABASE_URL \
"https://aurora-smart-living-default-rtdb.firebaseio.com/"


// ================================================================
// SENSOR PINS
// ================================================================

#define DHT_PIN      4
#define DHT_TYPE     DHT22

#define PIR_PIN      27
#define LDR_PIN      34
#define RAIN_PIN     32
#define GAS_PIN      33


// ================================================================
// ACTUATOR PINS
// ================================================================

#define SERVO_PIN        18
#define BUZZER_PIN       23
#define RGB_RELAY_PIN    25
#define WHITE_LED_PIN    26


// ================================================================
// RAIN
// ================================================================

#define RAIN_THRESHOLD 3200


// ================================================================
// CURTAIN
// ================================================================

#define CURTAIN_OPEN_ANGLE       135
#define CURTAIN_CLOSED_ANGLE      45


// ================================================================
// MOTION FILTER
// ================================================================

const unsigned long MOTION_ON_CONFIRM_MS  = 600;
const unsigned long MOTION_OFF_CONFIRM_MS = 800;

const unsigned long NO_MOTION_OFF_DELAY = 15000;


// ================================================================
// GAS FILTER
// ================================================================

const unsigned long GAS_ON_CONFIRM_MS  = 1500;
const unsigned long GAS_OFF_CONFIRM_MS = 1500;

const unsigned long GAS_CLEAR_CONFIRM_DELAY = 5000;


// ================================================================
// LIGHT FILTER
// ================================================================

const unsigned long LIGHT_CHANGE_CONFIRM_MS = 500;


// ================================================================
// FAN
// ================================================================

const int FAN_AUTOMATION_SPEED = 70;

const unsigned long FAN_ENFORCE_INTERVAL = 5000;


// ================================================================
// FIREBASE TIMING
// ================================================================

const unsigned long SENSOR_UPLOAD_INTERVAL = 5000;

const unsigned long CONTROL_POLL_INTERVAL = 2000;

const unsigned long CONFIG_REFRESH_INTERVAL = 7000;

const unsigned long CRITICAL_RETRY_INTERVAL = 3000;

const unsigned long GAS_ENFORCE_INTERVAL = 4000;


// ================================================================
// HEARTBEAT
// ================================================================

// Normal heartbeat every 8 seconds.
const unsigned long HEARTBEAT_INTERVAL = 8000;

// If heartbeat write fails, retry after 3 seconds.
const unsigned long HEARTBEAT_RETRY_INTERVAL = 3000;


// ================================================================
// ASYNC QUEUE SAFETY
// ================================================================

const size_t SAFE_ASYNC_TASK_LIMIT = 7;


// ================================================================
// OBJECTS
// ================================================================

DHT dht(
  DHT_PIN,
  DHT_TYPE
);

Servo curtainServo;


// ================================================================
// FIREBASE AUTH
// ================================================================

UserAuth userAuth(
  API_KEY,
  USER_EMAIL,
  USER_PASSWORD
);

FirebaseApp app;

RealtimeDatabase Database;


// ================================================================
// FIREBASE CLIENTS
// ================================================================

WiFiClientSecure sslAsync;
WiFiClientSecure sslControl;

using AsyncClient = AsyncClientClass;

AsyncClient asyncClient(
  sslAsync
);

AsyncClient controlClient(
  sslControl
);


// ================================================================
// FIREBASE READY
// ================================================================

bool firebaseStarted = false;


// ================================================================
// LOOP TIMERS
// ================================================================

unsigned long lastSensorUpload = 0;

unsigned long lastControlPoll = 0;

unsigned long lastConfigRefresh = 0;


// ================================================================
// HEARTBEAT STATE
// ================================================================

unsigned long lastHeartbeatSuccess = 0;

unsigned long lastHeartbeatAttempt = 0;

bool heartbeatSyncPending = false;


// ================================================================
// CURRENT PHYSICAL STATES
// ================================================================

bool currentWhiteOn = false;

int currentWhiteBrightness = 0;

bool currentRgbOn = false;

bool currentBuzzerOn = false;

String currentCurtainPosition = "";


// ================================================================
// SENSOR STATES
// ================================================================

bool latestMotionDetected = false;

bool latestGasDetected = false;

bool latestIsDark = false;

int latestLightLevel = 100;

bool latestRainDetected = false;

float latestTemperature = 0.0;

float latestHumidity = 0.0;

bool latestTemperatureValid = false;


// ================================================================
// FILTER CANDIDATES
// ================================================================

bool motionCandidate = false;

unsigned long motionCandidateSince = 0;


bool gasCandidate = false;

unsigned long gasCandidateSince = 0;


bool darkCandidate = false;

unsigned long darkCandidateSince = 0;


// ================================================================
// AUTOMATION CONFIG CACHE
// ================================================================

bool cfgMasterEnabled = false;

bool cfgRainCurtainEnabled = false;

bool cfgMotionSecurityEnabled = false;

bool cfgLowLightEnabled = false;

bool cfgGasEmergencyEnabled = false;

bool cfgTemperatureFanEnabled = false;


int cfgLowLightTrigger = 100;

int cfgTemperatureTrigger = 30;

int cfgTemperatureReset = 20;


// ================================================================
// FIREBASE DEVICE CACHE
// ================================================================

// White Light
bool fbWhiteOn = false;

int fbWhiteBrightness = 100;


// RGB
bool fbRgbOn = false;


// Buzzer
bool fbBuzzerOn = false;


// Curtain
String fbCurtainPosition = "open";


// Fan
bool fbFanOn = false;

int fbFanBrightness = 0;


// Door
#if ENABLE_DOOR_DIGITAL_TWIN

String fbDoorState = "locked";

#endif


// ================================================================
// WHITE LIGHT AUTOMATION
// ================================================================

bool whiteAutomationOwnsLight = false;

bool motionLightRequestActive = false;

bool lowLightRequestActive = false;

bool gasWhiteRequestActive = false;


// ================================================================
// WHITE FIREBASE SYNC
// ================================================================

bool whiteSyncPending = false;

bool whiteDesiredFirebaseState = false;

unsigned long lastWhiteSyncAttempt = 0;


// ================================================================
// MOTION TIMER
// ================================================================

unsigned long noMotionStartTime = 0;


// ================================================================
// GAS STATE
// ================================================================

bool gasEmergencyRequestActive = false;

bool gasEmergencyWasActive = false;

unsigned long gasNormalStartTime = 0;


bool buzzerStateBeforeGas = false;

bool rgbStateBeforeGas = false;


bool gasReleasedThisCycle = false;


bool gasActivationSyncPending = false;

bool gasResetPending = false;


unsigned long lastGasSyncAttempt = 0;

unsigned long lastGasEnforce = 0;


String activeGasAlertId = "";


// ================================================================
// TEMPERATURE FAN STATE
// ================================================================

bool temperatureFanRequestActive = false;

bool temperatureFanWasActive = false;


bool fanStateBeforeTemperature = false;

int fanBrightnessBeforeTemperature = 0;


bool fanSyncPending = false;

bool fanDesiredState = false;

int fanDesiredBrightness = 0;


unsigned long lastFanSyncAttempt = 0;

unsigned long lastFanEnforce = 0;


// ================================================================
// FIREBASE CALLBACK
// ================================================================

void processData(
  AsyncResult &result
) {

  if (!result.isResult()) {
    return;
  }


  if (result.isEvent()) {

    Serial.print(
      "Firebase EVENT: "
    );

    Serial.println(
      result.eventLog().message()
    );
  }


  if (result.isError()) {

    Serial.print(
      "Firebase ERROR: "
    );

    Serial.print(
      result.error().message()
    );

    Serial.print(
      " | code: "
    );

    Serial.println(
      result.error().code()
    );
  }


  // Never print result.c_str() for authentication.
}


// ================================================================
// FIREBASE BACKGROUND MAINTENANCE
// ================================================================

void serviceFirebase() {

  app.loop();

  Database.loop();

  yield();
}


// ================================================================
// LOCAL TIMESTAMP
//
// Used only where necessary.
//
// HEARTBEAT DOES NOT DEPEND ON THIS.
// HEARTBEAT USES FIREBASE SERVER TIMESTAMP.
// ================================================================

unsigned long long getTimestampMs() {

  time_t now =
    time(nullptr);


  if (
    now < 1000000000
  ) {

    return 0;
  }


  return (
    (unsigned long long)now
    *
    1000ULL
  );
}


// ================================================================
// BOOLEAN FILTER
// ================================================================

void updateStableBoolean(
  bool rawValue,

  bool &candidateValue,

  unsigned long &candidateSince,

  bool &stableValue,

  unsigned long onConfirmMs,

  unsigned long offConfirmMs
) {

  unsigned long now =
    millis();


  if (
    rawValue
    !=
    candidateValue
  ) {

    candidateValue =
      rawValue;


    candidateSince =
      now;
  }


  if (
    candidateValue
    !=
    stableValue
  ) {

    unsigned long requiredTime =
      candidateValue
        ? onConfirmMs
        : offConfirmMs;


    if (
      now
      -
      candidateSince
      >=
      requiredTime
    ) {

      stableValue =
        candidateValue;
    }
  }
}


// ================================================================
// FILTER INPUTS
// ================================================================

void updateFilteredInputs() {

  // ============================================================
  // MOTION
  // ============================================================

  bool rawMotion =
    (
      digitalRead(
        PIR_PIN
      )
      ==
      HIGH
    );


  bool oldMotion =
    latestMotionDetected;


  updateStableBoolean(
    rawMotion,

    motionCandidate,

    motionCandidateSince,

    latestMotionDetected,

    MOTION_ON_CONFIRM_MS,

    MOTION_OFF_CONFIRM_MS
  );


  if (
    oldMotion
    !=
    latestMotionDetected
  ) {

    Serial.print(
      "[FILTER][MOTION] -> "
    );


    Serial.println(
      latestMotionDetected
        ? "MOTION"
        : "NO MOTION"
    );
  }


  // ============================================================
  // GAS
  // RAW LOW = GAS
  // ============================================================

  bool rawGas =
    (
      digitalRead(
        GAS_PIN
      )
      ==
      LOW
    );


  bool oldGas =
    latestGasDetected;


  updateStableBoolean(
    rawGas,

    gasCandidate,

    gasCandidateSince,

    latestGasDetected,

    GAS_ON_CONFIRM_MS,

    GAS_OFF_CONFIRM_MS
  );


  if (
    oldGas
    !=
    latestGasDetected
  ) {

    Serial.print(
      "[FILTER][GAS] -> "
    );


    Serial.println(
      latestGasDetected
        ? "GAS DETECTED"
        : "NORMAL"
    );
  }


  // ============================================================
  // LIGHT
  // RAW HIGH = DARK
  // ============================================================

  bool rawDark =
    (
      digitalRead(
        LDR_PIN
      )
      ==
      HIGH
    );


  bool oldDark =
    latestIsDark;


  updateStableBoolean(
    rawDark,

    darkCandidate,

    darkCandidateSince,

    latestIsDark,

    LIGHT_CHANGE_CONFIRM_MS,

    LIGHT_CHANGE_CONFIRM_MS
  );


  latestLightLevel =
    latestIsDark
      ? 0
      : 100;


  if (
    oldDark
    !=
    latestIsDark
  ) {

    Serial.print(
      "[FILTER][LIGHT] -> "
    );


    Serial.println(
      latestIsDark
        ? "DARK"
        : "BRIGHT"
    );
  }
}


// ================================================================
// RAIN AVERAGING
// ================================================================

int readRainAverage() {

  long total = 0;

  const int samples = 20;


  for (
    int i = 0;
    i < samples;
    i++
  ) {

    total +=
      analogRead(
        RAIN_PIN
      );


    delay(
      5
    );
  }


  return (
    total / samples
  );
}


// ================================================================
// PHYSICAL WHITE LIGHT
// ================================================================

void applyWhiteLight(
  bool isOn,
  int brightness
) {

  brightness =
    constrain(
      brightness,
      0,
      100
    );


  if (
    isOn
      ==
      currentWhiteOn
    &&
    brightness
      ==
      currentWhiteBrightness
  ) {

    return;
  }


  int pwmValue = 0;


  if (isOn) {

    pwmValue =
      map(
        brightness,
        0,
        100,
        0,
        255
      );
  }


  ledcWrite(
    WHITE_LED_PIN,
    pwmValue
  );


  currentWhiteOn =
    isOn;


  currentWhiteBrightness =
    brightness;


  Serial.print(
    "[PHYSICAL] White Light -> "
  );


  Serial.print(
    isOn
      ? "ON"
      : "OFF"
  );


  Serial.print(
    " | "
  );


  Serial.print(
    brightness
  );


  Serial.println(
    "%"
  );
}


// ================================================================
// RGB LIGHT
// ================================================================

void applyRgbLight(
  bool isOn
) {

  if (
    isOn
    ==
    currentRgbOn
  ) {

    return;
  }


  // Active LOW relay.
  digitalWrite(
    RGB_RELAY_PIN,

    isOn
      ? LOW
      : HIGH
  );


  currentRgbOn =
    isOn;


  Serial.print(
    "[PHYSICAL] Color Lights -> "
  );


  Serial.println(
    isOn
      ? "ON"
      : "OFF"
  );
}


// ================================================================
// BUZZER
// ================================================================

void applyBuzzer(
  bool isOn
) {

  if (
    isOn
    ==
    currentBuzzerOn
  ) {

    return;
  }


  digitalWrite(
    BUZZER_PIN,

    isOn
      ? HIGH
      : LOW
  );


  currentBuzzerOn =
    isOn;


  Serial.print(
    "[PHYSICAL] Buzzer -> "
  );


  Serial.println(
    isOn
      ? "ON"
      : "OFF"
  );
}


// ================================================================
// CURTAIN
// ================================================================

void applyCurtain(
  String position
) {

  position.trim();

  position.toLowerCase();


  if (
    position
    ==
    "close"
  ) {

    position =
      "closed";
  }


  if (
    position != "open"
    &&
    position != "closed"
  ) {

    return;
  }


  if (
    position
    ==
    currentCurtainPosition
  ) {

    return;
  }


  if (
    position
    ==
    "open"
  ) {

    curtainServo.write(
      CURTAIN_OPEN_ANGLE
    );

  } else {

    curtainServo.write(
      CURTAIN_CLOSED_ANGLE
    );
  }


  currentCurtainPosition =
    position;


  Serial.print(
    "[PHYSICAL] Curtain -> "
  );


  Serial.println(
    position
  );
}


// ================================================================
// SAFE FIREBASE READ BOOL
// ================================================================

bool readBoolSafe(
  const String &path,
  bool &value
) {

  bool temp =
    Database.get<bool>(
      controlClient,
      path
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    errorCode == 0
  ) {

    value =
      temp;


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE READ ERROR] "
  );


  Serial.println(
    path
  );


  serviceFirebase();


  return false;
}


// ================================================================
// SAFE FIREBASE READ INT
// ================================================================

bool readIntSafe(
  const String &path,
  int &value
) {

  int temp =
    Database.get<int>(
      controlClient,
      path
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    errorCode == 0
  ) {

    value =
      temp;


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE READ ERROR] "
  );


  Serial.println(
    path
  );


  serviceFirebase();


  return false;
}


// ================================================================
// SAFE FIREBASE READ STRING
// ================================================================

bool readStringSafe(
  const String &path,
  String &value
) {

  String temp =
    Database.get<String>(
      controlClient,
      path
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    errorCode == 0
  ) {

    value =
      temp;


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE READ ERROR] "
  );


  Serial.println(
    path
  );


  serviceFirebase();


  return false;
}


// ================================================================
// CONFIRMED FIREBASE BOOL WRITE
// ================================================================

bool syncSetBool(
  const String &path,
  bool value,
  const String &label
) {

  bool status =
    Database.set<bool>(
      controlClient,
      path,
      value
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    status
    &&
    errorCode == 0
  ) {

    Serial.print(
      "[FIREBASE CONFIRMED] "
    );


    Serial.println(
      label
    );


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE WRITE FAILED] "
  );


  Serial.println(
    label
  );


  serviceFirebase();


  return false;
}


// ================================================================
// CONFIRMED FIREBASE STRING WRITE
// ================================================================

bool syncSetString(
  const String &path,
  const String &value,
  const String &label
) {

  bool status =
    Database.set<String>(
      controlClient,
      path,
      value
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    status
    &&
    errorCode == 0
  ) {

    Serial.print(
      "[FIREBASE CONFIRMED] "
    );


    Serial.println(
      label
    );


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE WRITE FAILED] "
  );


  Serial.println(
    label
  );


  serviceFirebase();


  return false;
}


// ================================================================
// CONFIRMED FIREBASE OBJECT PATCH
// ================================================================

bool syncUpdateObject(
  const String &path,
  object_t &json,
  const String &label
) {

  bool status =
    Database.update<object_t>(
      controlClient,
      path,
      json
    );


  int errorCode =
    controlClient
      .lastError()
      .code();


  if (
    status
    &&
    errorCode == 0
  ) {

    Serial.print(
      "[FIREBASE CONFIRMED] "
    );


    Serial.println(
      label
    );


    serviceFirebase();


    return true;
  }


  Serial.print(
    "[FIREBASE WRITE FAILED] "
  );


  Serial.print(
    label
  );


  Serial.print(
    " | "
  );


  Serial.println(
    controlClient
      .lastError()
      .message()
  );


  serviceFirebase();


  return false;
}


// ================================================================
// REAL ESP32 HEARTBEAT
//
// Firebase SERVER generates esp32_last_seen.
//
// JSON sent:
//
// {
//   "esp32_status": "online",
//   "esp32_last_seen": {
//       ".sv": "timestamp"
//   }
// }
//
// Firebase resolves esp32_last_seen into Unix milliseconds.
// ================================================================

bool writeHeartbeat() {

  lastHeartbeatAttempt =
    millis();


  object_t heartbeat(
    "{\"esp32_status\":\"online\","
    "\"esp32_last_seen\":{\".sv\":\"timestamp\"}}"
  );


  bool success =
    syncUpdateObject(
      "/rooms/room_01/system",
      heartbeat,
      "ESP32 heartbeat"
    );


  if (success) {

    heartbeatSyncPending =
      false;


    lastHeartbeatSuccess =
      millis();


    Serial.println(
      "[HEARTBEAT] Online timestamp refreshed"
    );

  } else {

    heartbeatSyncPending =
      true;


    Serial.println(
      "[HEARTBEAT] Write failed - retry scheduled"
    );
  }


  return success;
}


// ================================================================
// HEARTBEAT SERVICE
// ================================================================

void serviceHeartbeat() {

  if (
    !app.ready()
  ) {

    return;
  }


  // ------------------------------------------------------------
  // Previous write failed.
  // Retry more quickly.
  // ------------------------------------------------------------

  if (
    heartbeatSyncPending
  ) {

    if (
      millis()
      -
      lastHeartbeatAttempt
      >=
      HEARTBEAT_RETRY_INTERVAL
    ) {

      writeHeartbeat();
    }


    return;
  }


  // ------------------------------------------------------------
  // Normal heartbeat.
  // ------------------------------------------------------------

  if (
    millis()
    -
    lastHeartbeatSuccess
    >=
    HEARTBEAT_INTERVAL
  ) {

    writeHeartbeat();
  }
}


// ================================================================
// WHITE LIGHT SYNC
// ================================================================

bool tryWhiteFirebaseSync() {

  lastWhiteSyncAttempt =
    millis();


  bool success =
    syncSetBool(
      "/rooms/room_01/devices/whiteLight/isOn",

      whiteDesiredFirebaseState,

      "White Light synchronized"
    );


  if (success) {

    fbWhiteOn =
      whiteDesiredFirebaseState;


    whiteSyncPending =
      false;
  }


  return success;
}


// ================================================================

void requestWhiteFirebaseState(
  bool state
) {

  whiteDesiredFirebaseState =
    state;


  whiteSyncPending =
    true;


  tryWhiteFirebaseSync();
}


// ================================================================

void serviceWhiteSyncRetry() {

  if (
    !whiteSyncPending
  ) {

    return;
  }


  if (
    millis()
    -
    lastWhiteSyncAttempt
    <
    CRITICAL_RETRY_INTERVAL
  ) {

    return;
  }


  Serial.println(
    "[RETRY] White Light Firebase synchronization"
  );


  tryWhiteFirebaseSync();
}


// ================================================================
// GAS ALERT ID
// ================================================================

String createGasAlertId() {

  unsigned long long timestamp =
    getTimestampMs();


  char buffer[80];


  if (
    timestamp > 0
  ) {

    snprintf(
      buffer,
      sizeof(buffer),
      "gasEmergency_%llu_%lu",
      timestamp,
      millis()
    );

  } else {

    snprintf(
      buffer,
      sizeof(buffer),
      "gasEmergency_%lu",
      millis()
    );
  }


  return String(
    buffer
  );
}


// ================================================================
// TEMPERATURE ALERT ID
// ================================================================

String createTemperatureAlertId() {

  unsigned long long timestamp =
    getTimestampMs();


  char buffer[80];


  if (
    timestamp > 0
  ) {

    snprintf(
      buffer,
      sizeof(buffer),
      "temperatureFan_%llu_%lu",
      timestamp,
      millis()
    );

  } else {

    snprintf(
      buffer,
      sizeof(buffer),
      "temperatureFan_%lu",
      millis()
    );
  }


  return String(
    buffer
  );
}


// ================================================================
// GAS ACTIVATION
// ================================================================

bool syncGasActivation() {

  if (
    activeGasAlertId.length()
    ==
    0
  ) {

    activeGasAlertId =
      createGasAlertId();
  }


  unsigned long long createdAt =
    getTimestampMs();


  object_t patch;


  object_t objBuzzer;

  object_t objRgb;

  object_t objWhite;


#if ENABLE_DOOR_DIGITAL_TWIN

  object_t objDoor;

#endif


  object_t objAlertId;

  object_t objRuleId;

  object_t objTitle;

  object_t objMessage;

  object_t objSeverity;

  object_t objRead;

  object_t objTest;

  object_t objCreated;


  JsonWriter writer;


  writer.create(
    objBuzzer,

    "devices/buzzer/isOn",

    boolean_t(true)
  );


  writer.create(
    objRgb,

    "devices/rgbLight/isOn",

    boolean_t(true)
  );


  writer.create(
    objWhite,

    "devices/whiteLight/isOn",

    boolean_t(true)
  );


#if ENABLE_DOOR_DIGITAL_TWIN

  writer.create(
    objDoor,

    "devices/doorLock/doorLockState",

    string_t("unlocked")
  );

#endif


  String alertBase =
    String("alerts/")
    +
    activeGasAlertId
    +
    "/";


  writer.create(
    objAlertId,

    alertBase + "id",

    string_t(
      activeGasAlertId.c_str()
    )
  );


  writer.create(
    objRuleId,

    alertBase + "ruleId",

    string_t(
      "gasEmergency"
    )
  );


  writer.create(
    objTitle,

    alertBase + "title",

    string_t(
      "Gas Emergency Detected"
    )
  );


#if ENABLE_DOOR_DIGITAL_TWIN

  writer.create(
    objMessage,

    alertBase + "message",

    string_t(
      "Gas or smoke detected. Alarm devices were activated and the door was unlocked."
    )
  );

#else

  writer.create(
    objMessage,

    alertBase + "message",

    string_t(
      "Gas or smoke detected. Alarm devices were activated."
    )
  );

#endif


  writer.create(
    objSeverity,

    alertBase + "severity",

    string_t(
      "critical"
    )
  );


  writer.create(
    objRead,

    alertBase + "isRead",

    boolean_t(false)
  );


  writer.create(
    objTest,

    alertBase + "isTest",

    boolean_t(false)
  );


  writer.create(
    objCreated,

    alertBase + "createdAt",

    number_t(
      (double)createdAt,
      0
    )
  );


#if ENABLE_DOOR_DIGITAL_TWIN

  writer.join(
    patch,
    12,

    objBuzzer,
    objRgb,
    objWhite,
    objDoor,

    objAlertId,
    objRuleId,
    objTitle,
    objMessage,
    objSeverity,
    objRead,
    objTest,
    objCreated
  );

#else

  writer.join(
    patch,
    11,

    objBuzzer,
    objRgb,
    objWhite,

    objAlertId,
    objRuleId,
    objTitle,
    objMessage,
    objSeverity,
    objRead,
    objTest,
    objCreated
  );

#endif


  lastGasSyncAttempt =
    millis();


  bool success =
    syncUpdateObject(
      "/rooms/room_01",

      patch,

      "Gas emergency activation"
    );


  if (success) {

    gasActivationSyncPending =
      false;


    fbBuzzerOn =
      true;


    fbRgbOn =
      true;


    fbWhiteOn =
      true;


#if ENABLE_DOOR_DIGITAL_TWIN

    fbDoorState =
      "unlocked";

#endif


    whiteSyncPending =
      false;
  }


  return success;
}


// ================================================================
// GAS ENFORCEMENT
// ================================================================

bool syncGasEmergencyDevices() {

  object_t patch;


  object_t objBuzzer;

  object_t objRgb;

  object_t objWhite;


#if ENABLE_DOOR_DIGITAL_TWIN

  object_t objDoor;

#endif


  JsonWriter writer;


  writer.create(
    objBuzzer,

    "buzzer/isOn",

    boolean_t(true)
  );


  writer.create(
    objRgb,

    "rgbLight/isOn",

    boolean_t(true)
  );


  writer.create(
    objWhite,

    "whiteLight/isOn",

    boolean_t(true)
  );


#if ENABLE_DOOR_DIGITAL_TWIN

  writer.create(
    objDoor,

    "doorLock/doorLockState",

    string_t(
      "unlocked"
    )
  );


  writer.join(
    patch,
    4,

    objBuzzer,
    objRgb,
    objWhite,
    objDoor
  );

#else

  writer.join(
    patch,
    3,

    objBuzzer,
    objRgb,
    objWhite
  );

#endif


  bool success =
    syncUpdateObject(
      "/rooms/room_01/devices",

      patch,

      "Gas emergency device enforcement"
    );


  lastGasEnforce =
    millis();


  if (success) {

    fbBuzzerOn =
      true;


    fbRgbOn =
      true;


    fbWhiteOn =
      true;


#if ENABLE_DOOR_DIGITAL_TWIN

    fbDoorState =
      "unlocked";

#endif
  }


  return success;
}


// ================================================================
// GAS RESET
// ================================================================

bool syncGasReset() {

  object_t patch;


  object_t objBuzzer;

  object_t objRgb;


  JsonWriter writer;


  writer.create(
    objBuzzer,

    "buzzer/isOn",

    boolean_t(
      buzzerStateBeforeGas
    )
  );


  writer.create(
    objRgb,

    "rgbLight/isOn",

    boolean_t(
      rgbStateBeforeGas
    )
  );


  writer.join(
    patch,
    2,

    objBuzzer,
    objRgb
  );


  lastGasSyncAttempt =
    millis();


  bool success =
    syncUpdateObject(
      "/rooms/room_01/devices",

      patch,

      "Gas emergency reset"
    );


  if (success) {

    fbBuzzerOn =
      buzzerStateBeforeGas;


    fbRgbOn =
      rgbStateBeforeGas;


    gasResetPending =
      false;
  }


  return success;
}


// ================================================================
// FAN FIREBASE STATE
// ================================================================

bool syncFanState(
  bool isOn,
  int brightness
) {

  brightness =
    constrain(
      brightness,
      0,
      100
    );


  object_t patch;


  object_t objOn;

  object_t objBrightness;


  JsonWriter writer;


  writer.create(
    objOn,

    "isOn",

    boolean_t(
      isOn
    )
  );


  writer.create(
    objBrightness,

    "brightness",

    brightness
  );


  writer.join(
    patch,
    2,

    objOn,
    objBrightness
  );


  bool success =
    syncUpdateObject(
      "/rooms/room_01/devices/fan",

      patch,

      "Digital Fan synchronized"
    );


  lastFanSyncAttempt =
    millis();


  if (success) {

    fbFanOn =
      isOn;


    fbFanBrightness =
      brightness;


    fanSyncPending =
      false;
  }


  return success;
}


// ================================================================

void requestFanState(
  bool isOn,
  int brightness
) {

  fanDesiredState =
    isOn;


  fanDesiredBrightness =
    constrain(
      brightness,
      0,
      100
    );


  fanSyncPending =
    true;


  syncFanState(
    fanDesiredState,

    fanDesiredBrightness
  );
}


// ================================================================

void serviceFanSyncRetry() {

  if (
    !fanSyncPending
  ) {

    return;
  }


  if (
    millis()
    -
    lastFanSyncAttempt
    <
    CRITICAL_RETRY_INTERVAL
  ) {

    return;
  }


  Serial.println(
    "[RETRY][FAN] Firebase synchronization"
  );


  syncFanState(
    fanDesiredState,

    fanDesiredBrightness
  );
}


// ================================================================
// OPTIONAL TEMPERATURE ALERT
// ================================================================

#if ESP32_CREATES_TEMPERATURE_ALERT

void createTemperatureAlert() {

  String alertId =
    createTemperatureAlertId();


  unsigned long long createdAt =
    getTimestampMs();


  object_t alert;


  object_t objId;

  object_t objRule;

  object_t objTitle;

  object_t objMessage;

  object_t objSeverity;

  object_t objRead;

  object_t objTest;

  object_t objCreated;


  JsonWriter writer;


  writer.create(
    objId,

    "id",

    string_t(
      alertId.c_str()
    )
  );


  writer.create(
    objRule,

    "ruleId",

    string_t(
      "temperatureFan"
    )
  );


  writer.create(
    objTitle,

    "title",

    string_t(
      "High Temperature Detected"
    )
  );


  writer.create(
    objMessage,

    "message",

    string_t(
      "High temperature detected. The virtual fan was activated at 70% speed."
    )
  );


  writer.create(
    objSeverity,

    "severity",

    string_t(
      "warning"
    )
  );


  writer.create(
    objRead,

    "isRead",

    boolean_t(false)
  );


  writer.create(
    objTest,

    "isTest",

    boolean_t(false)
  );


  writer.create(
    objCreated,

    "createdAt",

    number_t(
      (double)createdAt,
      0
    )
  );


  writer.join(
    alert,
    8,

    objId,
    objRule,
    objTitle,
    objMessage,
    objSeverity,
    objRead,
    objTest,
    objCreated
  );


  syncUpdateObject(
    "/rooms/room_01/alerts/"
      +
      alertId,

    alert,

    "Temperature alert"
  );
}

#endif


// ================================================================
// AUTOMATION CONFIG
// ================================================================

void refreshAutomationConfig() {

  Serial.println(
    "[FIREBASE] Refreshing automation configuration..."
  );


  readBoolSafe(
    "/rooms/room_01/automation/masterEnabled",

    cfgMasterEnabled
  );


  readBoolSafe(
    "/rooms/room_01/automation/rules/rainCurtain/enabled",

    cfgRainCurtainEnabled
  );


  readBoolSafe(
    "/rooms/room_01/automation/rules/motionSecurity/enabled",

    cfgMotionSecurityEnabled
  );


  readBoolSafe(
    "/rooms/room_01/automation/rules/lowLight/enabled",

    cfgLowLightEnabled
  );


  readIntSafe(
    "/rooms/room_01/automation/rules/lowLight/triggerValue",

    cfgLowLightTrigger
  );


  readBoolSafe(
    "/rooms/room_01/automation/rules/gasEmergency/enabled",

    cfgGasEmergencyEnabled
  );


  readBoolSafe(
    "/rooms/room_01/automation/rules/temperatureFan/enabled",

    cfgTemperatureFanEnabled
  );


  readIntSafe(
    "/rooms/room_01/automation/rules/temperatureFan/triggerValue",

    cfgTemperatureTrigger
  );


  readIntSafe(
    "/rooms/room_01/automation/rules/temperatureFan/resetValue",

    cfgTemperatureReset
  );


  if (
    cfgLowLightTrigger <= 0
    ||
    cfgLowLightTrigger > 100
  ) {

    cfgLowLightTrigger =
      100;
  }


  if (
    cfgTemperatureTrigger
    <=
    cfgTemperatureReset
  ) {

    Serial.println(
      "[CONFIG] Invalid temperature hysteresis -> using 30/20"
    );


    cfgTemperatureTrigger =
      30;


    cfgTemperatureReset =
      20;
  }


  lastConfigRefresh =
    millis();
}


// ================================================================
// READ DEVICE STATES
// ================================================================

void readDeviceStates() {

  // ============================================================
  // WHITE
  // ============================================================

  bool whiteTemp =
    fbWhiteOn;


  if (
    readBoolSafe(
      "/rooms/room_01/devices/whiteLight/isOn",

      whiteTemp
    )
  ) {

    if (
      whiteSyncPending
    ) {

      if (
        whiteTemp
        ==
        whiteDesiredFirebaseState
      ) {

        fbWhiteOn =
          whiteTemp;


        whiteSyncPending =
          false;

      } else {

        fbWhiteOn =
          whiteTemp;
      }

    } else {

      fbWhiteOn =
        whiteTemp;
    }
  }


  readIntSafe(
    "/rooms/room_01/devices/whiteLight/brightness",

    fbWhiteBrightness
  );


  fbWhiteBrightness =
    constrain(
      fbWhiteBrightness,
      0,
      100
    );


  if (
    fbWhiteBrightness
    <=
    0
  ) {

    fbWhiteBrightness =
      100;
  }


  // ============================================================
  // RGB
  // ============================================================

  readBoolSafe(
    "/rooms/room_01/devices/rgbLight/isOn",

    fbRgbOn
  );


  // ============================================================
  // BUZZER
  // ============================================================

  readBoolSafe(
    "/rooms/room_01/devices/buzzer/isOn",

    fbBuzzerOn
  );


  // ============================================================
  // CURTAIN
  // ============================================================

  readStringSafe(
    "/rooms/room_01/devices/curtain/curtainPosition",

    fbCurtainPosition
  );


  fbCurtainPosition.trim();

  fbCurtainPosition.toLowerCase();


  if (
    fbCurtainPosition
    ==
    "close"
  ) {

    fbCurtainPosition =
      "closed";
  }


  // ============================================================
  // FAN
  // ============================================================

  bool fanTemp =
    fbFanOn;


  if (
    readBoolSafe(
      "/rooms/room_01/devices/fan/isOn",

      fanTemp
    )
  ) {

    if (
      !fanSyncPending
      ||
      fanTemp
      ==
      fanDesiredState
    ) {

      fbFanOn =
        fanTemp;
    }
  }


  int fanBrightnessTemp =
    fbFanBrightness;


  if (
    readIntSafe(
      "/rooms/room_01/devices/fan/brightness",

      fanBrightnessTemp
    )
  ) {

    fbFanBrightness =
      constrain(
        fanBrightnessTemp,
        0,
        100
      );
  }


  // ============================================================
  // DOOR
  // ============================================================

#if ENABLE_DOOR_DIGITAL_TWIN

  if (
    gasEmergencyRequestActive
    ||
    gasActivationSyncPending
  ) {

    readStringSafe(
      "/rooms/room_01/devices/doorLock/doorLockState",

      fbDoorState
    );


    fbDoorState.trim();

    fbDoorState.toLowerCase();
  }

#endif
}


// ================================================================
// MOTION REQUEST
// ================================================================

void updateMotionRequest() {

  if (
    !cfgMasterEnabled
    ||
    !cfgMotionSecurityEnabled
  ) {

    motionLightRequestActive =
      false;


    noMotionStartTime =
      0;


    return;
  }


  // Bright room means no automatic motion light.
  if (
    !latestIsDark
  ) {

    if (
      motionLightRequestActive
    ) {

      Serial.println(
        "[AUTO][MOTION] BRIGHT -> request RELEASED"
      );
    }


    motionLightRequestActive =
      false;


    noMotionStartTime =
      0;


    return;
  }


  if (
    latestMotionDetected
  ) {

    if (
      !motionLightRequestActive
    ) {

      Serial.println(
        "[AUTO][MOTION] Motion in DARK room -> ACTIVE"
      );
    }


    motionLightRequestActive =
      true;


    noMotionStartTime =
      0;


    return;
  }


  if (
    !motionLightRequestActive
  ) {

    noMotionStartTime =
      0;


    return;
  }


  if (
    noMotionStartTime
    ==
    0
  ) {

    noMotionStartTime =
      millis();


    Serial.println(
      "[AUTO][MOTION] No motion -> 15s timer"
    );


    return;
  }


  if (
    millis()
    -
    noMotionStartTime
    >=
    NO_MOTION_OFF_DELAY
  ) {

    motionLightRequestActive =
      false;


    noMotionStartTime =
      0;


    Serial.println(
      "[AUTO][MOTION] 15s no motion -> RELEASED"
    );
  }
}


// ================================================================
// LOW LIGHT
// ================================================================

void updateLowLightRequest() {

  if (
    !cfgMasterEnabled
    ||
    !cfgLowLightEnabled
  ) {

    lowLightRequestActive =
      false;


    return;
  }


  lowLightRequestActive =
    (
      latestLightLevel
      <
      cfgLowLightTrigger
    );
}


// ================================================================
// GAS REQUEST
// ================================================================

void updateGasEmergencyRequest() {

  if (
    !cfgMasterEnabled
    ||
    !cfgGasEmergencyEnabled
  ) {

    gasEmergencyRequestActive =
      false;


    gasWhiteRequestActive =
      false;


    gasNormalStartTime =
      0;


    return;
  }


  if (
    latestGasDetected
  ) {

    gasEmergencyRequestActive =
      true;


    gasWhiteRequestActive =
      true;


    gasNormalStartTime =
      0;


    return;
  }


  if (
    !gasEmergencyRequestActive
  ) {

    gasWhiteRequestActive =
      false;


    gasNormalStartTime =
      0;


    return;
  }


  if (
    gasNormalStartTime
    ==
    0
  ) {

    gasNormalStartTime =
      millis();


    Serial.println(
      "[AUTO][GAS] NORMAL -> 5s clear timer"
    );


    return;
  }


  if (
    millis()
    -
    gasNormalStartTime
    >=
    GAS_CLEAR_CONFIRM_DELAY
  ) {

    gasEmergencyRequestActive =
      false;


    gasWhiteRequestActive =
      false;


    gasNormalStartTime =
      0;


    Serial.println(
      "[AUTO][GAS] Emergency RELEASED"
    );
  }
}


// ================================================================
// GAS EMERGENCY
// ================================================================

void handleGasEmergency() {

  gasReleasedThisCycle =
    false;


  updateGasEmergencyRequest();


  // ============================================================
  // JUST ACTIVATED
  // ============================================================

  if (
    gasEmergencyRequestActive
    &&
    !gasEmergencyWasActive
  ) {

    gasEmergencyWasActive =
      true;


    gasResetPending =
      false;


    buzzerStateBeforeGas =
      fbBuzzerOn;


    rgbStateBeforeGas =
      fbRgbOn;


    if (
      !fbWhiteOn
      &&
      !whiteSyncPending
    ) {

      whiteAutomationOwnsLight =
        true;
    }


    applyBuzzer(
      true
    );


    applyRgbLight(
      true
    );


    applyWhiteLight(
      true,
      fbWhiteBrightness
    );


    activeGasAlertId =
      createGasAlertId();


    gasActivationSyncPending =
      !syncGasActivation();


    Serial.println();

    Serial.println(
      "=============================================="
    );


    Serial.println(
      "         GAS EMERGENCY ACTIVATED"
    );


    Serial.println(
      "Buzzer      : ON"
    );


    Serial.println(
      "RGB Alarm   : ON"
    );


    Serial.println(
      "White Light : ON"
    );


#if ENABLE_DOOR_DIGITAL_TWIN

    Serial.println(
      "Door        : UNLOCKED"
    );

#endif


    Serial.println(
      "Alert       : CRITICAL"
    );


    Serial.println(
      "=============================================="
    );


    return;
  }


  // ============================================================
  // STILL ACTIVE
  // ============================================================

  if (
    gasEmergencyRequestActive
  ) {

    applyBuzzer(
      true
    );


    applyRgbLight(
      true
    );


    applyWhiteLight(
      true,
      fbWhiteBrightness
    );


    if (
      gasActivationSyncPending
      &&
      millis()
      -
      lastGasSyncAttempt
      >=
      CRITICAL_RETRY_INTERVAL
    ) {

      Serial.println(
        "[RETRY][GAS] Activation sync"
      );


      gasActivationSyncPending =
        !syncGasActivation();
    }


    bool firebaseEmergencyStateWrong =
      (
        !fbBuzzerOn
        ||
        !fbRgbOn
        ||
        !fbWhiteOn
      );


#if ENABLE_DOOR_DIGITAL_TWIN

    firebaseEmergencyStateWrong =
      firebaseEmergencyStateWrong
      ||
      fbDoorState != "unlocked";

#endif


    if (
      !gasActivationSyncPending
      &&
      firebaseEmergencyStateWrong
      &&
      millis()
      -
      lastGasEnforce
      >=
      GAS_ENFORCE_INTERVAL
    ) {

      syncGasEmergencyDevices();
    }


    return;
  }


  // ============================================================
  // JUST CLEARED
  // ============================================================

  if (
    !gasEmergencyRequestActive
    &&
    gasEmergencyWasActive
  ) {

    gasEmergencyWasActive =
      false;


    gasActivationSyncPending =
      false;


    gasReleasedThisCycle =
      true;


    gasWhiteRequestActive =
      false;


    applyBuzzer(
      buzzerStateBeforeGas
    );


    applyRgbLight(
      rgbStateBeforeGas
    );


    gasResetPending =
      !syncGasReset();


    Serial.println();

    Serial.println(
      "=============================================="
    );


    Serial.println(
      "          GAS EMERGENCY CLEARED"
    );


    Serial.println(
      "Buzzer/RGB restored"
    );


    Serial.println(
      "White Light returned to normal logic"
    );


#if ENABLE_DOOR_DIGITAL_TWIN

    Serial.println(
      "Door remains UNLOCKED"
    );

#endif


    Serial.println(
      "=============================================="
    );


    activeGasAlertId =
      "";
  }


  // ============================================================
  // RESET RETRY
  // ============================================================

  if (
    gasResetPending
  ) {

    applyBuzzer(
      buzzerStateBeforeGas
    );


    applyRgbLight(
      rgbStateBeforeGas
    );


    if (
      millis()
      -
      lastGasSyncAttempt
      >=
      CRITICAL_RETRY_INTERVAL
    ) {

      Serial.println(
        "[RETRY][GAS] Reset synchronization"
      );


      syncGasReset();
    }
  }
}


// ================================================================
// WHITE LIGHT AUTOMATION
// ================================================================

void handleWhiteLightAutomation() {

  updateMotionRequest();

  updateLowLightRequest();


  bool automationNeedsLight =
    (
      gasWhiteRequestActive
      ||
      lowLightRequestActive
      ||
      motionLightRequestActive
    );


  bool effectiveFirebaseWhiteOn =
    whiteSyncPending
      ? whiteDesiredFirebaseState
      : fbWhiteOn;


  if (
    automationNeedsLight
  ) {

    if (
      gasWhiteRequestActive
    ) {

      applyWhiteLight(
        true,
        fbWhiteBrightness
      );


      return;
    }


    if (
      !effectiveFirebaseWhiteOn
    ) {

      applyWhiteLight(
        true,
        fbWhiteBrightness
      );


      whiteAutomationOwnsLight =
        true;


      requestWhiteFirebaseState(
        true
      );


      Serial.print(
        "[AUTO][LIGHT] ON -> "
      );


      if (
        lowLightRequestActive
        &&
        motionLightRequestActive
      ) {

        Serial.println(
          "LOW LIGHT + MOTION"
        );

      } else if (
        lowLightRequestActive
      ) {

        Serial.println(
          "LOW LIGHT"
        );

      } else {

        Serial.println(
          "MOTION"
        );
      }

    } else {

      applyWhiteLight(
        true,
        fbWhiteBrightness
      );
    }


    return;
  }


  // ============================================================
  // NO AUTOMATION NEEDS LIGHT
  // ============================================================

  if (
    whiteAutomationOwnsLight
  ) {

    applyWhiteLight(
      false,
      fbWhiteBrightness
    );


    whiteAutomationOwnsLight =
      false;


    if (
      effectiveFirebaseWhiteOn
    ) {

      requestWhiteFirebaseState(
        false
      );
    }


    if (
      !latestIsDark
    ) {

      Serial.println(
        "[AUTO][LIGHT] BRIGHT -> Automation light OFF"
      );

    } else {

      Serial.println(
        "[AUTO][LIGHT] Conditions cleared -> OFF"
      );
    }


    return;
  }


  // Manual state
  if (
    !whiteSyncPending
  ) {

    applyWhiteLight(
      fbWhiteOn,
      fbWhiteBrightness
    );
  }
}


// ================================================================
// RAIN CURTAIN
// ================================================================

void handleRainCurtain() {

  bool active =
    (
      cfgMasterEnabled
      &&
      cfgRainCurtainEnabled
      &&
      latestRainDetected
    );


  if (active) {

    applyCurtain(
      "closed"
    );


    if (
      fbCurtainPosition
      !=
      "closed"
    ) {

      if (
        syncSetString(
          "/rooms/room_01/devices/curtain/curtainPosition",

          "closed",

          "Rain -> Curtain CLOSED"
        )
      ) {

        fbCurtainPosition =
          "closed";
      }
    }


    return;
  }


  applyCurtain(
    fbCurtainPosition
  );
}


// ================================================================
// TEMPERATURE FAN REQUEST
// ================================================================

void updateTemperatureFanRequest() {

  if (
    !cfgMasterEnabled
    ||
    !cfgTemperatureFanEnabled
  ) {

    temperatureFanRequestActive =
      false;


    return;
  }


  if (
    !latestTemperatureValid
  ) {

    return;
  }


  if (
    !temperatureFanRequestActive
  ) {

    if (
      latestTemperature
      >=
      cfgTemperatureTrigger
    ) {

      temperatureFanRequestActive =
        true;
    }


    return;
  }


  if (
    latestTemperature
    <=
    cfgTemperatureReset
  ) {

    temperatureFanRequestActive =
      false;
  }
}


// ================================================================
// TEMPERATURE FAN AUTOMATION
// ================================================================

void handleTemperatureFan() {

  updateTemperatureFanRequest();


  // ============================================================
  // JUST ACTIVATED
  // ============================================================

  if (
    temperatureFanRequestActive
    &&
    !temperatureFanWasActive
  ) {

    temperatureFanWasActive =
      true;


    fanStateBeforeTemperature =
      fbFanOn;


    fanBrightnessBeforeTemperature =
      fbFanBrightness;


    requestFanState(
      true,
      FAN_AUTOMATION_SPEED
    );


#if ESP32_CREATES_TEMPERATURE_ALERT

    createTemperatureAlert();

#endif


    Serial.println();

    Serial.println(
      "=============================================="
    );


    Serial.println(
      "       HIGH TEMPERATURE AUTOMATION"
    );


    Serial.print(
      "Temperature : "
    );


    Serial.print(
      latestTemperature,
      1
    );


    Serial.println(
      " C"
    );


    Serial.print(
      "Trigger     : "
    );


    Serial.print(
      cfgTemperatureTrigger
    );


    Serial.println(
      " C"
    );


    Serial.println(
      "Virtual Fan : ON"
    );


    Serial.print(
      "Fan Speed   : "
    );


    Serial.print(
      FAN_AUTOMATION_SPEED
    );


    Serial.println(
      "%"
    );


    Serial.println(
      "=============================================="
    );


    lastFanEnforce =
      millis();


    return;
  }


  // ============================================================
  // REMAINS ACTIVE
  // ============================================================

  if (
    temperatureFanRequestActive
  ) {

    bool wrongFanState =
      (
        !fbFanOn
        ||
        fbFanBrightness
        !=
        FAN_AUTOMATION_SPEED
      );


    if (
      wrongFanState
      &&
      !fanSyncPending
      &&
      millis()
      -
      lastFanEnforce
      >=
      FAN_ENFORCE_INTERVAL
    ) {

      Serial.println(
        "[AUTO][TEMP] Restoring automatic fan state"
      );


      requestFanState(
        true,
        FAN_AUTOMATION_SPEED
      );


      lastFanEnforce =
        millis();
    }


    return;
  }


  // ============================================================
  // JUST RELEASED
  // ============================================================

  if (
    !temperatureFanRequestActive
    &&
    temperatureFanWasActive
  ) {

    temperatureFanWasActive =
      false;


    requestFanState(
      fanStateBeforeTemperature,

      fanBrightnessBeforeTemperature
    );


    Serial.println();

    Serial.println(
      "=============================================="
    );


    Serial.println(
      "     TEMPERATURE AUTOMATION RELEASED"
    );


    Serial.print(
      "Temperature : "
    );


    Serial.print(
      latestTemperature,
      1
    );


    Serial.println(
      " C"
    );


    Serial.print(
      "Reset Value : "
    );


    Serial.print(
      cfgTemperatureReset
    );


    Serial.println(
      " C"
    );


    Serial.println(
      "Previous manual Fan state restored"
    );


    Serial.println(
      "=============================================="
    );
  }
}


// ================================================================
// MANUAL RGB + BUZZER
// ================================================================

void handleManualBuzzerAndRgb() {

  if (
    gasEmergencyRequestActive
    ||
    gasActivationSyncPending
    ||
    gasResetPending
    ||
    gasReleasedThisCycle
  ) {

    return;
  }


  if (
    fbRgbOn
    !=
    currentRgbOn
  ) {

    Serial.print(
      "[MANUAL/FIREBASE] RGB -> "
    );


    Serial.println(
      fbRgbOn
        ? "ON"
        : "OFF"
    );
  }


  applyRgbLight(
    fbRgbOn
  );


  if (
    fbBuzzerOn
    !=
    currentBuzzerOn
  ) {

    Serial.print(
      "[MANUAL/FIREBASE] Buzzer -> "
    );


    Serial.println(
      fbBuzzerOn
        ? "ON"
        : "OFF"
    );
  }


  applyBuzzer(
    fbBuzzerOn
  );
}


// ================================================================
// MAIN CONTROL POLL
// ================================================================

void pollDeviceCommands() {

  Serial.println();

  Serial.println(
    "------ Checking App + Step 10F Automation ------"
  );


  if (
    millis()
    -
    lastConfigRefresh
    >=
    CONFIG_REFRESH_INTERVAL
  ) {

    refreshAutomationConfig();
  }


  readDeviceStates();


  serviceWhiteSyncRetry();

  serviceFanSyncRetry();


  // Priority 1
  handleGasEmergency();


  // Priority 2
  handleWhiteLightAutomation();


  // Priority 3
  handleTemperatureFan();


  // Priority 4
  handleManualBuzzerAndRgb();


  // Priority 5
  handleRainCurtain();


  // ============================================================
  // DEBUG
  // ============================================================

  Serial.println(
    "------------------------------------------------"
  );


  Serial.print(
    "Automation Master : "
  );


  Serial.println(
    cfgMasterEnabled
      ? "ON"
      : "OFF"
  );


  Serial.print(
    "Temperature       : "
  );


  if (
    latestTemperatureValid
  ) {

    Serial.print(
      latestTemperature,
      1
    );


    Serial.println(
      " C"
    );

  } else {

    Serial.println(
      "INVALID"
    );
  }


  Serial.print(
    "Temp Fan Rule     : "
  );


  Serial.println(
    cfgTemperatureFanEnabled
      ? "ENABLED"
      : "DISABLED"
  );


  Serial.print(
    "Temperature Fan   : "
  );


  Serial.println(
    temperatureFanRequestActive
      ? "ACTIVE"
      : "INACTIVE"
  );


  Serial.print(
    "Firebase Fan      : "
  );


  Serial.print(
    fbFanOn
      ? "ON"
      : "OFF"
  );


  Serial.print(
    " | "
  );


  Serial.print(
    fbFanBrightness
  );


  Serial.println(
    "%"
  );


  Serial.print(
    "Light Sensor      : "
  );


  Serial.print(
    latestIsDark
      ? "DARK"
      : "BRIGHT"
  );


  Serial.print(
    " ["
  );


  Serial.print(
    latestLightLevel
  );


  Serial.println(
    "]"
  );


  Serial.print(
    "Motion Filtered   : "
  );


  Serial.println(
    latestMotionDetected
      ? "MOTION"
      : "NO MOTION"
  );


  Serial.print(
    "Gas Filtered      : "
  );


  Serial.println(
    latestGasDetected
      ? "GAS DETECTED"
      : "NORMAL"
  );


  Serial.print(
    "Rain              : "
  );


  Serial.println(
    latestRainDetected
      ? "WET"
      : "DRY"
  );


  Serial.print(
    "Motion Request    : "
  );


  Serial.println(
    motionLightRequestActive
      ? "ACTIVE"
      : "INACTIVE"
  );


  Serial.print(
    "Low Light Request : "
  );


  Serial.println(
    lowLightRequestActive
      ? "ACTIVE"
      : "INACTIVE"
  );


  Serial.print(
    "Gas Request       : "
  );


  Serial.println(
    gasEmergencyRequestActive
      ? "EMERGENCY"
      : "INACTIVE"
  );


  Serial.print(
    "White Auto Owner  : "
  );


  Serial.println(
    whiteAutomationOwnsLight
      ? "YES"
      : "NO"
  );


  Serial.print(
    "White Sync        : "
  );


  Serial.println(
    whiteSyncPending
      ? "PENDING"
      : "OK"
  );


  Serial.print(
    "Gas Reset Sync    : "
  );


  Serial.println(
    gasResetPending
      ? "PENDING"
      : "OK"
  );


  Serial.print(
    "Fan Sync          : "
  );


  Serial.println(
    fanSyncPending
      ? "PENDING"
      : "OK"
  );


  Serial.println(
    "Door Twin         : ENABLED"
  );


  Serial.print(
    "Heartbeat Sync    : "
  );


  Serial.println(
    heartbeatSyncPending
      ? "PENDING"
      : "OK"
  );


  Serial.print(
    "Heartbeat Age     : "
  );


  if (
    lastHeartbeatSuccess > 0
  ) {

    Serial.print(
      (
        millis()
        -
        lastHeartbeatSuccess
      )
      /
      1000
    );


    Serial.println(
      " sec"
    );

  } else {

    Serial.println(
      "WAITING"
    );
  }


  Serial.print(
    "Async Queue Tasks : "
  );


  Serial.println(
    asyncClient.taskCount()
  );


  Serial.print(
    "Physical Buzzer   : "
  );


  Serial.println(
    currentBuzzerOn
      ? "ON"
      : "OFF"
  );


  Serial.print(
    "Firebase Buzzer   : "
  );


  Serial.println(
    fbBuzzerOn
      ? "ON"
      : "OFF"
  );
}


// ================================================================
// SENSOR UPLOAD
// ================================================================

void uploadSensors() {

  // ============================================================
  // DHT
  // ============================================================

  float temperature =
    dht.readTemperature();


  float humidity =
    dht.readHumidity();


  if (
    isnan(
      temperature
    )
    ||
    isnan(
      humidity
    )
  ) {

    Serial.println(
      "[SENSOR] DHT22 read failed"
    );


    return;
  }


  latestTemperature =
    temperature;


  latestHumidity =
    humidity;


  latestTemperatureValid =
    true;


  // ============================================================
  // RAIN
  // ============================================================

  int rainRaw =
    readRainAverage();


  latestRainDetected =
    (
      rainRaw
      <
      RAIN_THRESHOLD
    );


  // ============================================================
  // FILTERED VALUES
  // ============================================================

  bool motionValue =
    latestMotionDetected;


  int gasValue =
    latestGasDetected
      ? 1
      : 0;


  int lightValue =
    latestLightLevel;


  unsigned long long updatedAt =
    getTimestampMs();


  // ============================================================
  // SERIAL
  // ============================================================

  Serial.println();

  Serial.println(
    "================================================="
  );


  Serial.println(
    "         AURORA LIVE SENSOR DATA"
  );


  Serial.println(
    "================================================="
  );


  Serial.print(
    "Temperature : "
  );


  Serial.print(
    temperature,
    1
  );


  Serial.println(
    " C"
  );


  Serial.print(
    "Humidity    : "
  );


  Serial.print(
    humidity,
    1
  );


  Serial.println(
    " %"
  );


  Serial.print(
    "Motion      : "
  );


  Serial.println(
    motionValue
      ? "DETECTED"
      : "NO MOTION"
  );


  Serial.print(
    "Room Light  : "
  );


  Serial.print(
    latestIsDark
      ? "DARK"
      : "BRIGHT"
  );


  Serial.print(
    " ["
  );


  Serial.print(
    lightValue
  );


  Serial.println(
    "]"
  );


  Serial.print(
    "Rain        : "
  );


  Serial.print(
    latestRainDetected
      ? "WET"
      : "DRY"
  );


  Serial.print(
    " [RAW="
  );


  Serial.print(
    rainRaw
  );


  Serial.println(
    "]"
  );


  Serial.print(
    "Gas         : "
  );


  Serial.println(
    latestGasDetected
      ? "DETECTED [FILTERED]"
      : "NORMAL [FILTERED]"
  );


  // ============================================================
  // JSON
  // ============================================================

  object_t sensorJson;


  object_t objTemperature;

  object_t objHumidity;

  object_t objGas;

  object_t objMotion;

  object_t objRain;

  object_t objLight;

  object_t objUpdatedAt;


  JsonWriter writer;


  writer.create(
    objTemperature,

    "temperature",

    number_t(
      temperature,
      1
    )
  );


  writer.create(
    objHumidity,

    "humidity",

    number_t(
      humidity,
      1
    )
  );


  writer.create(
    objGas,

    "gas",

    gasValue
  );


  writer.create(
    objMotion,

    "motion",

    boolean_t(
      motionValue
    )
  );


  writer.create(
    objRain,

    "rain",

    boolean_t(
      latestRainDetected
    )
  );


  writer.create(
    objLight,

    "lightLevel",

    lightValue
  );


  writer.create(
    objUpdatedAt,

    "updatedAt",

    number_t(
      (double)updatedAt,
      0
    )
  );


  writer.join(
    sensorJson,
    7,

    objTemperature,
    objHumidity,
    objGas,
    objMotion,
    objRain,
    objLight,
    objUpdatedAt
  );


  // ============================================================
  // QUEUE SAFETY
  // ============================================================

  size_t queueCount =
    asyncClient.taskCount();


  if (
    queueCount
    >=
    SAFE_ASYNC_TASK_LIMIT
  ) {

    Serial.print(
      "[FIREBASE] Sensor upload deferred. Queue = "
    );


    Serial.println(
      queueCount
    );


    return;
  }


  Database.update<object_t>(
    asyncClient,

    "/rooms/room_01/sensors",

    sensorJson,

    processData,

    "sensorUpdate"
  );


  Serial.print(
    "Sensor data queued. Async queue = "
  );


  Serial.println(
    asyncClient.taskCount()
  );
}


// ================================================================
// INITIAL ONLINE STATUS
// ================================================================

void synchronizeOnlineStatus() {

  // ============================================================
  // PHYSICAL DEVICE ONLINE STATES
  // ============================================================

  object_t patch;


  object_t objWhite;

  object_t objRgb;

  object_t objBuzzer;

  object_t objCurtain;


  JsonWriter writer;


  writer.create(
    objWhite,

    "devices/whiteLight/isOnline",

    boolean_t(true)
  );


  writer.create(
    objRgb,

    "devices/rgbLight/isOnline",

    boolean_t(true)
  );


  writer.create(
    objBuzzer,

    "devices/buzzer/isOnline",

    boolean_t(true)
  );


  writer.create(
    objCurtain,

    "devices/curtain/isOnline",

    boolean_t(true)
  );


  writer.join(
    patch,
    4,

    objWhite,
    objRgb,
    objBuzzer,
    objCurtain
  );


  syncUpdateObject(
    "/rooms/room_01",

    patch,

    "Physical devices ONLINE"
  );


  // ============================================================
  // INITIAL HEARTBEAT
  // ============================================================

  writeHeartbeat();
}


// ================================================================
// INITIAL FILTER VALUES
// ================================================================

void initializeInputFilters() {

  unsigned long now =
    millis();


  motionCandidate =
    (
      digitalRead(
        PIR_PIN
      )
      ==
      HIGH
    );


  motionCandidateSince =
    now;


  latestMotionDetected =
    false;


  gasCandidate =
    (
      digitalRead(
        GAS_PIN
      )
      ==
      LOW
    );


  gasCandidateSince =
    now;


  latestGasDetected =
    false;


  darkCandidate =
    (
      digitalRead(
        LDR_PIN
      )
      ==
      HIGH
    );


  darkCandidateSince =
    now;


  latestIsDark =
    darkCandidate;


  latestLightLevel =
    latestIsDark
      ? 0
      : 100;
}


// ================================================================
// SETUP
// ================================================================

void setup() {

  Serial.begin(
    115200
  );


  delay(
    1000
  );


  Serial.println();

  Serial.println(
    "================================================="
  );


  Serial.println(
    "          AURORA SMART LIVING"
  );


  Serial.println(
    " STEP 10F - AUTOMATION + REAL HEARTBEAT"
  );


  Serial.println(
    "================================================="
  );


  // ============================================================
  // SENSORS
  // ============================================================

  dht.begin();


  pinMode(
    PIR_PIN,
    INPUT
  );


  pinMode(
    LDR_PIN,
    INPUT
  );


  pinMode(
    GAS_PIN,
    INPUT
  );


  analogReadResolution(
    12
  );


  analogSetPinAttenuation(
    RAIN_PIN,
    ADC_11db
  );


  // ============================================================
  // BUZZER
  // ============================================================

  pinMode(
    BUZZER_PIN,
    OUTPUT
  );


  digitalWrite(
    BUZZER_PIN,
    LOW
  );


  // ============================================================
  // RGB RELAY
  // ============================================================

  pinMode(
    RGB_RELAY_PIN,
    OUTPUT
  );


  // Active LOW -> HIGH means OFF.
  digitalWrite(
    RGB_RELAY_PIN,
    HIGH
  );


  // ============================================================
  // WHITE LIGHT
  // ============================================================

  ledcAttach(
    WHITE_LED_PIN,
    5000,
    8
  );


  ledcWrite(
    WHITE_LED_PIN,
    0
  );


  // ============================================================
  // SERVO
  // ============================================================

  curtainServo.setPeriodHertz(
    50
  );


  curtainServo.attach(
    SERVO_PIN,
    500,
    2400
  );


  curtainServo.write(
    90
  );


  initializeInputFilters();


  // ============================================================
  // WIFI
  // ============================================================

  Serial.print(
    "Connecting to Wi-Fi"
  );


  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );


  while (
    WiFi.status()
    !=
    WL_CONNECTED
  ) {

    Serial.print(
      "."
    );


    delay(
      500
    );
  }


  Serial.println();


  Serial.println(
    "Wi-Fi connected!"
  );


  Serial.print(
    "ESP32 IP: "
  );


  Serial.println(
    WiFi.localIP()
  );


  // ============================================================
  // NTP
  //
  // Still useful for alert IDs / current sensor updatedAt.
  //
  // Heartbeat does NOT depend on this.
  // ============================================================

  Serial.print(
    "Synchronizing time"
  );


  configTime(
    0,
    0,
    "pool.ntp.org",
    "time.nist.gov"
  );


  time_t now =
    time(nullptr);


  int attempts =
    0;


  while (
    now < 1000000000
    &&
    attempts < 20
  ) {

    Serial.print(
      "."
    );


    delay(
      500
    );


    now =
      time(nullptr);


    attempts++;
  }


  Serial.println();


  if (
    now >= 1000000000
  ) {

    Serial.println(
      "Time synchronized!"
    );

  } else {

    Serial.println(
      "WARNING: Time synchronization failed."
    );


    Serial.println(
      "Heartbeat will still work using Firebase server time."
    );
  }


  // ============================================================
  // SSL
  // ============================================================

  sslAsync.setInsecure();


  sslControl.setInsecure();


  sslAsync.setConnectionTimeout(
    1000
  );


  sslAsync.setHandshakeTimeout(
    5
  );


  sslControl.setConnectionTimeout(
    1000
  );


  sslControl.setHandshakeTimeout(
    5
  );


  // ============================================================
  // FIREBASE
  // ============================================================

  Serial.println(
    "Connecting to Firebase..."
  );


  initializeApp(
    asyncClient,

    app,

    getAuth(
      userAuth
    ),

    processData,

    "authTask"
  );


  app.getApp<RealtimeDatabase>(
    Database
  );


  Database.url(
    DATABASE_URL
  );
}


// ================================================================
// LOOP
// ================================================================

void loop() {

  // Local sensors remain independent of Firebase.
  updateFilteredInputs();


  // Firebase auth/background handling.
  app.loop();

  Database.loop();


  // ============================================================
  // FIRST FIREBASE READY
  // ============================================================

  if (
    app.ready()
    &&
    !firebaseStarted
  ) {

    firebaseStarted =
      true;


    Serial.println();

    Serial.println(
      "Firebase authenticated!"
    );


    synchronizeOnlineStatus();


    refreshAutomationConfig();


    readDeviceStates();


    // Initial DHT state.
    float startupTemperature =
      dht.readTemperature();


    float startupHumidity =
      dht.readHumidity();


    if (
      !isnan(
        startupTemperature
      )
      &&
      !isnan(
        startupHumidity
      )
    ) {

      latestTemperature =
        startupTemperature;


      latestHumidity =
        startupHumidity;


      latestTemperatureValid =
        true;
    }


    lastSensorUpload =
      millis()
      -
      SENSOR_UPLOAD_INTERVAL;


    lastControlPoll =
      millis()
      -
      CONTROL_POLL_INTERVAL;


    lastConfigRefresh =
      millis();
  }


  // ============================================================
  // HEARTBEAT
  //
  // Do this BEFORE slower device polling.
  // ============================================================

  if (
    app.ready()
  ) {

    serviceHeartbeat();
  }


  // ============================================================
  // SENSOR UPLOAD
  // ============================================================

  if (
    app.ready()
    &&
    millis()
    -
    lastSensorUpload
    >=
    SENSOR_UPLOAD_INTERVAL
  ) {

    lastSensorUpload =
      millis();


    uploadSensors();
  }


  // ============================================================
  // FIREBASE + AUTOMATION
  // ============================================================

  if (
    app.ready()
    &&
    millis()
    -
    lastControlPoll
    >=
    CONTROL_POLL_INTERVAL
  ) {

    lastControlPoll =
      millis();


    pollDeviceCommands();
  }
}
