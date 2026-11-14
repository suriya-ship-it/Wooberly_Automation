import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { spawn, execSync, ChildProcess } from "node:child_process";
import { EmailService } from "../services/EmailService";
import { DeviceManager } from "../services/DeviceManager";

const PORT = 4000;
const REPO_ROOT = path.resolve(__dirname, "..");
const TEST_REF_DIR = path.join(REPO_ROOT, "Test reference");
const RUNS_FILE = path.join(__dirname, "runs_history.json");

if (!fs.existsSync(TEST_REF_DIR)) {
  fs.mkdirSync(TEST_REF_DIR, { recursive: true });
}

interface TestRunRecord {
  id: string;
  productName: string;
  productKey?: string;
  platform?: "ios" | "android" | "web";
  status: "running" | "passed" | "failed" | "stopped";
  startedAt: string;
  endedAt: string | null;
  durationSeconds: number;
  exitCode: number | null;
  videoFilename: string | null;
  videoUrl: string | null;
  errorReason: string | null;
  logs: string[];
}

export function inferProductKey(productName: string = "", platform?: string): string {
  const name = productName.toLowerCase();
  const p = (platform || "").toLowerCase();
  if (name.includes("car")) {
    return name.includes("ios") || p === "ios" ? "rentall-cars-ios" : "rentall-cars";
  }
  if (name.includes("space")) {
    return name.includes("ios") || p === "ios" ? "rentall-space-ios" : "rentall-space";
  }
  if (name.includes("web") || p === "web") {
    return "rentall-web";
  }
  if (name.includes("rentall")) {
    return name.includes("ios") || p === "ios" ? "rentall-ios" : "rentall";
  }
  if (name.includes("wooberly")) {
    return name.includes("ios") || p === "ios" ? "wooberly-ios" : "wooberly-android";
  }
  return name.replace(/\s+/g, "-") || "unknown";
}


let activeProcess: ChildProcess | null = null;
let currentRun: TestRunRecord | null = null;
let currentLogs: string[] = [];


function killProcessTree(child: ChildProcess | null) {
  if (!child) return;
  const pid = child.pid;
  if (pid) {
    try {
      process.kill(-pid, "SIGTERM");
    } catch {}
    try {
      child.kill("SIGTERM");
    } catch {}
    setTimeout(() => {
      try {
        process.kill(-pid, "SIGKILL");
      } catch {}
      try {
        child.kill("SIGKILL");
      } catch {}
    }, 1500);
  }
  try {
    execSync('pkill -f "tests/e2e/wooberly"', { stdio: "ignore" });
    execSync('pkill -f "full_mobile_automation_flow"', { stdio: "ignore" });
    execSync('adb shell "pkill -f screenrecord"', { stdio: "ignore" });
  } catch {}
}

// Load existing run history
function loadHistory(): TestRunRecord[] {
  try {
    if (fs.existsSync(RUNS_FILE)) {
      const data = fs.readFileSync(RUNS_FILE, "utf-8");
      return JSON.parse(data);
    }
  } catch (err) {
    console.error("[Bridge] Failed to load runs history:", err);
  }
  return [];
}

function saveRunRecord(record: TestRunRecord) {
  try {
    if (!record.productKey) {
      record.productKey = inferProductKey(record.productName, record.platform);
    }
    const list = loadHistory();
    const index = list.findIndex((r) => r.id === record.id);
    if (index >= 0) {
      list[index] = record;
    } else {
      list.unshift(record);
    }
    // keep last 50 runs
    const trimmed = list.slice(0, 50);
    fs.writeFileSync(RUNS_FILE, JSON.stringify(trimmed, null, 2), "utf-8");
  } catch (err) {
    console.error("[Bridge] Failed to save run record:", err);
  }
}

function setCors(res: http.ServerResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Range");
  res.setHeader("Access-Control-Expose-Headers", "Content-Range, Accept-Ranges, Content-Length");
  res.setHeader("Access-Control-Allow-Private-Network", "true");
}

