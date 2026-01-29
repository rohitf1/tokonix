const { app, BrowserWindow } = require("electron");
const fs = require("fs");
const path = require("path");

const LOG_PATH = path.join(__dirname, "electron-debug.log");
const GPU_FLAG_PATH = path.join(__dirname, "gpu-crash.flag");

const safeStringify = (value) => {
  try {
    return JSON.stringify(value);
  } catch (error) {
    return String(value);
  }
};

const logLine = (message, data) => {
  const stamp = new Date().toISOString();
  const payload = data ? ` ${safeStringify(data)}` : "";
  try {
    fs.appendFileSync(LOG_PATH, `[${stamp}] ${message}${payload}\n`);
  } catch (error) {
    // Ignore logging failures to avoid blocking app start.
  }
};

const logError = (label, error) => {
  if (!error) {
    logLine(label);
    return;
  }
  if (error instanceof Error) {
    logLine(label, { message: error.message, stack: error.stack });
    return;
  }
  logLine(label, { error: String(error) });
};

logLine("boot", { argv: process.argv, cwd: process.cwd() });

if (fs.existsSync(GPU_FLAG_PATH)) {
  app.disableHardwareAcceleration();
  logLine("gpu-disabled", { reason: "previous-crash-flag" });
}

const WINDOW_OPTIONS = {
  width: 960,
  height: 720,
  backgroundColor: "#05060b",
  show: false,
  webPreferences: {
    preload: path.join(__dirname, "preload.js"),
    contextIsolation: true,
  },
};

function attachDiagnostics(win) {
  const { webContents } = win;
  webContents.on("console-message", (_event, level, message, line, sourceId) => {
    logLine("console-message", { level, message, line, sourceId });
  });
  webContents.on("did-fail-load", (_event, errorCode, errorDesc, validatedURL) => {
    logLine("did-fail-load", { errorCode, errorDesc, validatedURL });
  });
  webContents.on("render-process-gone", (_event, details) => {
    logLine("webContents-render-process-gone", details);
  });
  webContents.on("unresponsive", () => {
    logLine("webContents-unresponsive");
  });
}

function createWindow() {
  const win = new BrowserWindow(WINDOW_OPTIONS);
  attachDiagnostics(win);
  win.loadFile(path.join(__dirname, "index.html"));
  win.once("ready-to-show", () => win.show());
  win.on("closed", () => logLine("browser-window-closed"));
  return win;
}

process.on("uncaughtException", (error) => {
  logError("uncaughtException", error);
});

process.on("unhandledRejection", (reason) => {
  logError("unhandledRejection", reason);
});

app.on("render-process-gone", (_event, webContents, details) => {
  logLine("app-render-process-gone", { details, url: webContents?.getURL?.() });
});

app.on("child-process-gone", (_event, details) => {
  logLine("child-process-gone", details);
  if (details?.type === "GPU") {
    try {
      fs.writeFileSync(GPU_FLAG_PATH, new Date().toISOString());
    } catch (error) {
      logError("gpu-flag-write-failed", error);
    }
  }
});

app.on("gpu-process-crashed", (_event, killed) => {
  logLine("gpu-process-crashed", { killed });
  try {
    fs.writeFileSync(GPU_FLAG_PATH, new Date().toISOString());
  } catch (error) {
    logError("gpu-flag-write-failed", error);
  }
});

app.whenReady().then(() => {
  logLine("app-ready", { pid: process.pid, versions: process.versions });
  app.on("browser-window-created", (_event, window) => {
    logLine("browser-window-created");
    window.on("unresponsive", () => logLine("browser-window-unresponsive"));
  });
  app.on("web-contents-created", (_event, contents) => {
    logLine("web-contents-created", { id: contents.id, type: contents.getType?.() });
  });
  app.on("before-quit", () => logLine("before-quit"));
  app.on("will-quit", () => logLine("will-quit"));
  createWindow();
});

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

app.on("window-all-closed", () => {
  logLine("window-all-closed");
  if (process.platform !== "darwin") {
    app.quit();
  }
});
