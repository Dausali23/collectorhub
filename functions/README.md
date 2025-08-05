# Password Management Cloud Function

This Cloud Function allows administrators to directly set passwords for other users in the CollectorHub app.

## Prerequisites

1. Node.js installed on your machine
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. Firebase project set up and linked to your app

## Setup Instructions

1. Navigate to the functions directory:
   ```
   cd functions
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Deploy the function:
   ```
   firebase deploy --only functions
   ```

4. After deployment, you'll receive a URL for your function. It will look like:
   ```
   https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/updateUserPasswordHttp
   ```

5. Update the URL in your Flutter app:
   - Open `lib/screens/admin/admin_manage_screen.dart`
   - Replace the placeholder URL in `_updateUserPassword` method with your actual function URL

## Security Notes

- This function performs authentication and authorization checks to ensure only admin users can change passwords
- All requests are validated and secured with Firebase Auth tokens
- Password changes are logged for security auditing
- The minimum password length is enforced (6 characters) 