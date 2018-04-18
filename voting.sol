pragma solidity ^0.4.18;

contract Voting {
    mapping (bytes32 => bool) tokenHashes;
    struct Candidate {
        string name;
        bytes32 id;
    }
    Candidate[] public candidates;
    mapping (bytes32 => uint) candIndexMap;

    address admin;
    uint reward;

    function Voting(bytes32[] thashes) public payable {
        admin = msg.sender;
        reward = msg.value;

        for (uint8 i = 0; i < thashes.length; i++) {
            tokenHashes[thashes[i]] = true;
        }
        bytes32 aliceId = keccak256("Alice");
        candidates.push(Candidate("Alice", aliceId));
        candIndexMap[aliceId] = 0;
        bytes32 bobId = keccak256("Bob");
        candidates.push(Candidate("Bob", bobId));
        candIndexMap[bobId] = 1;
        bytes32 charlieId = keccak256("Charlie");
        candidates.push(Candidate("Charlie", charlieId));
        candIndexMap[charlieId] = 2;
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
    Ballot[100] voteBatch;

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

    // Contract Admin Functionality

    bytes32[] private decryptedVotes;

    modifier adminGuard() {
        require(msg.sender == admin);
        _;
    }

    function showEncryptedVote(uint batchId, uint voteId) public adminGuard() returns (string) {
        return voteBatch[batchId].votes[voteId];
    }

    // TODO: Add timer constraint
    function showVoteWithKey(uint batchId, uint voteId) public returns (string, string) {
        return (voteBatch[batchId].votes[voteId], deKeys[batchId]);
    }

    function showNumVoteBatches() public view adminGuard() returns (uint) {
        return voteBatch.length;
    }

    function numVotesInBatch(uint batchId) public adminGuard() returns (uint) {
        return voteBatch[batchId].votes.length;
    }

    function addDecryptedVote(bytes32 decVote) public adminGuard() {
        decryptedVotes.push(decVote);
    }

    bool private tallyDone = false;
    mapping (bytes32 => uint) voteCount;

    function voteTally(bytes32 candId) public returns (uint) {
        if (tallyDone == false) {
            for (uint8 i = 0; i < decryptedVotes.length; i++) {
                voteCount[decryptedVotes[i]] += 1;
            }
            tallyDone = true;
        }
        return voteCount[candId];
    }
}
