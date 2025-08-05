const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function to update a user's password
 * Can only be called by authenticated users with admin privileges
 */
exports.updateUserPassword = functions.https.onCall(async (data, context) => {
  try {
    // Check if the caller is authenticated and has admin role
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'The function must be called while authenticated.'
      );
    }

    // Get the caller's user ID and check if they have admin privileges
    const callerUid = context.auth.uid;
    const callerSnapshot = await admin.firestore().collection('users').doc(callerUid).get();
    
    if (!callerSnapshot.exists || callerSnapshot.data().role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can update user passwords.'
      );
    }

    // Get the data from the request
    const { userId, newPassword } = data;
    
    if (!userId || !newPassword) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'The function must be called with userId and newPassword arguments.'
      );
    }
    
    if (newPassword.length < 6) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password must be at least 6 characters long.'
      );
    }

    // Update the user's password
    await admin.auth().updateUser(userId, {
      password: newPassword,
    });

    return { success: true, message: 'Password updated successfully' };
  } catch (error) {
    console.error('Error updating password:', error);
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while updating the password: ' + error.message
    );
  }
});

// HTTP endpoint version for direct API calls
exports.updateUserPasswordHttp = functions.https.onRequest(async (req, res) => {
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // Extract auth token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).send({ error: 'Unauthorized: No bearer token provided' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];
    
    // Verify the ID token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const callerUid = decodedToken.uid;
    
    // Check if the caller has admin privileges
    const callerSnapshot = await admin.firestore().collection('users').doc(callerUid).get();
    
    if (!callerSnapshot.exists || callerSnapshot.data().role !== 'admin') {
      res.status(403).send({ error: 'Forbidden: Only admins can update user passwords' });
      return;
    }

    // Get the data from the request body
    const { userId, newPassword } = req.body;
    
    if (!userId || !newPassword) {
      res.status(400).send({ error: 'Bad Request: userId and newPassword are required' });
      return;
    }
    
    if (newPassword.length < 6) {
      res.status(400).send({ error: 'Bad Request: Password must be at least 6 characters long' });
      return;
    }

    // Update the user's password
    await admin.auth().updateUser(userId, {
      password: newPassword,
    });

    res.status(200).send({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error('Error updating password:', error);
    res.status(500).send({ error: 'Internal Server Error: ' + error.message });
  }
}); 