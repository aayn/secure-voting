from Crypto.PublicKey.RSA import generate, construct, import_key
from Crypto.Random import get_random_bytes, random
from Crypto.Cipher import AES, PKCS1_OAEP
from utils import ethash


def keygen():
    key = generate(2048)
    return key.publickey, key


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


if __name__ == '__main__':
    rsa_modulus = 25522819322198944697340174950556543969009505002248383814804136426048390846011594076984867499694335451342147136173546784517399072926537424198432426464896858547814681128485536248118959586697065496921596060960438570981093136950062316635191212467123038906973091220160014913117998846689491739398759214023162038696388297750174275550315835309789538897396357858619233402794941159633957155927008832531478303116215808788168339373114596202798886503352751075060847542077049619004222934341656255058346116119679500416478858586429127736338393018726939539157950763505823192922537319869813086062735656690722744278304434943843713352631
    priv_exp = 2338400729666349748007676281957013111096290229732829098310747168320300941985086540965494863999185760983626386303218970469120080769449226598707409626752417522168443060194873161753365165300861036914502091155178805857087961621933399152173667321647928454413841436615206822799594489753071595422736007150191135714947819271436329054215562069420009347678998925269627673015957332647742405583130131093310202396646533628873879959154371294486664419665631094174136295816479944501051267943347127805237489581055778442733486582559405474072484884597855763850868545637178176035515677811427026001785134588398089931941565880707352538673
    ev = encrypt_vote('0x81376b9868b292a46a1c486d344e427a3088657fda629b5f4a647822d329cd6a', rsa_modulus)
    # print(str(ev))
    print(decrypt_vote(ev, rsa_modulus, priv_exp))

# pu, pr = keygen()
# print(pu)