# 2. Rider App Functionality

The Rider app allows end-users to book vehicles for commuting.

## Core Workflow
1. Register using a mobile number (OTP via Twilio).
2. Set pick-up and drop-off addresses.
3. Select vehicle type and payment mode.
4. Request the ride.
5. Track the assigned driver.
6. Complete the trip, pay, and rate the driver.

## Key Features
- **Authentication**: Sign up via mobile number and OTP, complete profile (First/Last name, email, password, location). Same phone number can be used for Driver and Rider apps (but cannot be active on both simultaneously).
- **Location Management**: Set Pick Up/Drop location manually via search or map pin. Save 'Home' and 'Work' favorites.
- **Multiple Stops**: Add up to 2 extra stops before the final drop-off. Stop wait time is configurable (e.g., 1-10 mins).
- **Vehicle Categories**: Choose from Auto, Micro, Mini, Luxury, Prime, Bike.
- **Ride Comfort Options**: Request specific accommodations: Women only drivers, Child seat availability, and Wheelchair accessibility.
- **Payment Options**: Cash, Wallet, Credit/Debit Card (Stripe 3D secure), Google Pay, and PayStack (for supported regions).
- **Wallet**: Add funds to the wallet to pay for rides securely.
- **Promo Codes**: Apply admin-generated promo codes for discounts.
- **Ride Scheduling**: Schedule rides up to 30 days in advance (configurable buffer, e.g., 20 mins before).
- **Safety & Emergency**: 
  - Add up to 5 Emergency Contacts. 
  - SOS button to dial 911 or share trip details with contacts. 
  - Precaution notifications (e.g., COVID-19 mask mandates).
  - OTP Verification (4-digit code provided to driver to start the ride).
- **In-App Communication**: Chat with the driver (with unread indicators) or use the In-Call option.
- **Trip History & Reviews**: View past/current trips, rate drivers, and add tips.
- **Localization**: Multi-currency and multi-language support, including **RTL (Right-to-Left)** support for Arabic.
- **Dark Mode**: System default, light, or dark mode available in settings.
