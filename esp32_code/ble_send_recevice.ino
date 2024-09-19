#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID        "295a8771-1529-4765-950f-a5fdb3e4537c"
#define CHARACTERISTIC_UUID "295a8771-1529-4765-950f-a5fdb3e4537c"

// 用來儲存接收到的完整訊息
String completeMessage = "";  

// 自定義回呼類別，處理接收資料
class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();  // 取得原始資料
    size_t length = pCharacteristic->getLength();  // 資料長度

    if (length > 0) {
      Serial.println("*********");
      Serial.print("New value: ");

      // 將每個字節轉換為 ASCII 字符並印出
      for (int i = 0; i < length; i++) {
        Serial.print((char)data[i]);  // 轉換為 ASCII 字符並顯示
        completeMessage += (char)data[i];  // 將新接收到的資料附加到 completeMessage
      }

      Serial.println();
      Serial.println("*********");

      // 檢查是否有接收到換行符號，表示訊息已完整
      if (completeMessage.indexOf('\n') >= 0) {
        // 處理完整的訊息
        Serial.print("Complete message received: ");
        Serial.println(completeMessage);

        // 判斷是否為 "ON" 命令
        if (completeMessage.startsWith("ON")) {
          Serial.println("Received 'ON' command");
        } else {
          Serial.println("Received something else");
        }

        // 清空 completeMessage，準備接收下一條訊息
        completeMessage = "";
      }
    }
  }
};

// 針對傳輸的 characteristic
BLECharacteristic *pCharacteristic;

void setup() {
  // 初始化串口監視器
  Serial.begin(115200);

  // 藍牙初始化
  Serial.println("1- Download and install a BLE scanner app on your phone");
  Serial.println("2- Scan for BLE devices in the app");
  Serial.println("3- Connect to MyESP32");
  Serial.println("4- Go to CUSTOM CHARACTERISTIC in CUSTOM SERVICE and write something");
  Serial.println("5- See the magic =)");

  // 設定藍牙裝置名稱
  BLEDevice::init("MyESP32");
  BLEServer *pServer = BLEDevice::createServer();

  // 創建藍牙服務
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 創建藍牙 characteristic，設定其屬性為可讀取、可寫入、可通知
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | 
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // 設定回呼函數，處理接收到的資料
  pCharacteristic->setCallbacks(new MyCallbacks());

  // 設定初始值
  pCharacteristic->setValue("Hello from ESP32");
  
  // 啟動服務
  pService->start();

  // 開始廣播藍牙訊號
  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->start();
}

void loop() {
  // 主程式循環中可以放其他的應用邏輯
  
  // 每隔5秒發送一個訊息
  delay(5000);

  // 設定要傳送的訊息
  String message = "ESP32 sending data!";
  
  // 設定 characteristic 的值
  pCharacteristic->setValue(message.c_str());
  
  // 通知連接的裝置
  pCharacteristic->notify();
  
  Serial.println("Sent message: " + message);
}
