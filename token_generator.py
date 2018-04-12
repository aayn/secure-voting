from Crypto.Random.random import getrandbits
import pickle
from utils import ethash, save_token_hashes, load_token_hashes


def get_n_tokens(n):
    return [getrandbits(128) for _ in range(n)]


def get_token_hashes(token_list):
    return token_list, list(map(ethash, token_list))


tokens = get_n_tokens(5)
token_hashes = get_token_hashes(tokens)
save_token_hashes(token_hashes)
thashes = load_token_hashes()
print(thashes)
