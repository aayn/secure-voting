pragma solidity ^0.4.23;

import  "browser/wes.sol";


contract Voting {
    using WES for uint;
    
    event TimeEvent(TimeSlot _before, TimeSlot current, TimeSlot _after);
    event Log(string mssg, uint num);

    enum TimeSlot {BCR, ECR, BTD, ETD, BVC, EVC, BVT, END}
    //             0,   1,   2,   3,   4,   5,   6,   7
    TimeSlot timeSlot;

    function showTimeSlot() view public returns(uint) {
        return uint(timeSlot);
    }
    

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

    constructor(bytes32[] thashes) public payable {
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
    
    function encrypt(uint mssg, uint pk) pure public returns (uint) {
        return mssg * (100 - pk);
    }
    
    function decrypt(uint _self, uint sk) pure public returns (uint) {
        return _self / sk;
    }

    function showCandidate(uint index) view public returns (string, uint) {
        return (candidates[index].name, candidates[index].id);
    }

    // Warden Functionality

    uint private securityDep = 0.5 ether;
    uint private wardenLimit = 2;
    uint wid = 0;

    mapping (address => bool) wardenExists;
    mapping (address => uint) refundAmount;
    mapping (address => uint) wardens;
    mapping (uint => uint) enKeys;
    mapping (uint => uint) deKeys;

    modifier wardenGuard(bool val) {
        require(wardenExists[msg.sender] == val, "Warden Guard triggered.");
        _;
    }

    modifier greaterThanGuard(uint lhs, uint rhs) {
        require(lhs > rhs, "Greater Than Guard triggered.");
        _;
    }

    modifier enKeySubmitGuard(bool val) {
        require((enKeys[wardens[msg.sender]] == 0) == val);
        _;
    }

    modifier deKeySubmitGuard(bool val) {
        require((deKeys[wardens[msg.sender]] == 0) == val);
        _;
    }

    modifier validKeyGuard() {
        uint encMsg = encrypt(123, enKeys[wardens[msg.sender]]);
        require (123 == decrypt(encMsg, deKeys[wardens[msg.sender]]));
        _;
    }

    function wardenRegister() public wardenGuard(false) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(wardenLimit, 0) {
        wardenExists[msg.sender] = true;
        wardens[msg.sender] = wid;
        enKeys[wid] = 0;
        deKeys[wid] = 0;
        wid += 1;
        wardenLimit -= 1;
    }

    function depositSecurity() external payable wardenGuard(true) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(msg.value, securityDep) {
        refundAmount[msg.sender] = msg.value - securityDep;
    }
    
    function withdrawReward() external payable wardenGuard(true) timeGuard(TimeSlot.BVT, TimeSlot.END) greaterThanGuard(refundAmount[msg.sender], 0) enKeySubmitGuard(false) deKeySubmitGuard(false)
      validKeyGuard() {
        msg.sender.transfer(securityDep + refundAmount[msg.sender] + (reward / wardenLimit));
        refundAmount[msg.sender] = 0;
    }

    uint numKeys = 0;
    function submitEncryptionKey(uint pk) public wardenGuard(true) timeGuard(TimeSlot(0), TimeSlot.BVC) greaterThanGuard(refundAmount[msg.sender], 0) enKeySubmitGuard(true) {
       enKeys[wardens[msg.sender]] = pk;
       numKeys += 1;
    }

    function submitDecryptionKey(uint sk) public wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) deKeySubmitGuard(true) {
        deKeys[wardens[msg.sender]] = sk;
    }

    // Voter Functionality

    uint private keyIdCounter = 0;
    struct Ballot {
        uint[] votes;
    }
    Ballot[100] voteBatch;

    function getEncryptionKey() public timeGuard(TimeSlot.BVC, TimeSlot.EVC) returns (uint, uint) {
        uint i = keyIdCounter;
        uint enK = enKeys[i];
        keyIdCounter = (keyIdCounter + 1) % numKeys;
        return (i, enK);
    }

    function castVote(string token, uint i, uint encryptedVote) public timeGuard(TimeSlot.BVC, TimeSlot.EVC) voterGuard(token) {
        voteBatch[i].votes.push(encryptedVote);
        tokenHashes[keccak256(token)] = false;
    }

    // Contract Admin Functionality

    modifier adminGuard() {
        require(msg.sender == admin, "User is not an admin.");
        _;
    }

    function nextTimeSlot() public adminGuard() {
        timeSlot = TimeSlot(uint(timeSlot) + 1);
        emit TimeEvent(timeSlot, timeSlot, timeSlot);
    }

    bool private tallyDone = false;
    mapping (uint => uint) voteCount;

    function peekVotes(uint i, uint j) public adminGuard() returns(uint, uint) {
        return (voteBatch[i].votes[j], decrypt(voteBatch[i].votes[j], deKeys[i]));
    }

    function voteTally(uint candId) public timeGuard(TimeSlot.BVT, TimeSlot.END) returns (uint) {
        if (tallyDone == false) {
            for (uint i = 0; i < numKeys; i++) {
                for (uint j = 0; j < voteBatch[i].votes.length; j++) {
                    uint vote = decrypt(voteBatch[i].votes[j], deKeys[i]);
                    emit Log("Vote:", vote);
                    voteCount[vote] += 1;
                }
            }
            tallyDone = true;
        }
        return voteCount[candId];
    }
}
