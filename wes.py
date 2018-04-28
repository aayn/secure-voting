"""Weak Encryption system"""
import random
n = 100

def get_keypair():
    sk = random.randint(0, n)
    pk = n - sk
    return pk, sk

def encrypt(msg, pk):
    return msg * (n - pk)


def decrypt(e_msg, sk):
    return e_msg // sk