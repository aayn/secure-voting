pragma solidity ^0.4.23;

library WES {
    uint private constant N = 100;

    function encrypt(uint mssg, uint pk) public pure returns (uint) {
        return mssg * (N - pk);
    }

    function decrypt(uint encMsg, uint sk) public pure returns (uint) {
        return encMsg / sk;
    }
}