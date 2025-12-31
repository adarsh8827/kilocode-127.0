// kilocode_change - new file
import axios from "axios"
import https from "https"
import { ContextProxy } from "../core/config/ContextProxy"

/**
 * Configures axios globally based on SSL verification setting
 * @param contextProxy The context proxy to read settings from
 */
export function configureAxiosSSL(contextProxy: ContextProxy | undefined): void {
	// kilocode_change: Default to SSL verification disabled (bypass SSL by default)
	const sslVerificationEnabled = contextProxy?.getValue("sslVerificationEnabled") ?? false

	// Configure axios defaults for HTTPS requests
	if (sslVerificationEnabled) {
		// Enable SSL verification (when explicitly enabled)
		axios.defaults.httpsAgent = new https.Agent({
			rejectUnauthorized: true,
		})
		// Restore default behavior for Node.js
		delete process.env.NODE_TLS_REJECT_UNAUTHORIZED
	} else {
		// Disable SSL verification (default behavior - bypass SSL)
		axios.defaults.httpsAgent = new https.Agent({
			rejectUnauthorized: false,
		})
		// Set NODE_TLS_REJECT_UNAUTHORIZED to bypass SSL for all Node.js HTTPS requests
		process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
	}
}
