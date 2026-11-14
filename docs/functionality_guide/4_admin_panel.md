# 4. Admin Panel Functionality

The Admin panel is a web-based dashboard used to monitor and manage the entire Wooberly platform.

## Core Management Modules
- **Dashboard**: High-level metrics for Drivers, Riders, Bookings, and Earnings (daily/weekly/monthly).
- **Admin Users & Roles**: Create sub-admins and assign granular privileges (e.g., Booking Manager, Location Manager).
- **User Management**: View, edit, ban, or export Rider and Driver accounts. View uploaded driver documents and vehicle details to approve or decline drivers.
- **Location & Geofencing**: Add operational cities/regions and draw geofences on the map to control service areas and specific pricing.
- **Fare Management**: Configure pricing per location and vehicle category. Define base fare, unit price, minute price, driver/rider commissions, and configure **Surge Pricing** (day/time-based multipliers).
- **Manual & Scheduled Dispatch**: 
  - Admins can manually book rides for users (Instant or Scheduled).
  - **Auto-Assign**: Automatically routes the dispatch to the nearest driver.
  - **Manual-Assign**: Admin chooses a specific driver from a ranked list based on vicinity and rating.
- **Bookings & History**: Comprehensive lists of Scheduled, Completed, and Cancelled bookings. Admin can cancel ongoing rides directly from the panel.
- **Financial & Payouts**: 
  - Manage Driver Payouts: View pending amounts, process payouts automatically, hold payouts during disputes, or retry failed payouts.
  - **Driver Wallet Recharge**: Admin is responsible for adding funds to a driver's wallet (e.g., when they pay their cash commission dues).
- **Site & App Configuration**:
  - Update logos, meta tags, social links, and landing page content.
  - Manage Push Notifications, Promo Codes, and Cancellation Reasons.
  - Setup Stripe Publishable keys, PayStack settings, and Google Maps API keys.
  - Configure App Sleep Mode, Trip Request Window distances, and OTP features.
- **Tracking & Analytics**: 
  - **Map View**: Real-time tracking of active, available, unavailable, and offline drivers.
  - **Heat Map**: Visual representation of high-demand areas to optimize driver allocation.
- **Localization**: Manage multi-language content, add/remove languages, and handle RTL interface.
