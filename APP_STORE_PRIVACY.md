# App Store Privacy Questionnaire

This document provides answers for the App Store Connect privacy questionnaire.

## Data Collection

### Do you or your third-party partners collect data from this app?

**Answer: NO**

Personal OS does not collect any data. All data remains on the user's device or in their personal iCloud account.

## Privacy Nutrition Label

### Data Types

For each category, select "No" or provide the following information:

#### Contact Info
- **Collected**: No

#### Health & Fitness
- **Collected**: No
- **Note**: HealthKit data is accessed with permission but not collected by the app

#### Financial Info
- **Collected**: No
- **Note**: Portfolio data is stored locally, not collected

#### Location
- **Collected**: No

#### Sensitive Info
- **Collected**: No

#### Contacts
- **Collected**: No

#### User Content
- **Collected**: No
- **Note**: All user content (tasks, notes, posts) stays on device

#### Browsing History
- **Collected**: No

#### Search History
- **Collected**: No

#### Identifiers
- **Collected**: No

#### Purchases
- **Collected**: No

#### Usage Data
- **Collected**: No

#### Diagnostics
- **Collected**: No
- **Note**: Only if user opts into Apple's crash reporting

#### Other Data
- **Collected**: No

## Data Linked to User

**Answer: NO**

We do not link any data to the user's identity because we don't collect any data.

## Data Used to Track User

**Answer: NO**

We do not use data for tracking purposes.

## Third-Party SDKs

### Do you use third-party SDKs?

**Answer: NO**

Personal OS uses only Apple's native frameworks:
- SwiftUI
- SwiftData
- Combine
- Foundation
- HealthKit
- UserNotifications
- Security
- Network

No third-party analytics, advertising, or tracking SDKs are included.

## API Keys

### How are API keys handled?

- Users provide their own API keys (optional)
- Keys are stored in device Keychain
- Keys are never transmitted to our servers
- Keys are used only to make direct requests to third-party services

## HealthKit

### HealthKit Data Usage

- **Purpose**: Display health metrics in the app
- **Storage**: Remains on device and in user's iCloud Health data
- **Sharing**: Not shared with any third parties
- **Permission**: Explicit user permission required

## iCloud

### iCloud Sync

- **Optional**: User can enable/disable
- **Storage**: User's personal iCloud account
- **Access**: We do not have access to user's iCloud data
- **Encryption**: Handled by Apple

## Privacy Policy URL

Provide the URL to your privacy policy:
- [Your Privacy Policy URL]

## Support URL

Provide the URL for user support:
- [Your Support URL]

## Age Rating

Recommended: **4+**

The app does not contain:
- Unrestricted web access
- User-generated content sharing
- Location services
- Social networking features (content stays local)

## Compliance

### COPPA (Children's Online Privacy Protection Act)
- **Compliant**: Yes
- **Reason**: No data collection

### GDPR (General Data Protection Regulation)
- **Compliant**: Yes
- **Reason**: No personal data processing

### CCPA (California Consumer Privacy Act)
- **Compliant**: Yes
- **Reason**: No personal information collection or sale

## App Tracking Transparency (ATT)

### Do you need to request tracking permission?

**Answer: NO**

We do not track users, so ATT permission is not required.

## Data Retention

### How long is data retained?

- **Local Data**: Until user deletes it
- **iCloud Data**: Follows Apple's iCloud retention policies
- **Our Servers**: N/A - we don't have servers

## Data Deletion

### How can users delete their data?

1. Delete specific items within the app
2. Use "Clear All Data" in Settings
3. Delete the app from their device
4. Disable iCloud sync and delete iCloud backup

## Security Measures

- Keychain for sensitive data
- HTTPS for all network requests
- Certificate pinning for critical connections
- iOS Data Protection
- No server-side storage

## Changes to Privacy Practices

Users will be notified of privacy policy changes through:
- App updates
- In-app notifications
- Updated "Last Modified" date in Privacy Policy

## Contact Information

For privacy inquiries:
- [Your Contact Email]
- [Your Support Website]

---

**Last Updated**: November 24, 2024

**App Version**: 2.0.0
