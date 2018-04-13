pragma solidity ^1.4.18;

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

    // Warden Functionality

    uint private securityDep = 0.5 ether;
    uint private wardenLimit = 2;
    uint wid = 1;

    mapping (address => bool) wardenExists;
    mapping (address => uint) refundAmount;
    mapping (address => uint) wardens;
    mapping (uint => bytes) enKeys;

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
    
   function WithdrawSecurity() external payable wardenGuard(true) greaterThanGuard(refundAmount[msg.sender] , 0){
        msg.sender.transfer(securityDep + refundAmount[msg.sender] )
        refundAmount[msg.sender] = 0
        
	}
    
   function submitEncryptionKey(bytes rsaModulus) public wardenGuard(true) greaterThanGuard(refundAmount[msg.sender], 0) {
       enKeys[wardens[msg.sender]] = rsaModulus;
   }
}
