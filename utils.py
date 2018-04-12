from Crypto.Random.random import getrandbits
from eth_utils import keccak, encode_hex
import pickle


def ethash(data):
    return '"{}"'.format(encode_hex(keccak(text=str(data))))


def save_token_hashes(thashes):
    with open('thashes.pkl', 'wb') as thash_file:
        pickle.dump(thashes, thash_file)


def load_token_hashes():
    with open('thashes.pkl', 'rb') as thash_file:
        thashes = pickle.load(thash_file)
    return thashes

if __name__ == '__main__':
    print(ethash(1736245338))