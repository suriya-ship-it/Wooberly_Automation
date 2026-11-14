# 5. Advanced Feature Specifications

This document outlines specialized features introduced across various versions of Wooberly.

## Driver Wallet & Cash Management (v3.3)
To ensure the platform collects its service fees on cash trips, the Driver Wallet system is strictly enforced.
- **Mechanism**: When a driver completes a cash trip, they keep the physical cash. The platform instantly deducts its service commission from the driver's virtual wallet.
- **Minimum Balance**: Admins configure a minimum wallet balance. If a driver's balance falls below this threshold (or goes negative), they are blocked from receiving new ride requests.
- **Recharging**: Drivers cannot recharge their own wallets. They must remit cash to the admin, who then manually recharges the driver's wallet via the Admin Panel.

## Multiple Stops (v2.0)
Riders can add up to 2 intermediate stops before their final drop-off location.
- The pickup and drop-off cannot be identical unless there is at least one intermediate stop between them.
- Stop waiting times are strictly configured by the admin (1 to 10 minutes).
- Stops can be added, changed, or deleted even after the trip has started, dynamically updating the fare and driver route.

## Ride Comfort Options (v3.0)
Allows riders to request specialized vehicles. Drivers must opt-in via their Vehicle Details settings.
- **Women Only Drivers**: Restricts the matching pool to female drivers (safety feature for female passengers).
- **Child Seat**: Ensures the dispatched vehicle has a child safety seat.
- **Wheelchair Accessibility**: Ensures the vehicle is equipped to handle wheelchairs.

## Security & Verification (v3.3)
- **OTP Verification**: Provides a 4-digit code to the rider. The driver must physically ask the rider for this code and enter it into their app to begin the trip, preventing fraudulent ride starts.

## Theming & Localization
- **Dark Mode**: Integrated across Web, Rider, and Driver apps. Defaults to the system setting, but can be manually overridden.
- **RTL Support**: Full Right-To-Left UI mirroring for languages like Arabic.
