import { expect, test } from "bun:test";
import * as Bytes from "./bytes";

test("sum treats missing values as zero", () => {
	expect(Bytes.sum(undefined, 10, undefined, 5)).toBe(15);
});

test("sampleBitrate returns bits per second from byte deltas", () => {
	const bitrate = Bytes.sampleBitrate(
		{ bytes: 1_000, when: 1_000 },
		{ bytes: 2_000, when: 1_500 },
	);

	expect(bitrate).toBe(16_000);
});

test("sampleBitrate ignores zero or negative deltas", () => {
	expect(Bytes.sampleBitrate(undefined, { bytes: 1_000, when: 2_000 })).toBeUndefined();
	expect(Bytes.sampleBitrate({ bytes: 1_000, when: 2_000 }, { bytes: 1_000, when: 2_500 })).toBeUndefined();
	expect(Bytes.sampleBitrate({ bytes: 2_000, when: 2_000 }, { bytes: 1_000, when: 2_500 })).toBeUndefined();
	expect(Bytes.sampleBitrate({ bytes: 1_000, when: 2_000 }, { bytes: 2_000, when: 2_000 })).toBeUndefined();
});