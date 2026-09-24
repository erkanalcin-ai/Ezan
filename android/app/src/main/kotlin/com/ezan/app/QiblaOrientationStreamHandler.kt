package com.ezan.app

import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.plugin.common.EventChannel
import kotlin.math.sqrt

internal class QiblaOrientationStreamHandler(
    private val activity: MainActivity,
) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager = activity.getSystemService(SensorManager::class.java)
    private val rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private var eventSink: EventChannel.EventSink? = null
    private var latitude = 0.0
    private var longitude = 0.0
    private var rotationAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private var accelerometerAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private var magnetometerAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private var rotationMatrix = FloatArray(9)
    private var remappedRotationMatrix = FloatArray(9)
    private var orientation = FloatArray(3)
    private var accelerometerValues: FloatArray? = null
    private var magneticValues: FloatArray? = null
    private var hasRotationVector = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val coordinates = arguments as? Map<*, *>
        latitude = (coordinates?.get("latitude") as? Number)?.toDouble() ?: 0.0
        longitude = (coordinates?.get("longitude") as? Number)?.toDouble() ?: 0.0
        eventSink = events
        hasRotationVector = rotationSensor != null

        if (hasRotationVector) {
            sensorManager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_GAME)
        } else {
            accelerometer?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
        }
        magnetometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }

        if (magnetometer == null || (!hasRotationVector && accelerometer == null)) {
            events.error("SENSORS_UNAVAILABLE", "A rotation vector or fallback sensors are unavailable.", null)
            stop()
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        eventSink = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        when (sensor?.type) {
            Sensor.TYPE_ROTATION_VECTOR -> rotationAccuracy = accuracy
            Sensor.TYPE_ACCELEROMETER -> accelerometerAccuracy = accuracy
            Sensor.TYPE_MAGNETIC_FIELD -> magnetometerAccuracy = accuracy
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                rotationAccuracy = event.accuracy
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
            }
            Sensor.TYPE_ACCELEROMETER -> {
                accelerometerAccuracy = event.accuracy
                accelerometerValues = event.values.clone()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magnetometerAccuracy = event.accuracy
                magneticValues = event.values.clone()
            }
        }

        if (hasRotationVector) {
            if (event.sensor.type != Sensor.TYPE_ROTATION_VECTOR &&
                event.sensor.type != Sensor.TYPE_MAGNETIC_FIELD
            ) return
        } else if (event.sensor.type != Sensor.TYPE_ACCELEROMETER &&
            event.sensor.type != Sensor.TYPE_MAGNETIC_FIELD
        ) return

        val field = magneticValues ?: return
        if (!hasRotationVector) {
            val gravity = accelerometerValues ?: return
            if (!SensorManager.getRotationMatrix(rotationMatrix, null, gravity, field)) return
        }

        val axes = displayAxes()
        if (!SensorManager.remapCoordinateSystem(
                rotationMatrix,
                axes.first,
                axes.second,
                remappedRotationMatrix,
            )
        ) return
        SensorManager.getOrientation(remappedRotationMatrix, orientation)

        val magneticAzimuth = Math.toDegrees(orientation[0].toDouble())
        val fieldModel = GeomagneticField(
            latitude.toFloat(),
            longitude.toFloat(),
            0f,
            System.currentTimeMillis(),
        )
        val trueAzimuth = normalize(magneticAzimuth + fieldModel.declination)
        val observedStrength = sqrt(
            field[0] * field[0] + field[1] * field[1] + field[2] * field[2],
        ).toDouble()
        // GeomagneticField components are nT; TYPE_MAGNETIC_FIELD reports μT.
        val expectedStrength = sqrt(
            fieldModel.x * fieldModel.x +
                fieldModel.y * fieldModel.y +
                fieldModel.z * fieldModel.z,
        ).toDouble() / 1000.0
        val accuracyIsReliable = if (hasRotationVector) {
            rotationAccuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM &&
                magnetometerAccuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
        } else {
            accelerometerAccuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM &&
                magnetometerAccuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
        }
        eventSink?.success(
            mapOf(
                "azimuthDegrees" to trueAzimuth,
                "hasSensorAccuracy" to accuracyIsReliable,
                "magneticFieldStrengthMicroTesla" to observedStrength,
                "expectedFieldStrengthMicroTesla" to expectedStrength,
            ),
        )
    }

    @Suppress("DEPRECATION")
    private fun displayAxes(): Pair<Int, Int> = when (activity.windowManager.defaultDisplay.rotation) {
        Surface.ROTATION_90 -> Pair(SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X)
        Surface.ROTATION_180 -> Pair(SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y)
        Surface.ROTATION_270 -> Pair(SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X)
        else -> Pair(SensorManager.AXIS_X, SensorManager.AXIS_Y)
    }

    private fun normalize(degrees: Double): Double = (degrees % 360 + 360) % 360

}
