/**
 * Media Manager Extension
 *
 * Tools for interacting with Sonarr, Radarr, and qBittorrent.
 * Handles listing, searching, adding, and checking download status.
 *
 * Configuration via environment variables:
 *   SONARR_URL       (default: http://172.18.0.12:8989)
 *   SONARR_API_KEY   (required for write ops)
 *   RADARR_URL       (default: http://172.18.0.8:7878)
 *   RADARR_API_KEY   (required for write ops)
 *   QB_URL           (default: http://localhost:8081)
 *   QB_USERNAME      (default: admin)
 *   QB_PASSWORD      (required for write ops)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";

const SONARR_URL = process.env.SONARR_URL || "http://172.18.0.12:8989";
const SONARR_API_KEY = process.env.SONARR_API_KEY || "";
const RADARR_URL = process.env.RADARR_URL || "http://172.18.0.8:7878";
const RADARR_API_KEY = process.env.RADARR_API_KEY || "";
const QB_URL = process.env.QB_URL || "http://localhost:8081";
const QB_USERNAME = process.env.QB_USERNAME || "admin";
const QB_PASSWORD = process.env.QB_PASSWORD || "";

let qbCookieJar: string | null = null;

function getCookieJar(): string {
	if (!qbCookieJar) {
		const dir = mkdtempSync("/tmp/qb-");
		qbCookieJar = join(dir, "cookies.txt");
	}
	return qbCookieJar;
}

async function qbLogin(pi: ExtensionAPI): Promise<string> {
	const jar = getCookieJar();

	const result = await pi.exec("curl", [
		"--silent", "--show-error", "--location", "--max-time", "10",
		"--cookie-jar", jar,
		"--data", `username=${encodeURIComponent(QB_USERNAME)}&password=${encodeURIComponent(QB_PASSWORD)}`,
		`${QB_URL}/api/v2/auth/login`,
	]);

	if (result.code !== 0) {
		throw new Error(`qBittorrent login failed: ${result.stderr.slice(0, 200)}`);
	}

	return jar;
}

async function qbRequest(
	pi: ExtensionAPI,
	method: "GET" | "POST",
	path: string,
	body?: string,
): Promise<string> {
	const jar = await qbLogin(pi);
	const args = ["--silent", "--show-error", "--location", "--max-time", "15", "--cookie", jar];

	if (method === "POST") {
		args.push("--request", "POST");
		if (body) {
			args.push("--header", "Content-Type: application/x-www-form-urlencoded", "--data", body);
		}
	}

	args.push(`${QB_URL}${path}`);
	const result = await pi.exec("curl", args);
	if (result.code !== 0) throw new Error(`qBittorrent request failed: ${result.stderr.slice(0, 200)}`);
	return result.stdout;
}

interface SonarrSeries {
	id: number;
	title: string;
	status: string;
	seasonCount: number;
	monitored: boolean;
	path?: string;
	nextAiring?: string;
	statistics?: { episodeFileCount: number; episodeCount: number; sizeOnDisk: number };
}

export default function (pi: ExtensionAPI) {
	// --- Sonarr: List all series ---
	pi.registerTool({
		name: "sonarr_list",
		label: "Sonarr - List Series",
		description: "List all series tracked in Sonarr with title, status, seasons, and monitoring state.",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${SONARR_URL}/api/v3/series?apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr request failed: ${result.stderr.slice(0, 200)}`);
			const series: SonarrSeries[] = JSON.parse(result.stdout || "[]");
			if (!series.length) return { content: [{ type: "text", text: "No series in Sonarr." }], details: {} };
			const lines = series.map((s) =>
				`${s.monitored ? "●" : "○"} #${s.id} ${s.title} — ${s.status}, ${s.seasonCount} season(s)` +
				(s.statistics ? `, ${s.statistics.episodeFileCount}/${s.statistics.episodeCount} episodes` : "")
			);
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: series.length } };
		},
	});

	// --- Sonarr: Search for a series ---
	pi.registerTool({
		name: "sonarr_search",
		label: "Sonarr - Search Series",
		description: "Search for a series by name on Sonarr. Use before adding a series.",
		parameters: Type.Object({
			query: Type.String({ description: "Series name to search for" }),
		}),
		async execute(_id, params) {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${SONARR_URL}/api/v3/series/lookup?term=${encodeURIComponent(params.query)}&apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr search failed: ${result.stderr.slice(0, 200)}`);
			const results = JSON.parse(result.stdout || "[]");
			if (!results.length) return { content: [{ type: "text", text: `No results for "${params.query}"` }], details: {} };
			const lines = results.map((r: { tvdbId: number; title: string; year?: number; network?: string; overview?: string }, i: number) =>
				`${i + 1}. ${r.title}${r.year ? ` (${r.year})` : ""} — tvdb:${r.tvdbId}` +
				(r.network ? ` [${r.network}]` : "") +
				(r.overview ? `\n   ${r.overview.slice(0, 200)}` : "")
			);
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: results.length } };
		},
	});

	// --- Sonarr: Get series details ---
	pi.registerTool({
		name: "sonarr_get",
		label: "Sonarr - Get Series Details",
		description: "Get detailed info about a specific series by Sonarr ID.",
		parameters: Type.Object({
			id: Type.Number({ description: "Sonarr series ID" }),
		}),
		async execute(_id, params) {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${SONARR_URL}/api/v3/series/${params.id}?apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr request failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// --- Sonarr: Get quality profiles ---
	pi.registerTool({
		name: "sonarr_quality_profiles",
		label: "Sonarr - List Quality Profiles",
		description: "List quality profiles available in Sonarr (needed when adding a series).",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${SONARR_URL}/api/v3/qualityProfile?apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr request failed: ${result.stderr.slice(0, 200)}`);
			const profiles = JSON.parse(result.stdout || "[]");
			const lines = profiles.map((p: { id: number; name: string }) => `#${p.id}: ${p.name}`);
			return { content: [{ type: "text", text: lines.join("\n") || "No profiles found." }], details: {} };
		},
	});

	// --- Sonarr: Get root folders ---
	pi.registerTool({
		name: "sonarr_root_folders",
		label: "Sonarr - List Root Folders",
		description: "List root folder paths in Sonarr (needed when adding a series).",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${SONARR_URL}/api/v3/rootFolder?apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr request failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout || "[]" }], details: {} };
		},
	});

	// --- Sonarr: Add series ---
	pi.registerTool({
		name: "sonarr_add",
		label: "Sonarr - Add Series",
		description: "Add a series to Sonarr. Use sonarr_search first to find the tvdbId. Use sonarr_quality_profiles and sonarr_root_folders to list available options.",
		parameters: Type.Object({
			tvdbId: Type.Number({ description: "TVDB ID of the series (from sonarr_search)" }),
			title: Type.String({ description: "Series title" }),
			qualityProfileId: Type.Number({ description: "Quality profile ID (use sonarr_quality_profiles)" }),
			rootFolderPath: Type.String({ description: "Root folder path (use sonarr_root_folders)" }),
			seriesType: StringEnum(["standard", "daily", "anime"] as const, { description: "Series type" }),
			seasons: Type.Array(Type.Object({
				seasonNumber: Type.Number(),
				monitored: Type.Boolean(),
			}), { description: "Array of seasons with monitoring state" }),
			monitored: Type.Optional(Type.Boolean({ description: "Whether the series is monitored (default: true)" })),
			searchOnAdd: Type.Optional(Type.Boolean({ description: "Search for missing episodes on add (default: true)" })),
		}),
		async execute(_id, params) {
			const body = JSON.stringify({
				tvdbId: params.tvdbId,
				title: params.title,
				qualityProfileId: params.qualityProfileId,
				rootFolderPath: params.rootFolderPath,
				seriesType: params.seriesType,
				seasons: params.seasons,
				monitored: params.monitored ?? true,
				addOptions: { searchForMissingEpisodes: params.searchOnAdd ?? true },
			});
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				"--request", "POST",
				"--header", "Content-Type: application/json",
				"--data", body,
				`${SONARR_URL}/api/v3/series?apikey=${SONARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Sonarr add failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout || "Series added successfully." }], details: {} };
		},
	});

	// --- Radarr: List all movies ---
	pi.registerTool({
		name: "radarr_list",
		label: "Radarr - List Movies",
		description: "List all movies tracked in Radarr with title, year, status, and monitored state.",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${RADARR_URL}/api/v3/movie?apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr request failed: ${result.stderr.slice(0, 200)}`);
			const movies = JSON.parse(result.stdout || "[]");
			if (!movies.length) return { content: [{ type: "text", text: "No movies in Radarr." }], details: {} };
			const lines = movies.map((m: { id: number; title: string; year?: number; status: string; monitored: boolean; hasFile: boolean }) =>
				`${m.hasFile ? "●" : m.monitored ? "○" : "◌"} #${m.id} ${m.title}${m.year ? ` (${m.year})` : ""} — ${m.status}${m.hasFile ? " [downloaded]" : ""}`
			);
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: movies.length } };
		},
	});

	// --- Radarr: Search for movies ---
	pi.registerTool({
		name: "radarr_search",
		label: "Radarr - Search Movies",
		description: "Search for a movie by name on Radarr. Use before adding a movie.",
		parameters: Type.Object({
			query: Type.String({ description: "Movie name to search for" }),
		}),
		async execute(_id, params) {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${RADARR_URL}/api/v3/movie/lookup?term=${encodeURIComponent(params.query)}&apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr search failed: ${result.stderr.slice(0, 200)}`);
			const results = JSON.parse(result.stdout || "[]");
			if (!results.length) return { content: [{ type: "text", text: `No results for "${params.query}"` }], details: {} };
			const lines = results.map((r: { tmdbId: number; title: string; year?: number; overview?: string }, i: number) =>
				`${i + 1}. ${r.title}${r.year ? ` (${r.year})` : ""} — tmdb:${r.tmdbId}` +
				(r.overview ? `\n   ${r.overview.slice(0, 200)}` : "")
			);
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: results.length } };
		},
	});

	// --- Radarr: Get movie details ---
	pi.registerTool({
		name: "radarr_get",
		label: "Radarr - Get Movie Details",
		description: "Get detailed info about a specific movie by Radarr ID.",
		parameters: Type.Object({
			id: Type.Number({ description: "Radarr movie ID" }),
		}),
		async execute(_id, params) {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${RADARR_URL}/api/v3/movie/${params.id}?apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr request failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// --- Radarr: Get quality profiles ---
	pi.registerTool({
		name: "radarr_quality_profiles",
		label: "Radarr - List Quality Profiles",
		description: "List quality profiles available in Radarr (needed when adding a movie).",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${RADARR_URL}/api/v3/qualityProfile?apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr request failed: ${result.stderr.slice(0, 200)}`);
			const profiles = JSON.parse(result.stdout || "[]");
			const lines = profiles.map((p: { id: number; name: string }) => `#${p.id}: ${p.name}`);
			return { content: [{ type: "text", text: lines.join("\n") || "No profiles found." }], details: {} };
		},
	});

	// --- Radarr: Get root folders ---
	pi.registerTool({
		name: "radarr_root_folders",
		label: "Radarr - List Root Folders",
		description: "List root folder paths in Radarr (needed when adding a movie).",
		parameters: Type.Object({}),
		async execute() {
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				`${RADARR_URL}/api/v3/rootFolder?apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr request failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout || "[]" }], details: {} };
		},
	});

	// --- Radarr: Add movie ---
	pi.registerTool({
		name: "radarr_add",
		label: "Radarr - Add Movie",
		description: "Add a movie to Radarr. Use radarr_search first to find the tmdbId. Use radarr_quality_profiles and radarr_root_folders to list available options.",
		parameters: Type.Object({
			tmdbId: Type.Number({ description: "TMDB ID of the movie (from radarr_search)" }),
			title: Type.String({ description: "Movie title" }),
			year: Type.Optional(Type.Number({ description: "Release year" })),
			qualityProfileId: Type.Number({ description: "Quality profile ID (use radarr_quality_profiles)" }),
			rootFolderPath: Type.String({ description: "Root folder path (use radarr_root_folders)" }),
			monitored: Type.Optional(Type.Boolean({ description: "Whether the movie is monitored (default: true)" })),
			searchOnAdd: Type.Optional(Type.Boolean({ description: "Search for movie on add (default: true)" })),
		}),
		async execute(_id, params) {
			const body = JSON.stringify({
				tmdbId: params.tmdbId,
				title: params.title,
				year: params.year,
				qualityProfileId: params.qualityProfileId,
				rootFolderPath: params.rootFolderPath,
				monitored: params.monitored ?? true,
				minimumAvailability: "announced",
				addOptions: { searchForMovie: params.searchOnAdd ?? true },
			});
			const result = await pi.exec("curl", [
				"--silent", "--show-error", "--location", "--max-time", "15",
				"--request", "POST",
				"--header", "Content-Type: application/json",
				"--data", body,
				`${RADARR_URL}/api/v3/movie?apikey=${RADARR_API_KEY}`,
			]);
			if (result.code !== 0) throw new Error(`Radarr add failed: ${result.stderr.slice(0, 200)}`);
			return { content: [{ type: "text", text: result.stdout || "Movie added successfully." }], details: {} };
		},
	});

	// --- qBittorrent: List torrents ---
	pi.registerTool({
		name: "qb_list",
		label: "qBittorrent - List Torrents",
		description: "List torrents in qBittorrent. Optionally filter by state.",
		parameters: Type.Object({
			filter: Type.Optional(
				StringEnum(["all", "downloading", "seeding", "completed", "paused", "active", "inactive", "stalled", "stalled_uploading", "stalled_downloading"] as const,
					{ description: "Filter torrents by state" },
				),
			),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 50)" })),
		}),
		async execute(_id, params) {
			const filter = params.filter ? `&filter=${params.filter}` : "";
			const data = await qbRequest(pi, "GET", `/api/v2/torrents/info?limit=${params.limit ?? 50}${filter}`);
			const torrents = JSON.parse(data || "[]");
			if (!torrents.length) return { content: [{ type: "text", text: "No torrents matching filter." }], details: {} };

			const lines = torrents.map((t: {
				name: string; hash: string; state: string; progress: number;
				size: number; downloaded: number; ratio: number; dlspeed: number; upspeed: number;
				eta: number; added_on: number;
			}) => {
				const pct = (t.progress * 100).toFixed(1);
				const speed = `↓${formatSpeed(t.dlspeed)} ↑${formatSpeed(t.upspeed)}`;
				const etaStr = t.eta > 0 ? `ETA: ${formatEta(t.eta)}` : t.eta === 0 ? "Done" : "";
				return `[${t.state}] ${t.name}\n   ${pct}% ${speed} Ratio:${t.ratio.toFixed(2)} ${etaStr}`
			});
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: torrents.length } };
		},
	});

	// --- qBittorrent: Get torrent details ---
	pi.registerTool({
		name: "qb_get",
		label: "qBittorrent - Torrent Details",
		description: "Get detailed info about a specific torrent by hash.",
		parameters: Type.Object({
			hash: Type.String({ description: "Torrent hash" }),
		}),
		async execute(_id, params) {
			const data = await qbRequest(pi, "GET", `/api/v2/torrents/info?hashes=${params.hash}`);
			return { content: [{ type: "text", text: data || "Torrent not found." }], details: {} };
		},
	});

	// --- qBittorrent: Get global transfer info ---
	pi.registerTool({
		name: "qb_transfer_info",
		label: "qBittorrent - Transfer Info",
		description: "Get global transfer information from qBittorrent (download/upload speed, total downloaded/uploaded, etc.)",
		parameters: Type.Object({}),
		async execute() {
			const data = await qbRequest(pi, "GET", "/api/v2/transfer/info");
			const info = JSON.parse(data || "{}");
			const lines = [
				`Download speed: ${formatSpeed(info.dl_info_speed || 0)}`,
				`Upload speed:   ${formatSpeed(info.up_info_speed || 0)}`,
				`Downloaded:     ${formatBytes(info.dl_info_data || 0)}`,
				`Uploaded:       ${formatBytes(info.up_info_data || 0)}`,
				`DHT nodes:      ${info.dht_nodes || 0}`,
			];
			return { content: [{ type: "text", text: lines.join("\n") }], details: {} };
		},
	});

	// --- qBittorrent: List torrents that are currently downloading ---
	pi.registerTool({
		name: "qb_downloading",
		label: "qBittorrent - Active Downloads",
		description: "List currently downloading torrents with progress and speed.",
		parameters: Type.Object({}),
		async execute() {
			const data = await qbRequest(pi, "GET", "/api/v2/torrents/info?filter=downloading&sort=added_on&reverse=true");
			const torrents = JSON.parse(data || "[]");
			if (!torrents.length) return { content: [{ type: "text", text: "No active downloads." }], details: {} };

			const lines = torrents.map((t: {
				name: string; hash: string; progress: number; size: number; downloaded: number;
				dlspeed: number; eta: number; state: string;
			}) => {
				const pct = (t.progress * 100).toFixed(1);
				const speed = formatSpeed(t.dlspeed);
				const etaStr = t.eta > 0 ? formatEta(t.eta) : "calculating...";
				const downloaded = formatBytes(t.downloaded);
				const total = formatBytes(t.size);
				return `${t.name}\n   ${pct}% (${downloaded}/${total}) — ${speed}/s — ETA: ${etaStr} [${t.state}]`;
			});
			return { content: [{ type: "text", text: lines.join("\n") }], details: { count: torrents.length } };
		},
	});

	// Clean up qBittorrent cookie jar on session shutdown
	pi.on("session_shutdown", async () => {
		if (qbCookieJar) {
			try { rmSync(qbCookieJar); } catch {}
			try {
				const dir = qbCookieJar.substring(0, qbCookieJar.lastIndexOf("/"));
				rmSync(dir, { recursive: true, force: true });
			} catch {}
			qbCookieJar = null;
		}
	});
}

function formatSpeed(bytesPerSec: number): string {
	if (bytesPerSec >= 1_000_000) return `${(bytesPerSec / 1_000_000).toFixed(1)} MB/s`;
	if (bytesPerSec >= 1_000) return `${(bytesPerSec / 1_000).toFixed(1)} KB/s`;
	return `${bytesPerSec} B/s`;
}

function formatBytes(bytes: number): string {
	if (bytes >= 1_000_000_000) return `${(bytes / 1_000_000_000).toFixed(1)} GB`;
	if (bytes >= 1_000_000) return `${(bytes / 1_000_000).toFixed(1)} MB`;
	if (bytes >= 1_000) return `${(bytes / 1_000).toFixed(1)} KB`;
	return `${bytes} B`;
}

function formatEta(seconds: number): string {
	const d = Math.floor(seconds / 86400);
	const h = Math.floor((seconds % 86400) / 3600);
	const m = Math.floor((seconds % 3600) / 60);
	const s = seconds % 60;
	const parts: string[] = [];
	if (d) parts.push(`${d}d`);
	if (h) parts.push(`${h}h`);
	if (m) parts.push(`${m}m`);
	if (s || !parts.length) parts.push(`${s}s`);
	return parts.join(" ");
}


