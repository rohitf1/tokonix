import { create } from "zustand";

const useAppStore = create(() => ({
  status: "Connected",
  activeWorkspace: "Ops Hub",
  activity: [
    { time: "09:12", title: "Synced 4 data sources", detail: "CRM + Analytics" },
    { time: "09:28", title: "Generated weekly report", detail: "Saved to Reports" },
    { time: "09:41", title: "Scheduled follow-ups", detail: "12 reminders" },
  ],
  insights: [
    { label: "Active pipelines", value: "6" },
    { label: "Priority tasks", value: "14" },
    { label: "Alerts", value: "2" },
  ],
}));

const Card = ({ title, children }) => (
  <div className="card">
    <div className="card-title">{title}</div>
    <div className="card-body">{children}</div>
  </div>
);

export default function App() {
  const { status, activeWorkspace, activity, insights } = useAppStore();

  return (
    <div className="app-shell">
      <header className="topbar">
        <div>
          <div className="eyebrow">Artifact App</div>
          <div className="title">Command Center</div>
        </div>
        <div className="topbar-right">
          <div className="chip">{activeWorkspace}</div>
          <div className="status">
            <span className="status-dot" />
            {status}
          </div>
        </div>
      </header>

      <main className="main-grid">
        <section className="left-rail">
          <Card title="Quick Actions">
            <button className="primary">Launch workflow</button>
            <button className="ghost">Create new report</button>
            <button className="ghost">Connect data source</button>
          </Card>
          <Card title="Insights">
            <div className="insight-grid">
              {insights.map((item) => (
                <div key={item.label} className="insight">
                  <div className="insight-value">{item.value}</div>
                  <div className="insight-label">{item.label}</div>
                </div>
              ))}
            </div>
          </Card>
        </section>

        <section className="center-panel">
          <Card title="Active Canvas">
            <div className="canvas">
              <div className="canvas-title">Live Plan</div>
              <div className="canvas-row">Pipeline: Growth Ops</div>
              <div className="canvas-row">Next checkpoint: 14:30</div>
              <div className="canvas-row">Automation: 7 tasks queued</div>
            </div>
          </Card>
          <Card title="Workstream">
            <div className="workstream">
              <div className="work-item">
                <div className="work-title">Audit blockers</div>
                <div className="work-meta">Due today · 3 collaborators</div>
              </div>
              <div className="work-item">
                <div className="work-title">Refine messaging</div>
                <div className="work-meta">Due tomorrow · 2 collaborators</div>
              </div>
              <div className="work-item">
                <div className="work-title">Ship onboarding email</div>
                <div className="work-meta">Draft ready · Review pending</div>
              </div>
            </div>
          </Card>
        </section>

        <section className="right-rail">
          <Card title="Activity Feed">
            <div className="timeline">
              {activity.map((item) => (
                <div key={item.title} className="timeline-item">
                  <div className="timeline-time">{item.time}</div>
                  <div>
                    <div className="timeline-title">{item.title}</div>
                    <div className="timeline-detail">{item.detail}</div>
                  </div>
                </div>
              ))}
            </div>
          </Card>
          <Card title="System Health">
            <div className="health">
              <div>
                <div className="health-label">Latency</div>
                <div className="health-value">122ms</div>
              </div>
              <div>
                <div className="health-label">Automation queue</div>
                <div className="health-value">97%</div>
              </div>
              <div>
                <div className="health-label">Guardrails</div>
                <div className="health-value">All clear</div>
              </div>
            </div>
          </Card>
        </section>
      </main>
    </div>
  );
}
