import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import "./style.css";

export const DemoVideo = ({ title, subtitle }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const slide = interpolate(frame, [0, 30], [40, 0], {
    extrapolateRight: "clamp",
  });
  const fade = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });
  const pulse = interpolate(frame, [0, durationInFrames], [0, 1]);

  return (
    <AbsoluteFill className="video-root">
      <div className="glow" style={{ opacity: 0.25 + pulse * 0.35 }} />
      <div className="content" style={{ opacity: fade, transform: `translateY(${slide}px)` }}>
        <div className="eyebrow">Video Artifacts</div>
        <h1>{title}</h1>
        <p>{subtitle}</p>
        <div className="chips">
          <span>Data</span>
          <span>Motion</span>
          <span>Design</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
