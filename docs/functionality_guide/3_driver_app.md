# 3. Driver App Functionality

The Driver app allows vehicle owners/renters to offer rides on the platform.

## Core Workflow
1. Register using a mobile number and upload legal documents.
2. Add payout methods.
3. Toggle online/offline status.
4. Accept or decline ride requests.
5. Navigate to pick up the rider and start the trip (OTP verification).
6. Complete the ride, add toll fees, and rate the rider.

## Key Features
- **Onboarding & Verification**: Provide vehicle details (Name, Number, Model, Color, Comfort Options). Upload driver's license (front/back), vehicle registration, and insurance.
- **Availability Management**: Simple GO / OFFLINE toggle. Driver cannot take rides if they are logged in as a rider on an active trip.
- **Payout Methods**: Add bank accounts securely to receive automated payouts from the admin.
- **Trip Operations**: 
  - View rider pickup/drop-off. 
  - Navigate using maps. 
  - Handle Multiple Stops (confirm stop arrivals).
  - Add toll fees manually at the end of the trip if applicable.
- **Driver Wallet Management**: 
  - For cash trips, the platform service fee is deducted from the driver's wallet.
  - Driver must maintain a minimum wallet balance (set by admin) to receive new ride requests.
  - If the wallet goes negative, the driver must be recharged by the admin to continue.
- **Earnings & History**: View weekly and total earnings, tips, and distance traveled.
- **Privacy Mode**: An eye-icon toggle on the home screen to hide total earnings from being visible to passengers.
- **In-App Communication**: Chat and Call functions available once a ride is accepted.
- **Localization & Themes**: Multi-language, RTL support, and Dark Mode.
