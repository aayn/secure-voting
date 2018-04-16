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

    function ret1(string token) voterGuard(token) public view returns(uint) {
        return 1;
    }

    function getNumCandidates() view public returns (uint) {
        return candidates.length;
    }

    function showCandidate(uint index) public returns (string, bytes32) {
        return (candidates[index].name, candidates[index].id);
    }

    // Warden Functionality

    uint private securityDep = 0.5 ether;
    uint private wardenLimit = 2;
    uint wid = 0;

    mapping (address => bool) wardenExists;
    mapping (address => uint) refundAmount;
    mapping (address => uint) wardens;
    mapping (uint => string) enKeys;
    mapping (uint => string) deKeys;

    modifier wardenGuard(bool val) {
        require(wardenExists[msg.sender] == val);
        _;
    }

    modifier greaterThanGuard(uint lhs, uint rhs) {
        require(lhs > rhs);
        _;
    }


    function wardenRegister() public wardenGuard(false) greaterThanGuard(wardenLimit, 0) {
        wardenExists[msg.sender] = true;
        wardens[msg.sender] = wid;
        wid += 1;
        wardenLimit -= 1;
    }

    function depositSecurity() external payable wardenGuard(true) greaterThanGuard(msg.value, securityDep) {
        refundAmount[msg.sender] = msg.value - securityDep;
    }
    
   function withdrawSecurity() external payable wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) {
        msg.sender.transfer(securityDep + refundAmount[msg.sender]);
        refundAmount[msg.sender] = 0;
        
    }

    uint numKeys = 0;
    function submitEncryptionKey(string rsaModulus) public wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) {
       enKeys[wardens[msg.sender]] = rsaModulus;
       numKeys += 1;
    }

    function submitDecryptionKey(string privateExponent) public wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) {
        deKeys[wardens[msg.sender]] = privateExponent;
    }

    // Voter Functionality
    uint private keyIdCounter = 0;
    struct Ballot {
        string[] votes;
    }
    mapping (uint => Ballot) voteBatch;


    function getEncryptionKey() public returns (uint, string) {
        uint i = keyIdCounter;
        string enK = enKeys[i];
        keyIdCounter = (keyIdCounter + 1) % numKeys;
        return (i, enK);
    }

    function castVote(string token, uint i, string encryptedVote) public voterGuard(token) {
        voteBatch[i].votes.push(encryptedVote);
        tokenHashes[keccak256(token)] = false;
    }

    function showEncryptedVote() public returns (string) {
        return voteBatch[0].votes[0];
    }
}
