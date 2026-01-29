const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("artifact", {
  platform: process.platform,
  ready: true,
});

console.log("preload: ready");
