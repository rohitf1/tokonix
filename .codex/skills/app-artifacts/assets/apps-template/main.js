const { app, BrowserWindow } = require("electron");
const fs = require("fs");
const path = require("path");

const LOG_PATH = path.join(__dirname, "electron-debug.log");

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

const WINDOW_OPTIONS = {
  width: 1120,
  height: 780,
  backgroundColor: "#06070d",
  show: false,
  webPreferences: {
    preload: path.join(__dirname, "preload.js"),
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: false,
  },
};

const attachDiagnostics = (win) => {
  const { webContents } = win;
  webContents.on("console-message", (_event, level, message, line, sourceId) => {
    logLine("console-message", { level, message, line, sourceId });
  });
  webContents.on("did-fail-load", (_event, errorCode, errorDesc, validatedURL) => {
    logLine("did-fail-load", { errorCode, errorDesc, validatedURL });
  });
  webContents.on("render-process-gone", (_event, details) => {
    logLine("render-process-gone", details);
  });
};

const createWindow = () => {
  const win = new BrowserWindow(WINDOW_OPTIONS);
  attachDiagnostics(win);

  const startUrl = process.env.ELECTRON_START_URL;
  if (startUrl) {
    win.loadURL(startUrl);
  } else {
    win.loadFile(path.join(__dirname, "dist/index.html"));
  }

  win.once("ready-to-show", () => win.show());
  return win;
};

app.whenReady().then(() => {
  logLine("app-ready", { pid: process.pid, versions: process.versions });
  createWindow();
});

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
