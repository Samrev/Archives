
"""
Some random users with id defined by randint(1, 4000) seeded at 0 and their password for testing the client interface
"""

import bcrypt
import string
import random


pswd_list = ['rooster@89', 'jaguar$12', 'parrot#24', 'monkey&35', 'penguin!78', 'tiger%57']

salt = b'$2b$12$gNzgdEMmLsg826uziTfgO.'
random.seed(0)

for pswd in pswd_list:
	pswd_bytes = pswd.encode('utf-8')
	
	hashed_pswd_bytes = bcrypt.hashpw(pswd_bytes, salt)
	
	hashed_pswd = hashed_pswd_bytes.decode('utf-8')
	print(random.randint(1, 4000), hashed_pswd)




