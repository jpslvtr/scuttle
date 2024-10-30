import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime

# Initialize Firebase Admin SDK
cred = credentials.Certificate('scout-8cbdb-firebase-adminsdk-c3ytz-356ba74ead.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def update_user_tags():
    # Reference to the 'users' collection
    users_ref = db.collection('users')
    
    # Get all user documents
    docs = users_ref.stream()
    
    # Counter for tracking updates
    updated_count = 0
    
    for doc in docs:
        user_data = doc.to_dict()
        
        # Check if userTags exists and is not empty
        if 'userTags' in user_data and user_data['userTags']:
            # Create a new list of updated tags
            updated_tags = []
            
            # Add updatedAt to each tag
            for tag in user_data['userTags']:
                # Preserve existing tag data
                updated_tag = tag.copy()
                # Add updatedAt field with current timestamp
                updated_tag['updatedAt'] = datetime.now()
                updated_tags.append(updated_tag)
            
            # Update the document
            doc.reference.update({
                'userTags': updated_tags
            })
            
            updated_count += 1
            print(f"Updated tags for user: {doc.id}")
    
    print(f"\nCompleted! Updated {updated_count} user documents.")

if __name__ == "__main__":
    update_user_tags()