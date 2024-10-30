import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from tqdm import tqdm
from datetime import datetime

# Initialize Firebase Admin SDK
cred = credentials.Certificate('scout-8cbdb-firebase-adminsdk-c3ytz-356ba74ead.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def initialize_user_fields():
    # Reference to the 'users' collection
    users_ref = db.collection('users')
    
    # Get all user documents
    docs = list(users_ref.stream())
    
    print("\n=== Initializing fields for each user ===\n")
    
    # Progress bar setup with tqdm
    for doc in tqdm(docs, desc="Initializing fields"):
        user_data = doc.to_dict()
        user_id = doc.id

        # Initialize new fields with zero if they don't already exist
        update_data = {}

        if 'placesInListsCount' not in user_data:
            update_data['placesInListsCount'] = 0
        
        if 'placesTaggedCount' not in user_data:
            update_data['placesTaggedCount'] = 0
        
        if 'totalListStarsCount' not in user_data:
            update_data['totalListStarsCount'] = 0

        # If any field needs updating, update the document
        if update_data:
            doc.reference.update(update_data)

    print("\nField initialization completed for all users\n")

if __name__ == "__main__":
    initialize_user_fields()
