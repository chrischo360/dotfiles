/**
 * Theme Sync Extension
 *
 * Watches ~/.config/active-theme and ~/.config/theme-mode and maps them
 * to the corresponding pi theme JSON. Changes take effect immediately
 * via fs.watch — no polling.
 *
 * Theme map (theme × mode → pi theme name):
 *   dracula      dark  → dracula
 *   dracula      light → github-light      (dracula has no official light variant)
 *   onedark      dark  → onedark
 *   onedark      light → papercolor-light
 *   rose-pine    dark  → rose-pine
 *   rose-pine    light → rose-pine-dawn
 *   papercolor   dark  → papercolor-dark
 *   papercolor   light → papercolor-light
 *   github-dark  dark  → github-dark
 *   github-dark  light → github-light
 *   catppuccin   dark  → catppuccin-mocha
 *   catppuccin   light → catppuccin-latte
 *
 * State files written by your theme script:
 *   ~/.config/active-theme → dracula | onedark | rose-pine | papercolor | github-dark | catppuccin
 *   ~/.config/theme-mode   → dark | light
 */

import { watch, existsSync, readFileSync } from "node:fs";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const ACTIVE_THEME_FILE = `${process.env.HOME}/.config/active-theme`;
const THEME_MODE_FILE   = `${process.env.HOME}/.config/theme-mode`;

// Maps (active-theme, mode) → pi theme name
const THEME_MAP: Record<string, Record<string, string>> = {
	"dracula":     { dark: "dracula",          light: "github-light"     },
	"onedark":     { dark: "onedark",          light: "papercolor-light" },
	"rose-pine":   { dark: "rose-pine",        light: "rose-pine-dawn"   },
	"papercolor":  { dark: "papercolor-dark",  light: "papercolor-light" },
	"github-dark": { dark: "github-dark",      light: "github-light"     },
	"catppuccin":  { dark: "catppuccin-mocha", light: "catppuccin-latte" },
};

function readTrimmed(path: string): string {
	try {
		return readFileSync(path, "utf-8").trim().toLowerCase();
	} catch {
		return "";
	}
}

function resolveTheme(): string {
	const activeTheme = readTrimmed(ACTIVE_THEME_FILE);
	const mode        = readTrimmed(THEME_MODE_FILE) || "dark";
	const modeMap     = THEME_MAP[activeTheme];

	if (!modeMap) {
		// Unknown active-theme value — fall back to built-in dark/light
		return mode === "light" ? "light" : "dark";
	}

	return modeMap[mode] ?? (mode === "light" ? "light" : "dark");
}

export default function (pi: ExtensionAPI) {
	let watchers: ReturnType<typeof watch>[] = [];
	// Captured from session_start so watcher callbacks can call setTheme
	let applyTheme: (() => void) | null = null;

	pi.on("session_start", async (_event, ctx) => {
		applyTheme = () => {
			const name = resolveTheme();
			const result = ctx.ui.setTheme(name);
			if (!result.success) {
				ctx.ui.notify(`theme-sync: unknown theme "${name}"`, "warning");
			}
		};

		// Apply immediately on session start
		applyTheme();

		// Watch both state files for changes
		for (const filePath of [ACTIVE_THEME_FILE, THEME_MODE_FILE]) {
			if (!existsSync(filePath)) continue;

			try {
				const watcher = watch(filePath, () => {
					applyTheme?.();
				});
				watcher.on("error", () => {
					// File removed or inaccessible — ignore
				});
				watchers.push(watcher);
			} catch {
				// fs.watch not available — skip silently
			}
		}
	});

	pi.on("session_shutdown", () => {
		for (const w of watchers) {
			try { w.close(); } catch {}
		}
		watchers = [];
		applyTheme = null;
	});
}
