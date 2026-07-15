# Stey Cross-Project Service Dictionary

Last updated by automated scan with **ANCHOR-relative** path format.

## Path Model

- `ANCHOR` = discovered parent directory that contains one or more of: `Stey/`, `SteyApi/`, `SteyConnect/`, `SteyWeb/`.
- **Every path in this file is relative to `ANCHOR`.** Never rewrite them with an absolute prefix (`/Users/...`, `C:\...`, `~/...`); local roots differ per contributor.
- Use forward slashes only, even when consumed on Windows.

Canonical parent aliases:

- `stey` -> `Stey`
- `stey-api` -> `SteyApi`
- `stey-connect` -> `SteyConnect`
- `stey-web` -> `SteyWeb`

## Category: stey (business services)

Parent root: `Stey`

Detected repos (`build.sbt`):

- `Stey/SteyAccess`
- `Stey/SteyAnalysis`
- `Stey/SteyAuth`
- `Stey/SteyCms`
- `Stey/SteyCrm`
- `Stey/SteyCrs`
- `Stey/SteyDc`
- `Stey/SteyEcom`
- `Stey/SteyEsg`
- `Stey/SteyFinance`
- `Stey/SteyHskp`
- `Stey/SteyIm`
- `Stey/SteyIndex`
- `Stey/SteyIotData`
- `Stey/SteyIotV2`
- `Stey/SteyNotification`
- `Stey/SteyProfile`
- `Stey/SteyProject`
- `Stey/SteyReport`
- `Stey/SteyRms`
- `Stey/SteySc`
- `Stey/SteySocial`
- `Stey/SteySwitch`
- `Stey/SteyWallet`
- `Stey/SteyWo`

Detailed module mapping sample:

- Service: `stey-crm`
  - Repo root: `Stey/SteyCrm`
  - Source modules:
    - `Stey/SteyCrm/stey-crm-impl`
    - `Stey/SteyCrm/stey-crm-api`

## Category: stey-api (Play/Tapir API aggregation)

Parent root: `SteyApi`

Detected repos (`build.sbt`):

- `SteyApi/SteyApiApp`
- `SteyApi/SteyApiConsole`
- `SteyApi/SteyApiStaffapp`
- `SteyApi/SteyApiSystem`
- `SteyApi/SteyApiWeb`

## Category: stey-connect (external integrations)

Parent root: `SteyConnect`

Detected repos (`build.sbt`):

- `SteyConnect/SteyConnectAlipay`
- `SteyConnect/SteyConnectAsiapay`
- `SteyConnect/SteyConnectCamera`
- `SteyConnect/SteyConnectCoolkit`
- `SteyConnect/SteyConnectEmail`
- `SteyConnect/SteyConnectEsign`
- `SteyConnect/SteyConnectHefeng`
- `SteyConnect/SteyConnectKaiterra`
- `SteyConnect/SteyConnectLifesmart`
- `SteyConnect/SteyConnectLlm`
- `SteyConnect/SteyConnectMeraki`
- `SteyConnect/SteyConnectPush`
- `SteyConnect/SteyConnectRadix`
- `SteyConnect/SteyConnectSalto`
- `SteyConnect/SteyConnectSms`
- `SteyConnect/SteyConnectTranslator`
- `SteyConnect/SteyConnectTuya`
- `SteyConnect/SteyConnectVerify`
- `SteyConnect/SteyConnectWechat`
- `SteyConnect/SteyConnectXiaomentong`
- `SteyConnect/SteyConnectYeelock`
- `SteyConnect/SteyConnectYimu`
- `SteyConnect/SteyConnectYuelong`
- `SteyConnect/SteyConnectYunding`

## Category: stey-web (web applications)

Parent root: `SteyWeb`

Detected app/config roots (`package.json`):

- `SteyWeb/WebCommonConfig`
- `SteyWeb/WebConsoleV3`
- `SteyWeb/WebEmbedded`
- `SteyWeb/WebHomeStl`
- `SteyWeb/WebHomeV2`

## Notes

- Parent folders are PascalCase (`Stey`, `SteyApi`, `SteyConnect`, `SteyWeb`) while logical categories remain lowercase (`stey`, `stey-api`, `stey-connect`, `stey-web`).
- Additional ecosystems detected outside the four categories: `SteyCommon`, `SteySbt`, `SteySlickCodegen`, `CMS4s`, and mini-app roots (`MiniAppHskp`, `MiniAppVirtualTour`).
- iOS/Android marker files were not detected in the current scan results (`*.xcodeproj`, `*.xcworkspace`, `AndroidManifest.xml`, `build.gradle`).
