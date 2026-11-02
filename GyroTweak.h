#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Инициализация гироскопа. Возвращает 0 при успехе, -1 при ошибке.
int GyroTweak_Init(void);

// Остановка и очистка.
void GyroTweak_Shutdown(void);

// Получить текущие данные гироскопа (рад/сек).
// Возвращает 0 при успехе, -1 если не инициализирован.
int GyroTweak_GetRotationRate(float* outX, float* outY, float* outZ);

// Получить данные акселерометра (в g).
int GyroTweak_GetAcceleration(float* outX, float* outY, float* outZ);

// Получить ориентацию устройства (quaternion).
int GyroTweak_GetAttitudeQuaternion(float* outX, float* outY, float* outZ, float* outW);

// Проверить, доступен ли гироскоп на устройстве.
int GyroTweak_IsAvailable(void);

// Чувствительность (мультипликатор для gyro/accel). Диапазон 0.1–5.0.
float GyroTweak_GetSensitivity(void);
void GyroTweak_SetSensitivity(float value);

#ifdef __cplusplus
}
#endif
