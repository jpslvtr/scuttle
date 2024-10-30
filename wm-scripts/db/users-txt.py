import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate('scout-8cbdb-firebase-adminsdk-c3ytz-356ba74ead.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def format_field(value):
    # Function to handle missing or empty values
    return value if value not in [None, ''] else '-'

def display_basic_user_info(print_to_txt=True, file_name='basic_users_data.txt'):
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

        # Get userName, phone, and memberSince only
        user_info = {
            'userName': format_field(user_data.get('userName')),
            'phone': format_field(user_data.get('phone')),
            'memberSince': user_data.get('memberSince')
        }

        # Format 'memberSince' if it exists
        if user_info['memberSince']:
            user_info['memberSince'] = user_info['memberSince'].strftime('%Y-%m-%d %H:%M:%S')
        else:
            user_info['memberSince'] = '-'

        sorted_users.append(user_info)
        total_users += 1

    if print_to_txt:
        # Write to a formatted text file
        with open(file_name, mode='w') as txt_file:
            # Define table header with numbering column
            header = f"{'No.':<5} {'userName':<20} {'phone':<15} {'memberSince':<20}"
            txt_file.write(header + "\n")
            txt_file.write('-' * len(header) + "\n")  # Print a separator line

            # Write each user's info with numbering, aligned nicely
            for idx, user in enumerate(sorted_users, start=1):
                row = f"{idx:<5} {user['userName']:<20} {user['phone']:<15} {user['memberSince']:<20}"
                txt_file.write(row + "\n")

            # Write the total number of users
            txt_file.write(f"\nTotal users: {total_users}\n")
        
        print(f"\nText file '{file_name}' created with {total_users} users.")
    else:
        # Print to the terminal with numbering
        header = f"{'No.':<5} {'userName':<20} {'phone':<15} {'memberSince':<20}"
        print(header)
        print('-' * len(header))  # Print a separator line

        # Display each user's info with numbering, aligned nicely
        for idx, user in enumerate(sorted_users, start=1):
            print(f"{idx:<5} {user['userName']:<20} {user['phone']:<15} {user['memberSince']:<20}")
        
        # Display the total number of users
        print(f"\nTotal users: {total_users}")

# Run the function
if __name__ == "__main__":
    # Set print_to_txt to True to output to TXT file, or False to print to terminal
    display_basic_user_info(print_to_txt=True)
