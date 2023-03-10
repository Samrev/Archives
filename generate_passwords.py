import csv
import bcrypt
import random
import string

# Define the input and output file paths
input_file = 'data_berka/client.asc'
output_file = 'client_with_password.asc'

# Define the salt string to use for password hashing
salt = b'$2b$12$gNzgdEMmLsg826uziTfgO.'

# Define the length of the random password
password_length = 60

# Open the input ASC file and read the records
with open(input_file, 'r') as f_in, open(output_file, 'w', newline='') as f_out:
    reader = csv.DictReader(f_in, delimiter=';')
    fieldnames = reader.fieldnames + ['\"password_hash\"']
    writer = csv.DictWriter(f_out, fieldnames=fieldnames, delimiter=';')
    writer.writeheader()

    # Loop through each record and generate a random password
    for row in reader:
        password = ''.join(random.choices(string.ascii_letters + string.digits, k=password_length))
        password_bytes = password.encode('utf-8')

        # Hash the password using bcrypt with the fixed salt
        hashed_password_bytes = bcrypt.hashpw(password_bytes, salt)

        # Convert the hashed password bytes to a string for writing to ASC
        hashed_password = hashed_password_bytes.decode('utf-8')

        # Write the record to the output ASC file with the new password hash column
        row['"password_hash"'] = hashed_password
        writer.writerow(row)


