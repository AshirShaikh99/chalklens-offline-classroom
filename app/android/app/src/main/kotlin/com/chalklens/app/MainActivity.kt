package com.chalklens.app

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val audioPermissionRequestCode = 8419
    private val audioLock = Any()
    private var audioRecorder: AudioRecord? = null
    private var audioThread: Thread? = null
    private var audioBytes: ByteArrayOutputStream? = null
    private var pendingAudioStartResult: MethodChannel.Result? = null
    @Volatile private var isRecordingAudio = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "chalk_lens/storage"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "availableStorageBytes" -> {
                    val stat = StatFs(filesDir.absolutePath)
                    result.success(stat.availableBytes)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "chalk_lens/audio_recorder"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> startAudioRecording(result)
                "stop" -> stopAudioRecording(result)
                "cancel" -> cancelAudioRecording(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != audioPermissionRequestCode) return

        val result = pendingAudioStartResult ?: return
        pendingAudioStartResult = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            startAudioRecording(result)
        } else {
            result.error(
                "permissionDenied",
                "Microphone permission was denied.",
                null
            )
        }
    }

    private fun startAudioRecording(result: MethodChannel.Result) {
        if (isRecordingAudio) {
            result.error("alreadyRecording", "Voice recording is already running.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingAudioStartResult = result
            requestPermissions(
                arrayOf(Manifest.permission.RECORD_AUDIO),
                audioPermissionRequestCode
            )
            return
        }

        val sampleRate = 16000
        val minBufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufferSize <= 0) {
            result.error("recorderUnavailable", "Microphone recorder is unavailable.", null)
            return
        }

        val bufferSize = max(minBufferSize, sampleRate / 2)
        val recorder = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )
        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            result.error("recorderUnavailable", "Microphone recorder could not start.", null)
            return
        }

        synchronized(audioLock) {
            audioBytes = ByteArrayOutputStream()
            audioRecorder = recorder
        }
        isRecordingAudio = true

        try {
            recorder.startRecording()
        } catch (e: IllegalStateException) {
            isRecordingAudio = false
            recorder.release()
            synchronized(audioLock) {
                audioRecorder = null
                audioBytes = null
            }
            result.error("recorderUnavailable", "Microphone recorder could not start.", null)
            return
        }

        audioThread = Thread {
            val buffer = ByteArray(bufferSize)
            while (isRecordingAudio) {
                val read = recorder.read(buffer, 0, buffer.size)
                if (read > 0) {
                    synchronized(audioLock) {
                        audioBytes?.write(buffer, 0, read)
                    }
                }
            }
        }.also { it.start() }

        result.success(null)
    }

    private fun stopAudioRecording(result: MethodChannel.Result) {
        val recorder = audioRecorder
        if (!isRecordingAudio || recorder == null) {
            result.error("notRecording", "No voice recording is active.", null)
            return
        }

        isRecordingAudio = false
        try {
            recorder.stop()
        } catch (_: IllegalStateException) {
            // The read loop may already have wound down.
        }
        try {
            audioThread?.join(900)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
        recorder.release()

        val pcm = synchronized(audioLock) {
            val bytes = audioBytes?.toByteArray() ?: ByteArray(0)
            audioRecorder = null
            audioThread = null
            audioBytes = null
            bytes
        }

        if (pcm.isEmpty()) {
            result.error("emptyRecording", "No voice was recorded.", null)
            return
        }

        result.success(wavFromPcm(pcm, sampleRate = 16000, channels = 1))
    }

    private fun cancelAudioRecording(result: MethodChannel.Result) {
        val recorder = audioRecorder
        isRecordingAudio = false
        try {
            recorder?.stop()
        } catch (_: IllegalStateException) {
        }
        recorder?.release()
        synchronized(audioLock) {
            audioRecorder = null
            audioThread = null
            audioBytes = null
        }
        result.success(null)
    }

    private fun wavFromPcm(
        pcm: ByteArray,
        sampleRate: Int,
        channels: Int,
    ): ByteArray {
        val bitsPerSample = 16
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val dataSize = pcm.size
        val totalSize = 36 + dataSize
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray(Charsets.US_ASCII))
        header.putInt(totalSize)
        header.put("WAVE".toByteArray(Charsets.US_ASCII))
        header.put("fmt ".toByteArray(Charsets.US_ASCII))
        header.putInt(16)
        header.putShort(1.toShort())
        header.putShort(channels.toShort())
        header.putInt(sampleRate)
        header.putInt(byteRate)
        header.putShort(blockAlign.toShort())
        header.putShort(bitsPerSample.toShort())
        header.put("data".toByteArray(Charsets.US_ASCII))
        header.putInt(dataSize)
        return header.array() + pcm
    }
}
