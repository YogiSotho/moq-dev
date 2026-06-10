export interface Sample {
	bytes: number;
	when: number;
}

export function sum(...values: Array<number | undefined>): number {
	return values.reduce<number>((total, value) => total + (value ?? 0), 0);
}

export function sampleBitrate(previous: Sample | undefined, current: Sample | undefined): number | undefined {
	if (!previous || !current) return undefined;

	const deltaBytes = current.bytes - previous.bytes;
	const deltaMs = current.when - previous.when;
	if (deltaBytes <= 0 || deltaMs <= 0) return undefined;

	return (deltaBytes * 8 * 1000) / deltaMs;
}