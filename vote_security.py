import random
import wes
from utils import ethash


def keygen():
    return wes.get_keypair()


def encrypt_vote(candidate_id, pk):
    return wes.encrypt(int(candidate_id), pk)

def decrypt_vote(encrypted_vote, sk):
    return wes.decrypt(int(encrypted_vote), sk)


def interface():
    while True:
        print('What would you like to do?')
        print('1. Generate Keypair.\n2. Encrypt Vote.\n3. Decrypt Vote')
        try:
            c = int(input('> '))
        except ValueError:
            print('Invalid Choice')
            continue
        if c == 1:
            pk, sk = keygen()
            print('Public Key:')
            print(str(pk))
            print('Private Key:')
            print(str(sk))
        elif c == 2:
            candidate_id = input('Enter Candidate ID: ')
            pk = int(input('Enter Ecrypting Key: '))
            print('Encrypted Vote:\n{}'.format(encrypt_vote(candidate_id, pk)))
        elif c == 3:
            enc_vote = int(input('Enter Encrypted Vote: '))
            sk = int(input('Enter Decrypting Key: '))
            print('Decrypted Vote:\n{}'.format(decrypt_vote(enc_vote, sk)))
        else:
            print('Invalid Choice.')


if __name__ == '__main__':
    interface()