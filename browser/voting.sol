pragma solidity ^0.4.23;

contract Voting {
    event TimeEvent(TimeSlot _before, TimeSlot current, TimeSlot _after);

    enum TimeSlot {BCR, ECR, BTD, ETD, BVC, EVC, BVT, END}
    TimeSlot timeSlot;

    modifier timeGuard(TimeSlot _before, TimeSlot _after) {
        emit TimeEvent(_before, timeSlot, _after);
        require(timeSlot > _before, "Invalid timestamp.");
        require(timeSlot <= _after, "Invalid timestamp.");
        _;
    }

    mapping (bytes32 => bool) tokenHashes;
    struct Candidate {
        string name;
        uint id;
    }
    Candidate[] candidates;
    mapping (uint => uint) candIndexMap;

    address admin;
    uint reward;

    function Voting(bytes32[] thashes) public payable {
        admin = msg.sender;
        reward = msg.value;

        for (uint8 i = 0; i < thashes.length; i++) {
            tokenHashes[thashes[i]] = true;
        }
        uint aliceId = 5546871124;
        candidates.push(Candidate("Alice", aliceId));
        candIndexMap[aliceId] = 0;
        uint bobId = 77894562164;
        candidates.push(Candidate("Bob", bobId));
        candIndexMap[bobId] = 1;
        uint charlieId = 9845132113;
        candidates.push(Candidate("Charlie", charlieId));
        candIndexMap[charlieId] = 2;

        timeSlot = TimeSlot.ECR;
    }

    modifier voterGuard(string token) {
        bytes32 thash = keccak256(token);
        require(tokenHashes[thash] == true);
        _;
    }

    function getNumCandidates() view public returns (uint) {
        return candidates.length;
    }

    function showCandidate(uint index) public returns (string, uint) {
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
        require(wardenExists[msg.sender] == val, "Warden Guard triggered.");
        _;
    }

    modifier greaterThanGuard(uint lhs, uint rhs) {
        require(lhs > rhs, "Greater Than Guard triggered.");
        _;
    }

    modifier enKeySubmitGuard(bool val) {
        require((keccak256(enKeys[wardens[msg.sender]]) == keccak256("none")) == val, "Encryption Key Submit Guard triggered.");
        _;
    }

    modifier deKeySubmitGuard(bool val) {
        require((keccak256(deKeys[wardens[msg.sender]]) == keccak256("none")) == val, "Decryption Key Submit Guard triggered.");
        _;
    }

    // Ideally, we would like to check if an enc and dec key form a valid pair.
    // But, because of large number limitations, we assume that just checking for existence of key is enough.
    modifier validKeyGuard() {
        require (1 == 1);
        _;
    }

    function wardenRegister() public wardenGuard(false) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(wardenLimit, 0) {
        wardenExists[msg.sender] = true;
        wardens[msg.sender] = wid;
        enKeys[wid] = "none";
        deKeys[wid] = "none";
        wid += 1;
        wardenLimit -= 1;
    }

    function depositSecurity() external payable wardenGuard(true) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(msg.value, securityDep) {
        refundAmount[msg.sender] = msg.value - securityDep;
    }
    
    function withdrawReward() external payable wardenGuard(true) timeGuard(TimeSlot.BVT, TimeSlot.END) greaterThanGuard(refundAmount[msg.sender], 0) enKeySubmitGuard(false) deKeySubmitGuard(false) {
        msg.sender.transfer(securityDep + refundAmount[msg.sender] + (reward / wardenLimit));
        refundAmount[msg.sender] = 0;
    }

    uint numKeys = 0;
    function submitEncryptionKey(string rsaModulus) public wardenGuard(true) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(refundAmount[msg.sender], 0) enKeySubmitGuard(true) {
       enKeys[wardens[msg.sender]] = rsaModulus;
       numKeys += 1;
    }

    function submitDecryptionKey(string privateExponent) public wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) deKeySubmitGuard(true) {
        deKeys[wardens[msg.sender]] = privateExponent;
    }

    // Voter Functionality

    uint private keyIdCounter = 0;
    struct Ballot {
        string[] votes;
    }
    Ballot[100] voteBatch;

    function getEncryptionKey() public timeGuard(TimeSlot.BVC, TimeSlot.EVC) returns (uint, string) {
        uint i = keyIdCounter;
        string enK = enKeys[i];
        keyIdCounter = (keyIdCounter + 1) % numKeys;
        return (i, enK);
    }

    function castVote(string token, uint i, string encryptedVote) public timeGuard(TimeSlot.BVC, TimeSlot.EVC) voterGuard(token) {
        voteBatch[i].votes.push(encryptedVote);
        tokenHashes[keccak256(token)] = false;
    }

    // Contract Admin Functionality
    bytes32[] private decryptedVotes;

    modifier adminGuard() {
        require(msg.sender == admin, "User is not an admin.");
        _;
    }

    function nextTimeSlot() public adminGuard() {
        timeSlot = TimeSlot(uint(timeSlot) + 1);
        emit TimeEvent(timeSlot, timeSlot, timeSlot);
    }

    function showEncryptedVote(uint batchId, uint voteId) public adminGuard() returns (string) {
        return voteBatch[batchId].votes[voteId];
    }

    function showVoteWithKey(uint batchId, uint voteId) public timeGuard(TimeSlot.EVC, TimeSlot.BVT) returns (string, string) {
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

    function voteTally(bytes32 candId) public timeGuard(TimeSlot.BVT, TimeSlot.END) returns (uint) {
        if (tallyDone == false) {
            for (uint8 i = 0; i < decryptedVotes.length; i++) {
                voteCount[decryptedVotes[i]] += 1;
            }
            tallyDone = true;
        }
        return voteCount[candId];
    }
}
