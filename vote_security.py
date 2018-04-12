from Crypto.PublicKey.RSA import generate, construct
from Crypto.Random import get_random_bytes
from Crypto.Cipher import AES, PKCS1_OAEP


def keygen():
    key = generate(2048)
    return key.publickey, key

pu, pr = keygen()
print(pu)