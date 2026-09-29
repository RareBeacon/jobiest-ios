# jobiest-ios

Official Jobiest native iOS application (SwiftUI).

**Product:** [jobiest.com](https://jobiest.com) - Your AI career agent. Only sends applications you approve.
**Free tools:** [ATS resume scanner](https://jobiest.com/free-ats-resume-scanner), [all 10 free career tools](https://jobiest.com/tools)
**How it works:** [jobiest.com/how-it-works](https://jobiest.com/how-it-works)
Official Jobiest native iOS application (SwiftUI). Starter kit prepared 2026-09-28.

## What this is

A working SwiftUI foundation for the Jobiest iOS app, designed to mirror the Android
app's architecture: native screens + API client talking to the same jobiest.com
backend. It contains sign-in (Supabase), job search, saved jobs, applications with
approve/reject, profile and entitlements, with tokens stored in the iOS Keychain.

## Zero-budget build and test plan (no Apple Developer Program needed yet)

IMPORTANT: TestFlight requires the paid Apple Developer Program ($99/year). With no
budget, the free path is:

1. **iOS Simulator (free, unlimited):** build and run on the MacBook in Xcode's
   iPhone Simulator. This is where 95% of development happens.
2. **Free device sideloading (free):** connect a physical iPhone to the MacBook with
   a cable. Xcode signs the app with a free "Personal Team" certificate tied to your
   Apple ID. The app runs on the real iPhone.
   - The signature expires every 7 days: just reconnect and rebuild.
   - Limit: about 3 sideloaded apps per device, 10 app IDs per week.
   - Free signing does NOT include push notifications. V1 of the app polls the API
     while open instead. Push (APNs) is added later with the paid account.
3. **When budget allows ($99/year):** enroll at developer.apple.com, enable push,
     distribute via TestFlight, then the App Store. The code built now carries over
     100%; only signing and distribution change.

## Setup on the MacBook (step by step)

1. Install Xcode from the Mac App Store (free; several GB download).
2. Open Xcode once, go to Settings > Accounts, add your Apple ID (free account is
   fine).
3. File > New > Project > iOS > App:
   - Product Name: `Jobiest`
   - Interface: SwiftUI, Language: Swift, Storage: None
   - Team: Your Personal Team
   - Bundle Identifier: `com.phoslab.jobiest`
4. Delete the auto-generated `ContentView.swift` and the template `JobiestApp.swift`
   from the new project.
5. Drag the entire `Jobiest/` folder from this repository into the Xcode project
   navigator. Choose "Copy items if needed" and your app target.
6. Open `Jobiest/Config.swift` and paste the Supabase anon key (it is the public,
   safe-to-embed key, the same one the Android app ships with).
7. Select an iPhone Simulator and press Cmd+R. The app runs.
8. To test on a real iPhone: connect it with a cable, trust the computer on the
   phone, select the device in Xcode, press Cmd+R. On the phone accept the
   "untrusted developer" prompt under Settings > General > VPN & Device Management.

## Rules for the coding agent continuing this project

- Test ONLY with a dedicated test account, never the owner's personal account.
- The API contract is in `API_INTEGRATION_GUIDE.md`. Verify response shapes against
  real responses as you wire screens; adjust Codable models if fields differ.
- No billing or purchase screens in the app (Apple rule 3.1.1): the app is sign-in
  and usage only; subscriptions are managed on the website.
- The app must include account deletion in-app before any App Store submission
  (Apple rule 5.1.1). Add it in Settings later; not needed for private testing.
- Push notifications: do NOT add the APNs entitlement while on free signing; use the
  polling approach in `ApplicationsViewModel` until the paid account exists.

## Project structure

```
Jobiest/
  JobiestApp.swift        App entry + sign-in gate
  Config.swift            Base URLs + public anon key
  Models.swift            Codable models (session, profile, job, application...)
  KeychainStore.swift     iOS Keychain wrapper for tokens
  AuthService.swift       Supabase auth: sign in, sign up, refresh, sign out
  APIClient.swift         Jobiest REST client (jobs, applications, profile...)
  Views/
    LoginView.swift       Email + password sign-in / sign-up
    MainTabView.swift     Bottom tabs
    JobsView.swift        Job search, results, save/bookmark
    ApplicationsView.swift  Applications list + approve / reject actions
    ProfileView.swift     Profile, plan info, sign out
```
