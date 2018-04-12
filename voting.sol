pragma solidity ^0.4.18;

contract Voting {
    mapping (bytes32 => bool) tokenHashes;
    struct Candidate {
        string name;
        bytes32 id;
    }
    Candidate[] public candidates;

    function Voting(bytes32[] thashes) public {
        for (uint8 i = 0; i < thashes.length; i++) {
            tokenHashes[thashes[i]] = true;
        }
        candidates.push(Candidate("Alice", keccak256("Alice")));
        candidates.push(Candidate("Bob", keccak256("Bob")));
        candidates.push(Candidate("Charlie", keccak256("Charlie")));
    }

    modifier voterGuard(string token) {
        bytes32 thash = keccak256(token);
        require(tokenHashes[thash] == true);
        _;
    }

    
    function ret1(string token) voterGuard(token) public returns(uint) {
        return 1;
    }

    function getNumCandidates() view public returns (uint) {
        return candidates.length;
    }

    function showCandidate(uint index) returns (string, bytes32) {
        return (candidates[index].name, candidates[index].id);
    }
}