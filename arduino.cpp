#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

BLECharacteristic *pCharacteristic;
void setup() {
    Serial.begin(115200);
    BLEDevice::init("ESP32_Sensor");

    BLEServer *pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(BLEUUID("12345678-1234-5678-1234-56789abcdef0"));

    pCharacteristic = pService->createCharacteristic(
        BLEUUID("87654321-4321-6789-4321-fedcba987654"),
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );

    pCharacteristic->setValue("0"); // Default value
    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(pService->getUUID());
    pAdvertising->start();
}

void loop() {
    int sensorValue = analogRead(34);
    pCharacteristic->setValue(String(sensorValue).c_str());
    pCharacteristic->notify();
    delay(1000);
}
