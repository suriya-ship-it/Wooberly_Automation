import { spawn, execSync, ChildProcess } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { DeviceManager } from './DeviceManager';

export interface VideoRecorderOptions {
    testName?: string;
    outputDir?: string;
    bitRate?: number; // bits per second, default 6000000 (6Mbps)
    timeLimit?: number; // 0 = unlimited on Android 14+
}

export class VideoRecorder {
    private static isRecordingActive = false;
    private static currentProcess: ChildProcess | null = null;
    private static remoteCurrentFile = '';
    private static segmentIndex = 1;
    private static collectedSegments: string[] = [];
    private static watchdogTimer: NodeJS.Timeout | null = null;
    private static activeOptions: VideoRecorderOptions = {};
    private static startTime = 0;
    private static isParentOwner = false;

    private static readonly DEFAULT_FOLDER = 'Test reference';
    private static readonly ROOT_DIR = path.resolve(__dirname, '../');

    /**
     * Resolves the output directory path (ROOT/Test reference by default).
     */
    public static getOutputDir(customFolder?: string): string {
        const folder = customFolder || this.DEFAULT_FOLDER;
        const fullPath = path.isAbsolute(folder)
            ? folder
            : path.join(this.ROOT_DIR, folder);

        if (!fs.existsSync(fullPath)) {
            fs.mkdirSync(fullPath, { recursive: true });
        }
        return fullPath;
    }

    /**
     * Formats a timestamp string: YYYY-MM-DD_HH-mm-ss
     */
    private static getTimestamp(): string {
        const d = new Date();
        const pad = (n: number) => String(n).padStart(2, '0');
        const dateStr = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
        const timeStr = `${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
        return `${dateStr}_${timeStr}`;
    }

    /**
     * Starts continuous video recording of the device display.
     * Starts immediately after phone wakeup and runs until stopRecording() is called.
     */
    public static async startRecording(options: VideoRecorderOptions = {}): Promise<boolean> {
        // If video recording is disabled via env var, skip all recording logic
        if (process.env.VIDEO_RECORDING_DISABLED === 'true') {
            console.log('[VideoRecorder] Recording disabled – skipping startRecording.');
            return false;
        }
        // If an outer workflow (like step2) is already recording, skip child recording to prevent encoder clash
        if (process.env.VIDEO_RECORDING_ACTIVE === 'true' && !this.isParentOwner) {
            console.log('[VideoRecorder] Parent workflow recording is already active. Skipping child recorder.');
            return false;
        }

        if (this.isRecordingActive) {
            console.log('[VideoRecorder] Recording is already running.');
            return true;
        }

        this.activeOptions = {
            testName: options.testName || 'workflow_execution',
            outputDir: options.outputDir || this.getOutputDir(),
            bitRate: options.bitRate || 6000000,
            timeLimit: options.timeLimit !== undefined ? options.timeLimit : 0,
        };

        this.isRecordingActive = true;
        this.isParentOwner = true;
        this.segmentIndex = 1;
        this.collectedSegments = [];
        this.startTime = Date.now();
        process.env.VIDEO_RECORDING_ACTIVE = 'true';

        console.log('\n========================================================================');
        console.log('🎥 [VideoRecorder] Starting Video Recording of Automation Execution');
        console.log(`Target Folder:  ${this.activeOptions.outputDir}`);
        console.log(`Video Name:     ${this.activeOptions.testName}`);
        console.log('========================================================================\n');

        // Clean any leftover screenrecord processes on device
        this.killDeviceScreenrecord();

        // Launch first recording segment
        this.launchSegment(this.segmentIndex);

        // Start watchdog to handle any unexpected device process termination
        this.startWatchdog();

        // Setup process exit handler for graceful cleanup
        this.registerExitHook();

        return true;
    }

    /**
     * Spawns screenrecord on Android via ADB.
     */
    private static launchSegment(index: number): void {
        this.remoteCurrentFile = `/sdcard/active_rec_seg_${index}.mp4`;
        DeviceManager.runAdb(`shell rm -f ${this.remoteCurrentFile}`);

        const bitRate = this.activeOptions.bitRate || 6000000;
        const timeLimit = this.activeOptions.timeLimit !== undefined ? this.activeOptions.timeLimit : 0;

        const cmd = `screenrecord --bit-rate ${bitRate} --time-limit ${timeLimit} ${this.remoteCurrentFile}`;
        console.log(`[VideoRecorder] Spawning device screenrecord segment #${index}...`);

        this.currentProcess = spawn('adb', ['shell', cmd], {
            stdio: 'ignore',
            detached: false,
        });

        this.currentProcess.on('error', (err) => {
            console.warn('[VideoRecorder] ADB spawn warning:', err?.message || err);
        });
    }

