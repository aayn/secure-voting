# README

To switch between different modes, change branches - `weak-sec` for
mode 1, and `master` for mode 2.

## Mode 1 - Weak Security, Seamless System

The first mode uses very weak encryption and decryption methods. These
are just placeholders for stronger methods of encryption until Solidity
supports RSA decryption or there is a good Big Number Library.
This mode implements the given system specification as faithfully as
possible.

## Mode 2 - Strong Security, Not-so Seamless System

The second mode uses state-of-the-art RSA encryption and decryption.
But in Solidity, doing large RSA calculations is not very easy at the
moment. This mode differs from the given specification in that vote
decryption is done outside the contract by the contract creator/admin.

## Some Instructions

* Run `python vote_security.py` to run a key generation, encryption and
decryption interface.
* 5 tokens and thier hashes are there in tokens.txt.