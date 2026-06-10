import type { Effect } from "@moq/signals";
import * as Util from "@moq/hang/util";
import type MoqPublish from "../../element";

type StatusConfig = { variant: string; text: string };
const POLL_MS = 250;

function deriveStatus(
	url: URL | undefined,
	status: "connecting" | "connected" | "disconnected",
	hasAudio: boolean,
	hasVideo: boolean,
): StatusConfig {
	if (!url) return { variant: "error", text: "No URL" };
	if (status === "disconnected") return { variant: "error", text: "Disconnected" };
	if (status === "connecting") return { variant: "connecting", text: "Connecting..." };
	if (!hasAudio && !hasVideo) return { variant: "warning", text: "Select Source" };
	if (!hasAudio && hasVideo) return { variant: "video-only", text: "Video Only" };
	if (hasAudio && !hasVideo) return { variant: "audio-only", text: "Audio Only" };
	return { variant: "live", text: "Live" };
}

function formatBitrate(bps: number): string {
	if (bps >= 1_000_000) return `${(bps / 1_000_000).toFixed(1)}Mbps`;
	if (bps >= 1_000) return `${(bps / 1_000).toFixed(0)}kbps`;
	return `${bps.toFixed(0)}bps`;
}

export function publishStatusIndicator(parent: Effect, publish: MoqPublish): HTMLElement {
	const wrapper = document.createElement("div");
	wrapper.className = "status-indicator flex-center";

	const dot = document.createElement("span");
	const content = document.createElement("span");
	content.className = "status-indicator-content";
	const text = document.createElement("span");
	const detail = document.createElement("span");
	content.append(text, detail);
	wrapper.append(dot, content);

	let previous: Util.Bytes.Sample | undefined;

	parent.run((effect) => {
		const url = effect.get(publish.connection.url);
		const status = effect.get(publish.connection.status);
		const audioSource = effect.get(publish.broadcast.audio.source);
		const videoSource = effect.get(publish.broadcast.video.source);
		const muted = effect.get(publish.state.muted);
		const invisible = effect.get(publish.state.invisible);

		const { variant, text: label } = deriveStatus(
			url,
			status,
			!!audioSource && !muted,
			!!videoSource && !invisible,
		);
		const active = (!!audioSource && !muted) || (!!videoSource && !invisible);
		dot.className = `status-indicator-dot status-indicator-dot--${variant}`;
		text.className = `status-indicator-text status-indicator-text--${variant}`;
		text.textContent = label;
		detail.className = `status-indicator-detail status-indicator-detail--${variant}`;
		if (status !== "connected" || !active) {
			previous = undefined;
			detail.textContent = "";
			detail.style.display = "none";
		} else {
			detail.style.display = "";
		}
	});

	parent.interval(() => {
		const audioSource = publish.broadcast.audio.source.peek();
		const videoSource = publish.broadcast.video.source.peek();
		const muted = publish.state.muted.peek();
		const invisible = publish.state.invisible.peek();
		const active = (!!audioSource && !muted) || (!!videoSource && !invisible);
		if (publish.connection.status.peek() !== "connected" || !active) {
			previous = undefined;
			detail.textContent = "";
			detail.style.display = "none";
			return;
		}

		const current: Util.Bytes.Sample = {
			bytes: publish.broadcast.bytesSent.peek(),
			when: performance.now(),
		};
		const bitrate = Util.Bytes.sampleBitrate(previous, current);
		previous = current;

		detail.style.display = "";
		detail.textContent = bitrate !== undefined ? `↑ ${formatBitrate(bitrate)}` : "↑ measuring...";
	}, POLL_MS);

	return wrapper;
}