    /**
     * Periodically verifies screenrecord is still running on device.
     * If Android stops the process (e.g. system timeout or memory recycle),
     * automatically pulls the current segment and starts the next one.
     */
    private static startWatchdog(): void {
        if (this.watchdogTimer) clearInterval(this.watchdogTimer);

        this.watchdogTimer = setInterval(() => {
            if (!this.isRecordingActive) return;

            const check = DeviceManager.runAdb('shell pidof screenrecord');
            if (!check || check.trim() === '') {
                // screenrecord exited on device unexpectedly
                console.log(`[VideoRecorder] Segment #${this.segmentIndex} completed. Capturing segment and continuing...`);
                this.captureCurrentSegment();
                this.segmentIndex++;
                this.launchSegment(this.segmentIndex);
            }
        }, 5000);
    }

    /**
     * Pulls the currently finished segment from the device into temporary storage.
     */
    private static captureCurrentSegment(): void {
        const tempSegmentDir = path.join(this.getOutputDir(), '.tmp_segments');
        if (!fs.existsSync(tempSegmentDir)) fs.mkdirSync(tempSegmentDir, { recursive: true });

        const localSegmentFile = path.join(tempSegmentDir, `segment_${this.segmentIndex}_${Date.now()}.mp4`);
        try {
            DeviceManager.runAdb(`pull ${this.remoteCurrentFile} "${localSegmentFile}"`);
            DeviceManager.runAdb(`shell rm -f ${this.remoteCurrentFile}`);
            if (fs.existsSync(localSegmentFile) && fs.statSync(localSegmentFile).size > 1000) {
                this.collectedSegments.push(localSegmentFile);
                console.log(`[VideoRecorder] Cached segment #${this.segmentIndex} (${(fs.statSync(localSegmentFile).size / 1024).toFixed(1)} KB)`);
            }
        } catch (err: any) {
            console.warn('[VideoRecorder] Failed to pull segment:', err?.message || err);
        }
    }

    /**
     * Sends SIGINT (kill -2) to screenrecord on device to allow it to finalize the MP4 file header.
     */
    private static killDeviceScreenrecord(): void {
        try {
            DeviceManager.runAdb("shell 'pkill -2 -f screenrecord'");
        } catch {}
    }