function sendJson(res: http.ServerResponse, status: number, body: unknown) {
  setCors(res);
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

function getLatestVideo(preferFilename?: string, prefix?: string): string | null {
  try {
    if (!fs.existsSync(TEST_REF_DIR)) return null;
    const files = fs.readdirSync(TEST_REF_DIR).filter((f) => f.endsWith(".mp4"));
    if (!files.length) return null;
    // Prefer requested file if present
    if (preferFilename && files.includes(preferFilename)) {
      return preferFilename;
    }
    // If prefix is specified, match newest file with that prefix
    if (prefix) {
      const matching = files.filter((f) => f.startsWith(prefix));
      if (matching.length) {
        matching.sort((a, b) => {
          const aTime = fs.statSync(path.join(TEST_REF_DIR, a)).mtimeMs;
          const bTime = fs.statSync(path.join(TEST_REF_DIR, b)).mtimeMs;
          return bTime - aTime;
        });
        return matching[0];
      }
    }
    // Prefer latest_execution.mp4 if exists and no specific prefix requested
    if (!prefix && files.includes("latest_execution.mp4")) {
      return "latest_execution.mp4";
    }
    // Otherwise sort by mtime desc
    files.sort((a, b) => {
      const aTime = fs.statSync(path.join(TEST_REF_DIR, a)).mtimeMs;
      const bTime = fs.statSync(path.join(TEST_REF_DIR, b)).mtimeMs;
      return bTime - aTime;
    });
    return files[0];
  } catch {
    return null;
  }
}

// Stream video with HTTP 206 Partial Content for HTML5 player
function streamVideo(req: http.IncomingMessage, res: http.ServerResponse, filename: string) {
  setCors(res);
  const filePath = path.join(TEST_REF_DIR, filename);

  // Prevent path traversal
  if (!filePath.startsWith(TEST_REF_DIR) || !fs.existsSync(filePath)) {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("Video not found");
    return;
  }

  const stat = fs.statSync(filePath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunksize = end - start + 1;
    const file = fs.createReadStream(filePath, { start, end });

    res.writeHead(206, {
      "Content-Range": `bytes ${start}-${end}/${fileSize}`,
      "Accept-Ranges": "bytes",
      "Content-Length": chunksize,
      "Content-Type": "video/mp4",
    });
    file.pipe(res);
  } else {
    res.writeHead(200, {
      "Content-Length": fileSize,
      "Content-Type": "video/mp4",
      "Accept-Ranges": "bytes",
    });
    fs.createReadStream(filePath).pipe(res);
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  const pathname = url.pathname;

  if (req.method === "OPTIONS") {
    setCors(res);
    res.setHeader("Access-Control-Max-Age", "86400");
    res.writeHead(204);
    res.end();
    return;
  }

  // Health
  if (req.method === "GET" && pathname === "/api/health") {
    sendJson(res, 200, { status: "ok", port: PORT, appiumDir: REPO_ROOT });
    return;
  }

  // Get current status
  if (req.method === "GET" && pathname === "/api/tests/status") {
    const isRunning = activeProcess !== null;
    const elapsedSeconds = currentRun && isRunning
      ? Math.round((Date.now() - new Date(currentRun.startedAt).getTime()) / 1000)
      : (currentRun?.durationSeconds || 0);

    const history = loadHistory();
    const lastRun = currentRun || history[0] || null;

    // Build latestRunsByProduct map for 100% per-product status isolation
    const latestRunsByProduct: Record<string, TestRunRecord> = {};
    for (const h of history) {
      const key = h.productKey || inferProductKey(h.productName, h.platform);
      if (!latestRunsByProduct[key]) {
        latestRunsByProduct[key] = { ...h, productKey: key };
      }
    }
    if (currentRun) {
      const curKey = currentRun.productKey || inferProductKey(currentRun.productName, currentRun.platform);
      latestRunsByProduct[curKey] = {
        ...currentRun,
        productKey: curKey,
        durationSeconds: isRunning ? elapsedSeconds : currentRun.durationSeconds,
      };
    }

    sendJson(res, 200, {
      isRunning,
      activeProductKey: currentRun && isRunning ? (currentRun.productKey || inferProductKey(currentRun.productName, currentRun.platform)) : null,
      currentRun: isRunning ? { ...currentRun, elapsedSeconds } : null,
      lastRun,
      latestRunsByProduct,
      logsTail: currentLogs.slice(-40),
    });
    return;
  }

  // Start test
  if (req.method === "POST" && pathname === "/api/tests/start") {
    let bodyStr = "";
    req.on("data", (chunk) => {
      bodyStr += chunk.toString();
    });

    req.on("end", () => {
      if (activeProcess !== null) {
        sendJson(res, 409, {
          error: `Another test (${currentRun?.productName || "running"}) is currently executing. Please wait or stop it first.`,
          activeProductKey: currentRun?.productKey || (currentRun ? inferProductKey(currentRun.productName, currentRun.platform) : null),
          activeProductName: currentRun?.productName,
        });
        return;
      }

      let payload: { platform?: "ios" | "android" | "web"; productName?: string; productKey?: string } = {};
      try {
        if (bodyStr.trim()) {
          payload = JSON.parse(bodyStr);
        }
      } catch (err) {
        console.warn("[Bridge] Could not parse JSON body in /api/tests/start:", err);
      }

      const isWeb =
        payload.platform === "web" ||
        (payload.productName && payload.productName.toLowerCase().includes("web"));
      const isRentALLCars =
        process.env.DISABLE_RENTALL_CARS !== "true" &&
        !isWeb &&
        payload.productName &&
        payload.productName.toLowerCase().includes("car");
      const isRentALLSpace =
        !isWeb &&
        !isRentALLCars &&
        payload.productName &&
        payload.productName.toLowerCase().includes("space");
      const isRentALLMobile =
        !isWeb &&
        !isRentALLCars &&
        !isRentALLSpace &&
        payload.productName &&
        payload.productName.toLowerCase().includes("rentall");
      const isCarsIOS = Boolean(
        isRentALLCars &&
          (payload.platform === "ios" || (payload.productName && payload.productName.toLowerCase().includes("ios")))
      );
      const isIOS =
        !isWeb &&
        !isRentALLCars &&
        !isRentALLSpace &&
        !isRentALLMobile &&
        (payload.platform === "ios" ||
          (payload.productName && payload.productName.toLowerCase().includes("ios")));
      const isStoreInstall = Boolean(
        payload.productName &&
          (payload.productName.toLowerCase().includes("store") ||
            payload.productName.toLowerCase().includes("install") ||
            payload.productName.toLowerCase().includes("step2") ||
            payload.productName.toLowerCase().includes("step 2"))
      );
      const platform: "ios" | "android" | "web" = isWeb ? "web" : (isIOS || isCarsIOS) ? "ios" : "android";
      const productName = payload.productName || (
        isWeb
          ? "RentALL Web"
          : isRentALLCars
          ? (isCarsIOS ? "RentALL Cars (iOS)" : "RentALL Cars")
          : isRentALLSpace
          ? "RentALL Space"
          : isRentALLMobile
          ? "RentALL Mobile"
          : isIOS
          ? "Wooberly (iOS)"
          : "Wooberly (Android)"
      );
      const productKey = payload.productKey || inferProductKey(productName, platform);

      // Check if Android apps are already installed on device
      let needsAndroidInstall = false;
      if (platform === "android" && !isRentALLMobile && !isRentALLSpace && !isRentALLCars) {
        try {
          const riderInstalled = DeviceManager.isPackageInstalled("com.radicalstart.wooberly");
          const driverInstalled = DeviceManager.isPackageInstalled("com.radicalstart.wooberlydriver");
          needsAndroidInstall = !riderInstalled || !driverInstalled || isStoreInstall;
          console.log(`[Bridge] Android app check -> Rider: ${riderInstalled}, Driver: ${driverInstalled}. Needs install: ${needsAndroidInstall}`);
        } catch (e) {
          console.warn("[Bridge] Could not verify installed packages via ADB:", e);
        }
      }

      // Route npm script, video prefix, and target working directory per product
      const npmScript = isWeb
        ? "test:web"
        : isRentALLCars
        ? (isCarsIOS ? "test:ios" : "test:android")
        : isRentALLSpace
        ? "test:mobile:full"
        : isRentALLMobile
        ? "test:mobile:full"
        : isIOS
        ? (isStoreInstall ? "test:ios:step2" : "test:ios")
        : (needsAndroidInstall ? "test:step2" : "test:step1");

      const preferredVideo = isRentALLCars
        ? (isCarsIOS ? "rentall_cars_ios_e2e_latest.mp4" : "rentall_cars_android_e2e_latest.mp4")
        : isRentALLSpace
        ? "rentall_space_mobile_full_e2e_latest.mp4"
        : isRentALLMobile
        ? "rentall_mobile_full_e2e_latest.mp4"
        : isIOS
        ? "latest_ios_execution.mp4"
        : "latest_execution.mp4";

      const videoPrefix = isRentALLCars
        ? "rentall_cars_"
        : isRentALLSpace
        ? "rentall_space_"
        : isRentALLMobile
        ? "rentall_mobile_"
        : isIOS
        ? "latest_ios"
        : "latest_execution";

      const targetCwd = isWeb
        ? "/Users/radicalstart/Documents/PackageDemo/RentALL_V3.9.2/RentALL Automation"
        : isRentALLCars
        ? "/Users/radicalstart/Documents/RentALL Cars Automation"
        : isRentALLSpace
        ? "/Users/radicalstart/Documents/RentALL Space Automation"
        : isRentALLMobile
        ? "/Users/radicalstart/Documents/PackageDemo/RentALL_V3.9.2/RentALL Mobile Automation"
        : REPO_ROOT;

      // Clean up any lingering worker processes before spawning a fresh run
      try {
        execSync('pkill -f "tests/e2e/wooberly"', { stdio: "ignore" });
        execSync('pkill -f "full_mobile_automation_flow"', { stdio: "ignore" });
        execSync('adb shell "pkill -f screenrecord"', { stdio: "ignore" });
      } catch {}

      const runId = "run_" + Date.now();
      const startedAt = new Date().toISOString();
      currentLogs = [];

      currentRun = {
        id: runId,
        productName,
        productKey,
        platform,
        status: "running",
        startedAt,
        endedAt: null,
        durationSeconds: 0,
        exitCode: null,
        videoFilename: null,
        videoUrl: null,
        errorReason: null,
        logs: currentLogs,
      };
      saveRunRecord(currentRun);

      console.log(`\n========================================`);
      console.log(`[Bridge] Starting ${npmScript} for ${productName} (key=${productKey})...`);
      console.log(`[Bridge] Platform: ${platform.toUpperCase()} | Run ID: ${runId} | Time: ${startedAt}`);
      console.log(`========================================\n`);

      const child = spawn("npm", ["run", npmScript], {
        cwd: targetCwd,
        shell: true,
        detached: true,
        env: { ...process.env, FORCE_COLOR: "1" },
      });

      activeProcess = child;

      const appendLog = (chunk: Buffer) => {
        const text = chunk.toString();
        process.stdout.write(text);
        const lines = text.split("\n");
        for (const line of lines) {
          if (line.trim()) {
            currentLogs.push(line);
            if (currentLogs.length > 2000) currentLogs.shift();
          }
        }
      };

      child.stdout.on("data", appendLog);
      child.stderr.on("data", appendLog);

      child.on("close", (code) => {
        const endedAt = new Date().toISOString();
        const durationSeconds = Math.round((Date.now() - new Date(startedAt).getTime()) / 1000);
        const isSuccess = code === 0;
        const status = isSuccess ? "passed" : "failed";

        let videoFilename: string | null = null;
        let videoUrl: string | null = null;
        let errorReason: string | null = null;

        if (isSuccess) {
          videoFilename = getLatestVideo(preferredVideo, videoPrefix);
          videoUrl = videoFilename ? `http://localhost:${PORT}/api/video/${videoFilename}` : null;
          console.log(`\n[Bridge] Test PASSED in ${durationSeconds}s! Video recorded: ${videoFilename}`);
          // Send pass report email with video attachment
          try {
            process.env.APP_NAME = currentRun?.productName || "RentALL Cars";
            EmailService.sendTestPassedReport(videoFilename || undefined);
          } catch (e) {
            console.warn('[Bridge] Email dispatch error:', e);
          }
        } else {
          // Extract meaningful error lines
          const errorLines = currentLogs.filter(
            (l) =>
              l.toLowerCase().includes("error") ||
              l.toLowerCase().includes("fail") ||
              l.includes("Error:") ||
              l.includes("Exception") ||
              l.includes("ECONNREFUSED") ||
              l.includes("Device")
          );
          errorReason = errorLines.slice(-6).join("\n") || currentLogs.slice(-6).join("\n") || `Script exited with exit code ${code}`;
          console.log(`\n[Bridge] Test FAILED with exit code ${code}. Error: ${errorReason}`);
        }

        if (currentRun && currentRun.id === runId) {
          currentRun = {
            ...currentRun,
            status,
            endedAt,
            durationSeconds,
            exitCode: code,
            videoFilename,
            videoUrl,
            errorReason,
            logs: currentLogs.slice(-200),
          };
          saveRunRecord(currentRun);
        }

        activeProcess = null;
      });

      sendJson(res, 200, {
        message: `Test started successfully on ${platform.toUpperCase()}`,
        platform,
        productName,
        productKey,
        runId,
        startedAt,
      });
    });
    return;
  }

  // Stop test
  if (req.method === "POST" && pathname === "/api/tests/stop") {
    let bodyStr = "";
    req.on("data", (chunk) => {
      bodyStr += chunk.toString();
    });

    req.on("end", () => {
      let payload: { productName?: string; productKey?: string } = {};
      try {
        if (bodyStr.trim()) payload = JSON.parse(bodyStr);
      } catch {}

      const reqKey = payload.productKey || (payload.productName ? inferProductKey(payload.productName) : null);
      const curKey = currentRun?.productKey || (currentRun ? inferProductKey(currentRun.productName, currentRun.platform) : null);

      if (reqKey && curKey && reqKey !== curKey && activeProcess) {
        sendJson(res, 409, {
          error: `Cannot stop ${payload.productName || reqKey}: active running test belongs to ${currentRun?.productName || curKey}.`,
          activeProductKey: curKey,
          activeProductName: currentRun?.productName,
        });
        return;
      }

      // Always perform cleanup of any lingering worker processes
      try {
        execSync('pkill -f "tests/e2e/wooberly"', { stdio: "ignore" });
        execSync('pkill -f "full_mobile_automation_flow"', { stdio: "ignore" });
        execSync('pkill -f "sync_cosmetics_from_md"', { stdio: "ignore" });
        execSync('adb shell "pkill -f screenrecord"', { stdio: "ignore" });
      } catch {}

      if (activeProcess) {
        console.log("[Bridge] Stop signal received. Terminating test process tree...");
        killProcessTree(activeProcess);
        activeProcess = null;
      }

      if (currentRun && currentRun.status === "running") {
        currentRun = {
          ...currentRun,
          status: "stopped",
          endedAt: new Date().toISOString(),
          durationSeconds: Math.round((Date.now() - new Date(currentRun.startedAt).getTime()) / 1000),
          exitCode: -1,
          videoFilename: null,
          videoUrl: null,
          errorReason: "Execution stopped manually by user.",
        };
        saveRunRecord(currentRun);
      }

      sendJson(res, 200, {
        message: "Test stopped successfully.",
        stoppedProductKey: curKey,
      });
    });
    return;
  }

  // List historical runs
  if (req.method === "GET" && pathname === "/api/runs") {
    const history = loadHistory();
    // If active process, prepend currentRun
    const all = currentRun && activeProcess ? [currentRun, ...history.filter((h) => h.id !== currentRun!.id)] : history;
    sendJson(res, 200, { runs: all });
    return;
  }

  // List available videos
  if (req.method === "GET" && pathname === "/api/videos") {
    try {
      const files = fs.readdirSync(TEST_REF_DIR).filter((f) => f.endsWith(".mp4"));
      const videos = files.map((name) => {
        const stat = fs.statSync(path.join(TEST_REF_DIR, name));
        return {
          filename: name,
          sizeBytes: stat.size,
          sizeMB: (stat.size / (1024 * 1024)).toFixed(2) + " MB",
          modifiedAt: stat.mtime.toISOString(),
          url: `http://localhost:${PORT}/api/video/${encodeURIComponent(name)}`,
        };
      });
      // Sort newest first
      videos.sort((a, b) => new Date(b.modifiedAt).getTime() - new Date(a.modifiedAt).getTime());
      sendJson(res, 200, { videos });
    } catch (err) {
      sendJson(res, 500, { error: "Failed to list videos", details: String(err) });
    }
    return;
  }

  // Stream video
  if (
    (req.method === "GET" || req.method === "HEAD") &&
    (pathname.startsWith("/api/video/") || pathname.startsWith("/videos/") || pathname.startsWith("/video/"))
  ) {
    const filename = decodeURIComponent(
      pathname.replace(/^\/(api\/video|videos|video)\//, "")
    );
    streamVideo(req, res, filename);
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`\n======================================================`);
  console.log(`  Wooberly Automation Bridge Server running on:`);
  console.log(`  http://localhost:${PORT}`);
  console.log(`  Video Stream: http://localhost:${PORT}/api/video/latest_execution.mp4`);
  console.log(`======================================================\n`);
});
