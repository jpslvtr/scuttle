const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.createFirebaseToken = functions.https.onCall(async (data, context) => {
    console.log('createFirebaseToken function called with data:', JSON.stringify(data));
    const idmeToken = data.idmeToken;

    if (!idmeToken) {
        console.error('ID.me token is missing');
        throw new functions.https.HttpsError('invalid-argument', 'ID.me token is required');
    }

    try {
        console.log('Fetching user data from ID.me');
        const response = await axios.get('https://api.id.me/api/public/v3/attributes.json', {
            headers: {
                'Authorization': `Bearer ${idmeToken}`,
                'Accept': 'application/json'
            }
        });

        console.log('ID.me API Response:', {
            status: response.status,
            data: response.data
        });

        const userData = response.data;

        // Check if we got valid user data
        if (!userData || !userData.attributes) {
            console.error('Invalid user data returned from ID.me:', userData);
            throw new functions.https.HttpsError(
                'internal',
                'Invalid user data returned from ID.me'
            );
        }

        // Find email in attributes
        const emailAttr = userData.attributes.find(attr => attr.handle === 'email');
        if (!emailAttr || !emailAttr.value) {
            throw new functions.https.HttpsError(
                'internal',
                'No email found in ID.me response'
            );
        }

        const email = emailAttr.value;
        console.log('Found user email:', email);

        // Create or update Firebase user
        let firebaseUser;
        try {
            firebaseUser = await admin.auth().getUserByEmail(email);
            console.log('Found existing Firebase user:', firebaseUser.uid);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                const fnameAttr = userData.attributes.find(attr => attr.handle === 'fname');
                const lnameAttr = userData.attributes.find(attr => attr.handle === 'lname');

                firebaseUser = await admin.auth().createUser({
                    email: email,
                    emailVerified: true,
                    displayName: `${fnameAttr?.value || ''} ${lnameAttr?.value || ''}`.trim() || undefined
                });
                console.log('Created new Firebase user:', firebaseUser.uid);
            } else {
                console.error('Error getting/creating Firebase user:', error);
                throw new functions.https.HttpsError('internal', error.message);
            }
        }

        // Update custom claims
        await admin.auth().setCustomUserClaims(firebaseUser.uid, {
            idmeVerified: true,
            militaryStatus: 'military'
        });

        // Create custom token
        const customToken = await admin.auth().createCustomToken(firebaseUser.uid);
        console.log('Created custom token for user:', firebaseUser.uid);

        return { customToken };

    } catch (error) {
        console.error('Error in createFirebaseToken:', error);
        if (error.response) {
            console.error('ID.me API error:', {
                status: error.response.status,
                data: error.response.data
            });
        }
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            'internal',
            error.message || 'An unknown error occurred'
        );
    }
});