/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleWrite.cpp
    Ported to Arduino ESP32 by Evandro Copercini
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID        "295a8771-1529-4765-950f-a5fdb3e4537c"
#define CHARACTERISTIC_UUID "295a8771-1529-4765-950f-a5fdb3e4537c"

// class MyCallbacks : public BLECharacteristicCallbacks {
//   void onWrite(BLECharacteristic *pCharacteristic) {
//     String value = pCharacteristic->getValue();

//     if (value.length() > 0) {
//       Serial.println("*********");
//       Serial.print("New value: ");
//       for (int i = 0; i < value.length(); i++) {
//         Serial.print(value[i]);
//       }

//       Serial.println();
//       Serial.println("*********");
//     }
//   }
// };

// class MyCallbacks : public BLECharacteristicCallbacks {
//   void onWrite(BLECharacteristic *pCharacteristic) {
//     // 使用 getData() 來取得原始的二進位資料
//     uint8_t* data = pCharacteristic->getData();  
//     size_t length = pCharacteristic->getLength();  // 取得資料的長度

//     if (length > 0) {
//       Serial.println("*********");
//       Serial.print("New value: ");

//       // 逐字節印出資料，使用十六進位格式
//       for (int i = 0; i < length; i++) {
//         Serial.print("0x");
//         Serial.print(data[i], HEX);  // 以十六進位格式印出
//         Serial.print(" ");
//       }

//       Serial.println();
//       Serial.println("*********");
//     }
//   }
// };

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();  // 取得原始資料
    size_t length = pCharacteristic->getLength();  // 資料長度

    if (length > 0) {
      Serial.println("*********");
      Serial.print("New value: ");

      // 將每個字節轉換為 ASCII 字符並印出
      String receivedValue = "";
      for (int i = 0; i < length; i++) {
        Serial.print((char)data[i]);  // 轉換為 ASCII 字符並顯示
        receivedValue += (char)data[i];  // 將字符加到字串中
      }

      Serial.println();
      Serial.println("*********");

      // 判斷接收到的字串是否為 "ON"
      if (receivedValue == "ON") {
        Serial.println("Received 'ON' command");
      } else {
        Serial.println("Received something else");
      }
    }
  }
};


void setup() {
  Serial.begin(115200);

  Serial.println("1- Download and install an BLE scanner app in your phone");
  Serial.println("2- Scan for BLE devices in the app");
  Serial.println("3- Connect to MyESP32");
  Serial.println("4- Go to CUSTOM CHARACTERISTIC in CUSTOM SERVICE and write something");
  Serial.println("5- See the magic =)");

  BLEDevice::init("MyESP32");
  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService(SERVICE_UUID);

  BLECharacteristic *pCharacteristic =
    pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);

  pCharacteristic->setCallbacks(new MyCallbacks());

  pCharacteristic->setValue("Hello World");
  pService->start();

  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->start();
}

void loop() {
  // put your main code here, to run repeatedly:
  delay(2000);
}
