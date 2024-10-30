import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime
import math
from tqdm import tqdm
import pandas as pd
from tabulate import tabulate

# Initialize Firebase Admin SDK
cred = credentials.Certificate('scout-8cbdb-firebase-adminsdk-c3ytz-356ba74ead.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def calculate_member_duration_score(member_since):
    """Calculate score based on membership duration"""
    if not member_since:
        return 0
    
    days_member = (datetime.now() - member_since).days
    return math.log(max(days_member, 1)) * 5

def calculate_list_score(list_count, places_count):
    """Calculate score based on lists and places in lists"""
    list_base = math.log(max(list_count, 1)) * 10
    avg_places = places_count / max(list_count, 1)
    places_bonus = math.log(max(avg_places, 1)) * 7
    return list_base + places_bonus

def calculate_tag_score(tagged_places):
    """Calculate score based on number of tagged places"""
    return math.log(max(tagged_places, 1)) * 12

def calculate_star_score(stars_received, stars_given):
    """Calculate score based on stars received and given"""
    received_score = math.log(max(stars_received, 1)) * 15
    given_score = math.log(max(stars_given, 1)) * 7
    return received_score + given_score

def calculate_social_score(followers_count, following_count):
    """Calculate score based on followers and following"""
    followers_score = math.log(max(followers_count, 1)) * 10
    following_score = math.log(max(following_count, 1)) * 5
    return followers_score + following_score

def calculate_note_score(note_count):
    """Calculate score based on number of notes left by the user"""
    return math.log(max(note_count, 1)) * 8  # Adjust multiplier as needed

def calculate_user_scores():
    # Reference to the 'users' collection
    users_ref = db.collection('users')
    
    # Get all user documents
    docs = list(users_ref.stream())
    
    print("\n=== Starting User Score Calculations ===\n")
    
    # Initialize an empty list to hold the final score data for all users
    user_scores_data = []

    # Progress bar setup with tqdm
    for doc in tqdm(docs, desc="Calculating user scores"):
        user_data = doc.to_dict()
        user_id = doc.id
        username = user_data.get('userName', 'No username')
        scores = {}

        # Member duration score
        member_since = user_data.get('memberSince')
        if member_since:
            member_since = member_since.timestamp()
            member_since = datetime.fromtimestamp(member_since)
        scores['memberScore'] = calculate_member_duration_score(member_since)
        
        # Lists and places score
        created_lists = user_data.get('createdLists', [])
        total_places = 0
        total_stars_received = 0
        
        for list_id in created_lists:
            list_doc = db.collection('lists').document(list_id).get()
            if list_doc.exists:
                list_data = list_doc.to_dict()
                total_places += len(list_data.get('places', []))
                total_stars_received += list_data.get('starCount', 0)
        
        scores['listScore'] = calculate_list_score(len(created_lists), total_places)
        
        # Tagged places score
        user_tags = user_data.get('userTags', [])
        scores['tagScore'] = calculate_tag_score(len(user_tags))
        
        # Stars score
        stars_given = len(user_data.get('followedLists', []))
        scores['starScore'] = calculate_star_score(total_stars_received, stars_given)
        
        # Social score
        followers = user_data.get('followers', [])
        following = user_data.get('following', [])
        scores['socialScore'] = calculate_social_score(len(followers), len(following))
        
        # Notes score - count notes for this user from 'place_notes' collection
        notes_query = db.collection('place_notes').where('userId', '==', user_id)
        note_count = len(list(notes_query.stream()))  # Count the user's notes
        scores['noteScore'] = calculate_note_score(note_count)
        
        # Calculate total score
        total_score = sum(scores.values())
        
        # Store the calculated data for later display
        user_scores_data.append({
            'Username': username,
            'User ID': user_id,
            'Member Score': round(scores['memberScore'], 2),
            'List Score': round(scores['listScore'], 2),
            'Tag Score': round(scores['tagScore'], 2),
            'Star Score': round(scores['starScore'], 2),
            'Social Score': round(scores['socialScore'], 2),
            'Note Score': round(scores['noteScore'], 2),  # Include note score in the summary
            'Total Score': round(total_score, 2)  
        })
        
        # Update the user document with the new scores
        doc.reference.update({
            'userScores': scores,
            'totalUserScore': total_score,
            'lastScoreUpdate': datetime.now()
        })
    
    print("\nScore calculation completed for all users\n")
    
    # Create a Pandas DataFrame to display the final scores in a nice table format
    df = pd.DataFrame(user_scores_data)
    
    # Sort the DataFrame by total score in descending order
    df_sorted = df.sort_values(by='Total Score', ascending=False)
    
    # Use tabulate to create a formatted table
    table = tabulate(df_sorted, headers='keys', tablefmt='grid')
    
    # Write the formatted table to a .txt file
    with open('user_scores.txt', 'w') as f:
        f.write(table)
    
    print(f"\nScores have been written to 'user_scores.txt'.\n")

if __name__ == "__main__":
    calculate_user_scores()