    /**
     * Stops video recording, pulls all video segments from device,
     * merges if multiple segments exist, and saves the final MP4 in 'Test reference'.
     */
    public static async stopRecording(): Promise<string | null> {
        if (!this.isRecordingActive || !this.isParentOwner) {
            return null;
        }

        console.log('\n========================================================================');
        console.log('🎥 [VideoRecorder] Stopping Video Recording & Finalizing MP4 File...');
        console.log('========================================================================');

        if (this.watchdogTimer) {
            clearInterval(this.watchdogTimer);
            this.watchdogTimer = null;
        }

        this.isRecordingActive = false;
        delete process.env.VIDEO_RECORDING_ACTIVE;

        // Signal screenrecord to finish gracefully
        this.killDeviceScreenrecord();

        // Wait 2 seconds for Android to finalize the moov box
        await new Promise((r) => setTimeout(r, 2000));

        // Pull the final segment
        this.captureCurrentSegment();

        const outputDir = this.activeOptions.outputDir || this.getOutputDir();
        const baseName = this.activeOptions.testName || 'workflow_execution';
        const timestamp = this.getTimestamp();
        const finalFilename = `${baseName}_${timestamp}.mp4`;
        const finalFilePath = path.join(outputDir, finalFilename);
        const latestFilePath = path.join(outputDir, `${baseName}_latest.mp4`);
        const genericLatestPath = path.join(outputDir, 'latest_execution.mp4');

        if (this.collectedSegments.length === 0) {
            console.warn('⚠️ [VideoRecorder] No video segments were captured.');
            return null;
        }

        if (this.collectedSegments.length === 1) {
            // Single segment: simply move it to the final destination
            fs.copyFileSync(this.collectedSegments[0], finalFilePath);
        } else {
            // Multiple segments: concatenate with ffmpeg stream-copy
            console.log(`[VideoRecorder] Concatenating ${this.collectedSegments.length} segments with ffmpeg...`);
            this.concatenateSegments(this.collectedSegments, finalFilePath);
        }

        // Clean up temp segment files
        const tempSegmentDir = path.join(outputDir, '.tmp_segments');
        try {
            if (fs.existsSync(tempSegmentDir)) {
                fs.rmSync(tempSegmentDir, { recursive: true, force: true });
            }
        } catch {}

        // Create convenient "latest" copies
        try {
            fs.copyFileSync(finalFilePath, latestFilePath);
            fs.copyFileSync(finalFilePath, genericLatestPath);
        } catch {}

        // Also copy to artifact directory if present
        const artifactDir = process.env.ARTIFACT_DIR;
        if (artifactDir && fs.existsSync(artifactDir)) {
            try {
                fs.copyFileSync(finalFilePath, path.join(artifactDir, finalFilename));
            } catch {}
        }

        const durationSec = Math.round((Date.now() - this.startTime) / 1000);
        const mins = Math.floor(durationSec / 60);
        const secs = durationSec % 60;
        const durationStr = `${mins}m ${secs}s`;

        const stats = fs.statSync(finalFilePath);
        const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);

        console.log('\n========================================================================');
        console.log('✅ 🎥 [VideoRecorder] Video Reference Recorded Successfully!');
        console.log(`Saved Video:   ${finalFilePath}`);
        console.log(`Latest Copy:   ${latestFilePath}`);
        console.log(`File Size:     ${sizeMB} MB`);
        console.log(`Duration:      ${durationStr}`);
        console.log('========================================================================\n');

        this.isParentOwner = false;
        return finalFilePath;
    }

    /**
     * Concatenates multiple MP4 segments using ffmpeg concat demuxer without re-encoding.
     */
    private static concatenateSegments(segments: string[], outputFile: string): void {
        const listFile = path.join(path.dirname(outputFile), `.concat_list_${Date.now()}.txt`);
        const content = segments.map((s) => `file '${s}'`).join('\n');
        fs.writeFileSync(listFile, content, 'utf-8');

        try {
            const ffmpegBin = fs.existsSync('/opt/homebrew/bin/ffmpeg')
                ? '/opt/homebrew/bin/ffmpeg'
                : 'ffmpeg';

            execSync(`${ffmpegBin} -y -f concat -safe 0 -i "${listFile}" -c copy "${outputFile}"`, {
                stdio: 'ignore',
            });
        } catch (err: any) {
            console.warn('[VideoRecorder] ffmpeg concat warning, copying last segment as fallback:', err?.message || err);
            fs.copyFileSync(segments[segments.length - 1], outputFile);
        } finally {
            try { fs.unlinkSync(listFile); } catch {}
        }
    }

    /**
     * Registers an exit hook to ensure the Android device recording stops if node exits.
     */
    private static registerExitHook(): void {
        const cleanup = () => {
            if (VideoRecorder.isRecordingActive) {
                VideoRecorder.killDeviceScreenrecord();
            }
        };
        process.once('exit', cleanup);
        process.once('SIGINT', () => { cleanup(); process.exit(130); });
        process.once('SIGTERM', () => { cleanup(); process.exit(143); });
    }

    /**
     * Checks if video recording is currently active.
     */
    public static isRecording(): boolean {
        return this.isRecordingActive;
    }
}
