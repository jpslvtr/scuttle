import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import csv

# Initialize Firebase Admin SDK
cred = credentials.Certificate('scout-8cbdb-firebase-adminsdk-c3ytz-356ba74ead.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def format_field(value):
    # Function to handle missing or empty values
    return value if value not in [None, ''] else '-'

def display_all_users(print_to_csv=False, file_name='users_data.csv'):
    # Reference to the 'users' collection
    users_ref = db.collection('users')

    # Query for all users and sort by 'memberSince'
    query = users_ref.order_by('memberSince')

    # Get all documents
    docs = query.stream()

    # Counter for total users
    total_users = 0

    # List to store sorted user information
    sorted_users = []

    # Iterate through all documents
    for doc in docs:
        user_data = doc.to_dict()
        user_id = doc.id

        # Get userName, displayName, phone, email, and memberSince
        user_info = {
            'userName': format_field(user_data.get('userName')),
            'displayName': format_field(user_data.get('displayName')),
            'phone': format_field(user_data.get('phone')),
            'email': format_field(user_data.get('email')),
            'memberSince': user_data.get('memberSince')
        }

        # Check if 'memberSince' is not None and format it
        if user_info['memberSince']:
            user_info['memberSince'] = user_info['memberSince'].strftime('%Y-%m-%d %H:%M:%S')
        else:
            user_info['memberSince'] = '-'

        sorted_users.append(user_info)
        total_users += 1

    if print_to_csv:
        # Write to CSV
        with open(file_name, mode='w', newline='') as csv_file:
            fieldnames = ['userName', 'displayName', 'phone', 'email', 'memberSince']
            writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

            # Write the header
            writer.writeheader()

            # Write user data rows
            for user in sorted_users:
                writer.writerow(user)
        
        print(f"\nCSV file '{file_name}' created with {total_users} users.")
    else:
        # Print to the terminal
        header = f"{'userName':<20} {'displayName':<20} {'phone':<15} {'email':<25} {'memberSince':<20}"
        print(header)
        print('-' * len(header))  # Print a separator line

        # Display each user's info, aligned nicely
        for user in sorted_users:
            print(f"{user['userName']:<20} {user['displayName']:<20} {user['phone']:<15} {user['email']:<25} {user['memberSince']:<20}")
        
        # Display the total number of users
        print(f"\nTotal users: {total_users}")

# Run the function
if __name__ == "__main__":
    # Set print_to_csv to True to output to CSV, or False to print to terminal
    # display_all_users(print_to_csv=False)
    display_all_users(print_to_csv=True)
