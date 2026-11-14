# E2E Test Execution Guide

### 0. Dynamic Play Store App Installation Flow (New Milestone - Standalone)
Sequentially navigates to Google Play Store using redirect links from `.env` and downloads the Rider and Driver applications:
```bash
npm run test:store-install
# or shortcut:
npm run test:playstore
```

---

### 0.1 Unified Step #2 Orchestrator Flow (Store Install + Step #1 E2E)
Executes the full automated workflow from scratch: Store Installation $\rightarrow$ Driver Online $\rightarrow$ Rider Booking $\rightarrow$ Driver Trip Lifecycle:
```bash
npm run "test:step #2"
# or shortcut:
npm run test:step2
```

---

### 1. Bring Driver Online Flow (Phase: "During booking" Setup)
Launches the Driver app, logs in with static credentials from `.env`, completes the location disclosure dialog, handles system settings (`Allow all the time`), dismisses battery & background prompts, and sets driver status to Online:
```bash
npx tsx tests/e2e/wooberly_driver_online_flow.ts
# or
npm run test:driver-online
```

---

### 2. Test with Rider Login Flow (Existing user from .env -> Booking)
Runs the Rider login, selects drop location, selects available category, chooses Cash, proceeds through precautions, and transitions to "Connecting nearby drivers":
```bash
npx tsx tests/e2e/wooberly_login_e2e_flow.ts
# or
npm run test:login
```

---

### 3. Test with Rider Signup Flow (Fresh user & Profile creation -> Booking)
```bash
npx tsx tests/e2e/wooberly_e2e_flow.ts
# or
npm run test:signup
```

> **Note**: Both Rider flows keep the phone in the foreground on the driver-searching screen after on-demand booking completes without auto-closing or restarting the app.
