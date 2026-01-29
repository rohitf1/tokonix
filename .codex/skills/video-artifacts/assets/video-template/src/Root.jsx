import { Composition } from "remotion";
import { DemoVideo } from "./Video";

export const RemotionRoot = () => {
  return (
    <>
      <Composition
        id="Demo"
        component={DemoVideo}
        durationInFrames={180}
        fps={30}
        width={1280}
        height={720}
        defaultProps={{
          title: "Tokonix Demo",
          subtitle: "Remotion-powered video",
        }}
      />
    </>
  );
};
