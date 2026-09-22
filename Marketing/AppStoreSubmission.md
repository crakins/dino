# App Store Connect Submission Guide

Guidance for submitting the Dinosaur watchOS app (bundle `com.a6enterprises.Dinosaur.watchkitapp`) to App Store Connect under the A6 Enterprises LLC developer account. Written because the YouTube walkthrough being used got stuck on the signing step — a lot of tutorials predate recent changes to Xcode's signing UI and Apple's business-account agreement flow.

## 1. Prerequisites

- Active Apple Developer Program membership for A6 Enterprises LLC (organization/business accounts require an Account Holder to accept agreements — see step 2).
- Xcode signed in with an Apple ID that has **Admin** or **App Manager** role on that team.
- App record already created in App Store Connect (or create it in step 5).

## 2. Fixing "Communication with Apple failed" / "No profiles found"

This error is about account/agreement state, not about needing a registered physical device — App Store distribution profiles don't require one.

1. **Xcode → Settings → Accounts** — confirm the right Apple ID is listed, select it, click **Download Manual Profiles** to force a refresh.
2. **developer.apple.com/account**, signed in as that same Apple ID — check for a pending **Program License Agreement**. Business/organization accounts often need the Account Holder to re-accept this after renewal or role changes. This is the most common cause of this exact error.
3. In Xcode's Signing & Capabilities tab, reselect the **Team** dropdown (even back to the same value) to force a re-fetch, then click **Try Again**.
4. Still stuck: quit Xcode, delete `~/Library/Developer/Xcode/DerivedData`, relaunch, and retry.
5. Last resort: toggle **Automatically manage signing** off, then back on, for the watch app target.

Do this for **both** targets that ship in the archive — the container iOS/watch app and the Watch App target — since each has its own signing section.

## 3. Signing settings to verify

For each target (Dinosaur, Dinosaur Watch App):
- **Automatically manage signing**: checked (recommended unless you manage manual profiles).
- **Team**: A6 Enterprises LLC.
- **Bundle Identifier**: matches what's registered in App Store Connect exactly.
- **Signing Certificate**: should resolve to "Apple Distribution" once you archive (Xcode shows "Apple Development" during normal builds/debugging — that's expected and not an error).

## 4. Archiving

1. In Xcode, set the run destination to **Any watchOS Device (arm64)** — you can't archive with a Simulator destination selected.
2. **Product → Archive**.
3. Once archiving finishes, the Organizer window opens automatically with your build listed.

## 5. App Store Connect record

Before or after archiving, create the app record at appstoreconnect.apple.com if it doesn't exist:
- Platform: watchOS (or iOS if bundling the companion iPhone app — this project has a `Dinosaur iPhone` target too).
- Bundle ID: must match the registered identifier.
- SKU: any internal identifier, not shown publicly.

## 6. Uploading

1. In the Organizer, select your archive → **Distribute App**.
2. Choose **App Store Connect** → **Upload**.
3. Accept the default signing options (App Store Connect handles re-signing during processing if needed) unless you have a specific manual profile requirement.
4. Wait for upload to complete, then check App Store Connect → TestFlight or the app's build list — processing typically takes 5–30 minutes.

## 7. After upload

- Build appears under **App Store Connect → your app → TestFlight** (and later under the version's build picker) once processing finishes.
- Fill out the App Store listing (screenshots, description, privacy info) if not already done.
- Attach the processed build to a version and submit for review.

## Notes specific to this project

- Two targets ship together: `Dinosaur Watch App` (the watch target itself) and the `Dinosaur` container target — both need signing configured correctly for the archive to validate.
- If a `Dinosaur iPhone` companion target is included in the archive, App Store Connect requires it to be signed and have a valid bundle ID too, even if the primary product is the watch app.
