# Help people discover Relay

## First, make testing easy

Lead with one concrete use case: “Choose which Mac browser or Chrome profile opens a link.” Link straight to the latest release, explain macOS requirements, and disclose the current first-launch security prompt. Ask a small group of testers to report what happened rather than asking only for stars.

The README uses a descriptive title, feature explanations, image alt text, a flow diagram, and links to installation help. GitHub topics and the repository description make the project easier to browse. These steps help discovery; they cannot guarantee Google indexing or ranking. See [Google’s SEO starter guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide).

## Suggested launch sequence

1. Recruit 5–10 Apple Silicon testers with different browser setups. Prioritize macOS 15 and 26, permission-denied cases, Chrome profiles, and keyboard-only use.
2. Record a 20–30 second demonstration: click a link, choose a browser, remember a domain, and inspect a cleaned URL. Use synthetic sites and profile names.
3. Share one honest launch post in a relevant Mac community and on Show HN when the download has been tested. Follow each community’s self-promotion rules and disclose that you maintain the app. Do not mass-post or buy stars.
4. Ask for specific feedback: installation trouble, a browser that behaves differently, or a routing workflow that is missing. Respond with reproducible fixes and release notes.
5. After signing/notarization and installation are dependable, pursue a Homebrew cask or tap and relevant open-source Mac app directories. Check each directory’s submission rules before submitting.
6. If interest grows, add a public landing page on a domain you control with the same clear description, demo, download, and privacy information. Verify it in Google Search Console and submit its sitemap. A GitHub README alone does not give you control over GitHub’s search indexing.

## Track useful signals

Look at successful installations, reproducible bug reports, returning testers, release downloads, and resolved compatibility issues. Stars are a discovery signal, not evidence of reliability. Use GitHub’s aggregate repository information; the app does not need telemetry for this launch.

## Most valuable next investment

Apple Developer ID signing and notarization will remove a major trust and installation obstacle. Avoid presenting an unnotarized early release as a polished, universally compatible product. Be clear about what is tested and invite help with the remaining gaps.
