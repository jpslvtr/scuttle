const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.createFirebaseToken = functions.https.onCall(async (data, context) => {
    console.log('createFirebaseToken function called with data:', data);
    const idmeToken = data.idmeToken;

    if (!idmeToken) {
        console.error('ID.me token is missing');
        throw new functions.https.HttpsError('invalid-argument', 'ID.me token is required');
    }

    try {
        console.log('Fetching user data from ID.me');
        const response = await axios.get('https://api.id.me/api/public/v3/attributes.json', {
            headers: {
                'Authorization': `Bearer ${idmeToken}`
            }
        });

        const userData = response.data;
        console.log('ID.me API response:', JSON.stringify(userData, null, 2));

        // Check if the user has a verified military status
        const militaryStatus = userData.status && userData.status.find(s => s.group === 'military');

        console.log('Military status:', militaryStatus);

        if (!militaryStatus || !militaryStatus.verified) {
            console.error('User not verified by ID.me');
            throw new functions.https.HttpsError('permission-denied', 'User is not verified by ID.me');
        }

        console.log('User verified as military');

        // Get user email
        const email = userData.attributes.find(attr => attr.handle === 'email').value;
        console.log('User email:', email);

        // Create or update Firebase user
        let firebaseUser;
        try {
            firebaseUser = await admin.auth().getUserByEmail(email);
            console.log('Found existing Firebase user:', firebaseUser.uid);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                firebaseUser = await admin.auth().createUser({
                    email: email,
                    displayName: `${userData.attributes.find(attr => attr.handle === 'fname').value} ${userData.attributes.find(attr => attr.handle === 'lname').value}`,
                });
                console.log('Created new Firebase user:', firebaseUser.uid);
            } else {
                console.error('Error getting/creating Firebase user:', error);
                throw error;
            }
        }

        // Update user claims
        await admin.auth().setCustomUserClaims(firebaseUser.uid, {
            idmeVerified: true,
            militaryStatus: militaryStatus.group
        });
        console.log('Updated user claims');

        console.log('Creating custom token');
        const customToken = await admin.auth().createCustomToken(firebaseUser.uid);

        console.log('Returning custom token');
        return { customToken };

    } catch (error) {
        console.error('Error creating Firebase token:', error);
        if (error.response) {
            console.error('Error data:', error.response.data);
            console.error('Error status:', error.response.status);
            console.error('Error headers:', error.response.headers);
        } else if (error.request) {
            console.error('Error request:', error.request);
        } else {
            console.error('Error message:', error.message);
        }
        throw new functions.https.HttpsError('internal', 'Error creating Firebase token: ' + error.message);
    }
});