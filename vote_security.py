from Crypto.PublicKey.RSA import generate, construct, import_key
from Crypto.Random import get_random_bytes, random
from Crypto.Cipher import AES, PKCS1_OAEP
from utils import ethash


def keygen():
    key = generate(2048)
    return key.publickey().n, key.d


def encrypt_vote(candidate_id, rsa_modulus):
    candidate_id = str(candidate_id)
    pub_key = construct((rsa_modulus, 65537))
    salt = str(random.getrandbits(128))
    vote = ''.join([candidate_id, salt]).encode('utf-8')

    cipher_rsa = PKCS1_OAEP.new(pub_key)
    encrypted_vote = cipher_rsa.encrypt(vote)

    return int.from_bytes(encrypted_vote, 'little')
    # return int.from_bytes(encrypted_vote, 'little').to_bytes(len(encrypted_vote), 'little'), encrypted_vote

def decrypt_vote(encrypted_vote, rsa_modulus, priv_exp):
    encrypted_vote = encrypted_vote.to_bytes(256, 'little')
    priv_key = import_key(construct((rsa_modulus, 65537, priv_exp)).exportKey())

    cipher_rsa = PKCS1_OAEP.new(priv_key)
    decrypted_vote = str(cipher_rsa.decrypt(encrypted_vote), 'utf-8')[:66]

    return decrypted_vote


def interface():
    key_number = 1
    while True:
        print('What would you like to do?')
        print('1. Generate Keypair.\n2. Encrypt Vote.\n3. Decrypt Vote')
        try:
            c = int(input('> '))
        except ValueError:
            print('Invalid Choice')
            continue
        if c == 1:
            pu, pr = keygen()
            key_filename = 'key' + str(key_number) + '.txt'
            print('Public Modulus:')
            print(str(pu))
            print('Private Exponent:')
            print(str(pr))
            with open(key_filename, 'w') as keyfile:
                keyfile.write('Public Modulus:\n')
                keyfile.write(str(pu) + '\n')
                keyfile.write('Private Exponent:\n')
                keyfile.write(str(pr))
            print('Key written in {}'.format(key_filename))
            key_number += 1
        elif c == 2:
            candidate_id = input('Enter Candidate ID: ')
            rsa_mod = int(input('Enter Ecrypting Key: '))
            print('Encrypted Vote:\n{}'.format(encrypt_vote(candidate_id, rsa_mod)))
        elif c == 3:
            enc_vote = int(input('Enter Encrypted Vote: '))
            rsa_mod = int(input('Enter Ecrypting Key: '))
            priv_exp = int(input('Enter Decrypting Key: '))

            print('Decrypted Vote:\n{}'.format(decrypt_vote(enc_vote, rsa_mod, priv_exp)))
        else:
            print('Invalid Choice.')


if __name__ == '__main__':
    interface()