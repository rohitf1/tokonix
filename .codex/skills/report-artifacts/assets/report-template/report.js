const dataElement = document.getElementById("report-data");
const reportData = dataElement ? JSON.parse(dataElement.textContent || "{}") : {};

const metricsRoot = document.getElementById("metrics");
const chartsRoot = document.getElementById("charts");
const tablesRoot = document.getElementById("tables");
const tableRoot = document.getElementById("table");
const notesRoot = document.getElementById("notes");

const palette = ["#4cc3ff", "#b44bff", "#ff4fd8", "#2ee6c7", "#6aa9ff"];

function createMetric(metric) {
  const card = document.createElement("div");
  card.className = "metric-card";

  const label = document.createElement("div");
  label.className = "metric-label";
  label.textContent = metric.label || "Metric";

  const value = document.createElement("div");
  value.className = "metric-value";
  value.textContent = metric.value || "0";

  const delta = document.createElement("div");
  delta.className = "metric-delta";
  delta.textContent = metric.delta || "";

  card.append(label, value, delta);
  return card;
}

function renderMetrics() {
  if (!metricsRoot) {
    return;
  }
  const metrics = reportData.metrics || [];
  if (!metrics.length) {
    metricsRoot.parentElement?.classList.add("hidden");
    return;
  }
  metrics.forEach((metric) => metricsRoot.appendChild(createMetric(metric)));
}

function renderCharts() {
  if (!chartsRoot) {
    return;
  }
  const charts = reportData.charts || [];
  if (!charts.length) {
    chartsRoot.style.display = "none";
    return;
  }

  charts.forEach((chart, index) => {
    const card = document.createElement("div");
    card.className = "chart-card";

    const title = document.createElement("h3");
    title.textContent = chart.title || `Chart ${index + 1}`;

    const canvas = document.createElement("canvas");
    canvas.height = 180;

    card.append(title, canvas);
    chartsRoot.appendChild(card);

    const datasets = (chart.series || []).map((series, seriesIndex) => {
      const color = palette[(index + seriesIndex) % palette.length];
      return {
        label: series.label || `Series ${seriesIndex + 1}`,
        data: series.data || [],
        borderColor: color,
        backgroundColor: `${color}66`,
        tension: 0.35,
        fill: chart.type === "line",
      };
    });

    new Chart(canvas, {
      type: chart.type || "line",
      data: {
        labels: chart.labels || [],
        datasets,
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            labels: {
              color: "#e6f3ff",
            },
          },
        },
        scales: {
          x: {
            ticks: { color: "#9bb0c9" },
            grid: { color: "rgba(255,255,255,0.05)" },
          },
          y: {
            ticks: { color: "#9bb0c9" },
            grid: { color: "rgba(255,255,255,0.05)" },
          },
        },
      },
    });
  });
}

function buildTable(table, wrapperClass) {
  const wrapper = document.createElement("div");
  wrapper.className = wrapperClass;

  const heading = document.createElement("h3");
  heading.textContent = table.title || "Details";

  const tableEl = document.createElement("table");
  const thead = document.createElement("thead");
  const headRow = document.createElement("tr");
  table.columns.forEach((col) => {
    const th = document.createElement("th");
    th.textContent = col;
    headRow.appendChild(th);
  });
  thead.appendChild(headRow);

  const tbody = document.createElement("tbody");
  table.rows.forEach((row) => {
    const tr = document.createElement("tr");
    row.forEach((cell) => {
      const td = document.createElement("td");
      td.textContent = cell;
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  });

  tableEl.append(thead, tbody);
  wrapper.append(heading, tableEl);

  return wrapper;
}

function renderTables() {
  if (!tablesRoot) {
    return;
  }
  const tables = reportData.tables || [];
  if (!tables.length) {
    tablesRoot.style.display = "none";
    return;
  }

  tables.forEach((table) => {
    if (!table || !table.columns || !table.rows) {
      return;
    }
    tablesRoot.appendChild(buildTable(table, "table-card"));
  });

  if (tableRoot) {
    tableRoot.style.display = "none";
  }
}

function renderTable() {
  if (!tableRoot) {
    return;
  }
  if (reportData.tables && reportData.tables.length) {
    tableRoot.style.display = "none";
    return;
  }
  const table = reportData.table;
  if (!table || !table.columns || !table.rows) {
    tableRoot.style.display = "none";
    return;
  }
  tableRoot.appendChild(buildTable(table, "table"));
}

function renderNotes() {
  if (!notesRoot) {
    return;
  }
  const notes = reportData.notes || [];
  if (!notes.length) {
    notesRoot.style.display = "none";
    return;
  }

  const heading = document.createElement("h3");
  heading.textContent = reportData.notesTitle || "Highlights";

  const list = document.createElement("ul");
  notes.forEach((note) => {
    const item = document.createElement("li");
    item.textContent = note;
    list.appendChild(item);
  });

  notesRoot.append(heading, list);
}

function handleActions() {
  const printButton = document.getElementById("print-btn");
  const copyButton = document.getElementById("copy-btn");

  if (printButton) {
    printButton.addEventListener("click", () => window.print());
  }

  if (copyButton) {
    copyButton.addEventListener("click", async () => {
      const copyText = reportData.copyText
        || [reportData.title, reportData.summary]
          .filter(Boolean)
          .join("\n\n");

      if (!copyText) {
        return;
      }

      try {
        await navigator.clipboard.writeText(copyText);
        copyButton.textContent = "Copied";
        setTimeout(() => {
          copyButton.textContent = "Copy summary";
        }, 1500);
      } catch (error) {
        console.error("Clipboard copy failed", error);
      }
    });
  }
}

renderMetrics();
renderCharts();
renderTables();
renderTable();
renderNotes();
handleActions();
